"""
Azure OpenAI客户端 - 生产级实现
支持多用户并发、错误恢复、成本追踪和性能监控
"""

import os
import time
import asyncio
import logging
from typing import Dict, List, Optional, Any
from openai import AzureOpenAI
from dataclasses import dataclass
from datetime import datetime

logger = logging.getLogger(__name__)

@dataclass
class AzureLLMResponse:
    """Azure LLM响应数据类"""
    success: bool
    content: str
    usage: Dict[str, Any]
    model: str
    processing_time_ms: int
    attempt: int
    error: Optional[Dict] = None
    fallback_used: bool = False

class AzureOpenAIClient:
    """Azure OpenAI服务客户端 - 生产级实现"""
    
    def __init__(self, config: Optional[Dict] = None):
        """初始化Azure OpenAI客户端"""
        self.config = config or self._load_azure_config()
        
        # 初始化Azure OpenAI客户端
        self.client = AzureOpenAI(
            api_key=self.config["api_key"],
            api_version=self.config["api_version"],
            azure_endpoint=self.config["endpoint"]
        )
        
        # 服务配置
        self.deployment_name = self.config["model"]  # gpt-4o-mini-prod
        # Azure OpenAI o4-mini需要更多tokens用于推理 + 输出 - 测试阶段使用最大窗口
        self.max_tokens = self.config.get("max_tokens", 4000)
        # self.temperature = self.config.get("temperature", 0.7)  # Removed for o4-mini compatibility
        self.timeout = self.config.get("timeout", 30)
        self.retry_attempts = self.config.get("retry_attempts", 3)
        
        # 使用统计
        self.usage_stats = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "total_tokens": 0,
            "total_cost_usd": 0.0,
            "average_response_time_ms": 0.0
        }
        
        self.response_times = []
        
    def _load_azure_config(self) -> Dict[str, str]:
        """加载Azure配置"""
        api_key = os.getenv("AZURE_OPENAI_API_KEY", "a0aad09ad49949f8960ed30cc9d39c0a")
        endpoint = os.getenv("AZURE_OPENAI_ENDPOINT", "https://xiangopenai2025.openai.azure.com/")
        deployment_name = os.getenv("AZURE_OPENAI_MODEL", "o4-mini")
        
        # 验证必需的配置
        if not api_key or api_key == "":
            raise ValueError("Azure OpenAI API key is required but not configured")
        if not endpoint or endpoint == "":
            raise ValueError("Azure OpenAI endpoint is required but not configured")
        if not deployment_name or deployment_name == "":
            raise ValueError("Azure OpenAI deployment name is required but not configured")
            
        logger.info(f"Azure OpenAI configuration loaded: endpoint={endpoint}, deployment={deployment_name}")
        
        return {
            "api_key": api_key,
            "endpoint": endpoint,
            "api_version": os.getenv("AZURE_OPENAI_API_VERSION", "2024-12-01-preview"),
            "model": deployment_name,  # This is the deployment name for Azure
            "max_tokens": int(os.getenv("AZURE_MAX_TOKENS", "4000")),
            # "temperature": float(os.getenv("AZURE_TEMPERATURE", "0.7")),  # Removed for o4-mini compatibility
            "timeout": int(os.getenv("AZURE_TIMEOUT", "30")),
            "retry_attempts": int(os.getenv("AZURE_RETRY_ATTEMPTS", "3"))
        }
    
    async def generate_completion(self, prompt: str, 
                                config_override: Optional[Dict] = None) -> AzureLLMResponse:
        """
        生成AI回复 - 兼容现有接口
        """
        start_time = time.time()
        
        # 合并配置 - Azure OpenAI uses max_completion_tokens instead of max_tokens
        effective_config = {
            "max_tokens": self.max_tokens,
            **(config_override or {})
        }
        
        # ❌ AZURE o4-mini BUG FIX: 不设置max_completion_tokens
        # 经测试发现o4-mini模型设置max_completion_tokens会导致返回空内容
        # 移除所有tokens限制参数，让模型自由生成
        effective_config.pop("max_tokens", None)
        effective_config.pop("max_completion_tokens", None)
        
        logger.info("🔧 Azure o4-mini修复: 移除max_completion_tokens限制")
        
        # Note: temperature removed for o4-mini compatibility
        
        # 更新请求统计
        self.usage_stats["total_requests"] += 1
        
        # 重试机制
        for attempt in range(1, self.retry_attempts + 1):
            try:
                # 调用Azure OpenAI API
                response = await self._call_azure_api(prompt, effective_config)
                
                processing_time_ms = int((time.time() - start_time) * 1000)
                self.response_times.append(processing_time_ms)
                
                # 更新成功统计
                self.usage_stats["successful_requests"] += 1
                self._update_usage_stats(response, processing_time_ms)
                
                return AzureLLMResponse(
                    success=True,
                    content=response.choices[0].message.content,
                    usage=self._extract_usage_info(response),
                    model=self.deployment_name,
                    processing_time_ms=processing_time_ms,
                    attempt=attempt,
                    fallback_used=False
                )
                
            except Exception as e:
                logger.warning(f"Azure OpenAI调用失败 (尝试 {attempt}/{self.retry_attempts}): {e}")
                
                if attempt == self.retry_attempts:
                    # 最后一次尝试失败
                    processing_time_ms = int((time.time() - start_time) * 1000)
                    self.usage_stats["failed_requests"] += 1
                    
                    return AzureLLMResponse(
                        success=False,
                        content="",
                        usage={},
                        model=self.deployment_name,
                        processing_time_ms=processing_time_ms,
                        attempt=attempt,
                        error=self._format_azure_error(e),
                        fallback_used=False
                    )
                
                # 等待后重试（指数退避）
                await asyncio.sleep(min(2 ** (attempt - 1), 10))
    
    async def _call_azure_api(self, prompt: str, config: Dict) -> Any:
        """调用Azure OpenAI API"""
        try:
            # ❌ AZURE o4-mini BUG FIX: 完全移除max_completion_tokens参数
            # 经测试验证，o4-mini模型设置max_completion_tokens会返回空内容
            logger.debug(f"Azure API call: deployment={self.deployment_name} (无tokens限制)")
            
            # 构建API调用参数，不包含任何tokens限制
            api_params = {
                "model": self.deployment_name,
                "messages": [
                    {"role": "system", "content": "You are a professional nutritionist and food safety expert."},
                    {"role": "user", "content": prompt}
                ]
                # ❌ 移除max_completion_tokens参数
                # ❌ 移除temperature参数 (o4-mini只支持默认值1)
            }
            
            logger.info(f"🔧 Azure API参数: {list(api_params.keys())}")
            
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    self.client.chat.completions.create,
                    **api_params
                ),
                timeout=self.timeout
            )
            # Detailed response logging for debugging
            if response.choices:
                content = response.choices[0].message.content
                logger.info(f"Azure API response details: choices_count={len(response.choices)}, content_length={len(content) if content else 0}")
                logger.info(f"Azure API response content preview: '{content[:100] if content else 'EMPTY'}...'")
            else:
                logger.warning("Azure API response has no choices")
            
            return response
        except asyncio.TimeoutError:
            logger.error(f"Azure OpenAI API调用超时 ({self.timeout}s) for deployment {self.deployment_name}")
            raise Exception(f"Azure request timeout after {self.timeout} seconds for deployment {self.deployment_name}")
        except Exception as e:
            error_str = str(e)
            logger.error(f"Azure OpenAI API调用失败: {error_str} (deployment: {self.deployment_name})")
            
            # 增强错误信息以便调试
            if "401" in error_str or "invalid api key" in error_str.lower():
                raise Exception(f"Azure authentication failed: Invalid API key for deployment {self.deployment_name}")
            elif "404" in error_str or "deployment" in error_str.lower():
                raise Exception(f"Azure deployment not found: {self.deployment_name} not available at {self.config['endpoint']}")
            elif "429" in error_str or "rate limit" in error_str.lower():
                raise Exception(f"Azure rate limit exceeded for deployment {self.deployment_name}")
            else:
                raise Exception(f"Azure API error for deployment {self.deployment_name}: {error_str}")
    
    def _extract_usage_info(self, response: Any) -> Dict[str, Any]:
        """提取使用信息"""
        try:
            if hasattr(response, 'usage'):
                usage = response.usage
                return {
                    "total_tokens": getattr(usage, 'total_tokens', 0),
                    "prompt_tokens": getattr(usage, 'prompt_tokens', 0),
                    "completion_tokens": getattr(usage, 'completion_tokens', 0)
                }
        except Exception as e:
            logger.warning(f"提取Azure usage信息失败: {e}")
        return {"total_tokens": 0, "estimated": True}
    
    def _update_usage_stats(self, response: Any, processing_time_ms: int):
        """更新使用统计"""
        usage_info = self._extract_usage_info(response)
        tokens_used = usage_info.get("total_tokens", 0)
        
        self.usage_stats["total_tokens"] += tokens_used
        
        # 估算成本（基于Azure OpenAI定价）
        estimated_cost = self._estimate_cost(usage_info)
        self.usage_stats["total_cost_usd"] += estimated_cost
        
        # 更新平均响应时间
        if self.response_times:
            self.usage_stats["average_response_time_ms"] = sum(self.response_times) / len(self.response_times)
    
    def _estimate_cost(self, usage_info: Dict) -> float:
        """估算API调用成本"""
        # Azure OpenAI gpt-4o-mini定价（估算）
        input_cost_per_1k = 0.00015  # $0.15/1K tokens
        output_cost_per_1k = 0.0006   # $0.60/1K tokens
        
        prompt_tokens = usage_info.get("prompt_tokens", 0)
        completion_tokens = usage_info.get("completion_tokens", 0)
        
        input_cost = (prompt_tokens / 1000) * input_cost_per_1k
        output_cost = (completion_tokens / 1000) * output_cost_per_1k
        
        return input_cost + output_cost
    
    def _format_azure_error(self, error: Exception) -> Dict[str, Any]:
        """格式化Azure错误信息"""
        error_message = str(error).lower()
        
        if "rate limit" in error_message or "429" in error_message:
            error_code = "AZURE_RATE_LIMIT_EXCEEDED"
            user_message = "Azure服务繁忙，请稍后重试"
        elif "invalid api key" in error_message or "401" in error_message:
            error_code = "AZURE_AUTH_ERROR"
            user_message = "Azure服务认证失败"
        elif "timeout" in error_message:
            error_code = "AZURE_TIMEOUT"
            user_message = "Azure服务响应超时"
        else:
            error_code = "AZURE_API_ERROR"
            user_message = "Azure AI服务暂时不可用"
        
        return {
            "code": error_code,
            "message": user_message,
            "details": {
                "original_error": str(error),
                "timestamp": datetime.now().isoformat(),
                "deployment": self.deployment_name
            }
        }
    
    async def health_check(self) -> Dict[str, Any]:
        """Azure服务健康检查"""
        try:
            test_prompt = "请回复'Azure健康检查通过'"
            start_time = time.time()
            
            response = await self._call_azure_api(test_prompt, {"max_tokens": 50})
            response_time = (time.time() - start_time) * 1000
            
            return {
                "status": "healthy",
                "service": "Azure OpenAI",
                "deployment": self.deployment_name,
                "endpoint": self.config["endpoint"],
                "response_time_ms": response_time,
                "api_accessible": True,
                "timestamp": datetime.now().isoformat()
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "service": "Azure OpenAI", 
                "deployment": self.deployment_name,
                "endpoint": self.config["endpoint"],
                "error": str(e),
                "api_accessible": False,
                "timestamp": datetime.now().isoformat()
            }
    
    def get_usage_statistics(self) -> Dict[str, Any]:
        """获取使用统计信息"""
        stats = self.usage_stats.copy()
        
        # 计算成功率
        total_requests = stats["total_requests"]
        if total_requests > 0:
            stats["success_rate"] = stats["successful_requests"] / total_requests
            stats["failure_rate"] = stats["failed_requests"] / total_requests
        else:
            stats["success_rate"] = 0.0
            stats["failure_rate"] = 0.0
        
        # 添加响应时间统计
        if self.response_times:
            stats["response_time_stats"] = {
                "min_ms": min(self.response_times),
                "max_ms": max(self.response_times),
                "avg_ms": stats["average_response_time_ms"],
                "p95_ms": self._calculate_percentile(self.response_times, 0.95),
                "p99_ms": self._calculate_percentile(self.response_times, 0.99)
            }
        
        stats["generated_at"] = datetime.now().isoformat()
        return stats
    
    def _calculate_percentile(self, values: List[float], percentile: float) -> float:
        """计算百分位数"""
        if not values:
            return 0.0
        
        sorted_values = sorted(values)
        index = int(len(sorted_values) * percentile)
        return sorted_values[min(index, len(sorted_values) - 1)]
    
    # 兼容现有接口
    def generate_completion_sync(self, prompt: str, 
                               config_override: Optional[Dict] = None) -> AzureLLMResponse:
        """同步版本的completion生成"""
        return asyncio.run(self.generate_completion(prompt, config_override))

# 全局客户端实例
_global_azure_client = None

def get_azure_openai_client() -> AzureOpenAIClient:
    """获取全局Azure OpenAI客户端实例"""
    global _global_azure_client
    if _global_azure_client is None:
        _global_azure_client = AzureOpenAIClient()
    return _global_azure_client

# 便捷函数
async def generate_azure_ai_analysis(prompt: str, **kwargs) -> str:
    """便捷的Azure AI分析生成函数"""
    client = get_azure_openai_client()
    response = await client.generate_completion(prompt, kwargs)
    
    if response.success:
        return response.content
    else:
        logger.error(f"Azure AI分析生成失败: {response.error}")
        return "Azure AI分析暂时不可用，请稍后重试。"

def generate_azure_ai_analysis_sync(prompt: str, **kwargs) -> str:
    """同步版本的Azure AI分析生成"""
    return asyncio.run(generate_azure_ai_analysis(prompt, **kwargs))