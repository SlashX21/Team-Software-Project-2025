"""
OpenAI客户端 - 基于用户提供的API格式
支持异步调用、错误恢复、成本追踪和Spring Boot风格错误处理
"""

import asyncio
import logging
import time
import json
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import re

from openai import OpenAI
from config.settings import get_llm_config, LLMConfig
from config.constants import LLM_CONSTANTS, API_RESPONSE_TEMPLATE

logger = logging.getLogger(__name__)

@dataclass
class LLMResponse:
    """LLM响应数据类"""
    success: bool
    content: str
    usage: Dict[str, Any]
    model: str
    processing_time_ms: int
    attempt: int
    error: Optional[Dict] = None
    fallback_used: bool = False

class OpenAIClient:
    """OpenAI客户端 - 支持用户提供的API格式"""
    
    def __init__(self, config: Optional[LLMConfig] = None):
        self.config = config or get_llm_config()
        
        # 使用配置中的API密钥
        api_key = self.config.api_key
        if not api_key:
            raise ValueError("OpenAI API密钥未配置。请设置OPENAI_API_KEY环境变量或在配置中提供。")
        
        # 初始化OpenAI客户端
        self.client = OpenAI(api_key=api_key)
        
        # 使用用户指定的模型
        self.model = self.config.model
        
        # 使用统计
        self.token_usage_stats = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "total_tokens": 0,
            "total_cost_usd": 0.0,
            "average_response_time_ms": 0.0
        }
        
        # 响应时间记录
        self.response_times = []
        
    async def generate_completion(self, prompt: str, 
                                config_override: Optional[Dict] = None) -> LLMResponse:
        """
        异步生成AI回复
        Args:
            prompt: 输入提示词
            config_override: 配置覆盖参数
        Returns:
            LLM响应对象
        """
        start_time = time.time()
        
        # 合并配置
        effective_config = {
            "model": self.model,
            "max_tokens": self.config.max_tokens,
            "temperature": self.config.temperature,
            **(config_override or {})
        }
        
        # 更新请求统计
        self.token_usage_stats["total_requests"] += 1
        
        # 重试机制
        for attempt in range(1, self.config.retry_attempts + 1):
            try:
                # 调用用户提供的API格式
                response = await self._call_openai_api(prompt, effective_config)
                
                processing_time_ms = int((time.time() - start_time) * 1000)
                self.response_times.append(processing_time_ms)
                
                # 更新成功统计
                self.token_usage_stats["successful_requests"] += 1
                self._update_usage_stats(response, processing_time_ms)
                
                return LLMResponse(
                    success=True,
                    content=response.choices[0].message.content,
                    usage=self._extract_usage_info(response),
                    model=self.model,
                    processing_time_ms=processing_time_ms,
                    attempt=attempt,
                    fallback_used=False
                )
                
            except Exception as e:
                logger.warning(f"LLM调用失败 (尝试 {attempt}/{self.config.retry_attempts}): {e}")
                
                if attempt == self.config.retry_attempts:
                    # 最后一次尝试失败
                    processing_time_ms = int((time.time() - start_time) * 1000)
                    self.token_usage_stats["failed_requests"] += 1
                    
                    # 检查是否使用降级响应
                    if self.config.fallback_mode:
                        fallback_content = self._get_fallback_response(prompt)
                        return LLMResponse(
                            success=False,
                            content=fallback_content,
                            usage={},
                            model="fallback",
                            processing_time_ms=processing_time_ms,
                            attempt=attempt,
                            error=self._format_error(e),
                            fallback_used=True
                        )
                    else:
                        return LLMResponse(
                            success=False,
                            content="",
                            usage={},
                            model=self.model,
                            processing_time_ms=processing_time_ms,
                            attempt=attempt,
                            error=self._format_error(e),
                            fallback_used=False
                        )
                
                # 等待后重试（指数退避）
                await asyncio.sleep(min(2 ** (attempt - 1), 10))
        
        # 理论上不会执行到这里
        return LLMResponse(
            success=False,
            content="",
            usage={},
            model=self.model,
            processing_time_ms=0,
            attempt=0,
            error={"code": "UNEXPECTED_ERROR", "message": "Unexpected error in retry loop"}
        )

    async def _call_openai_api(self, prompt: str, config: Dict) -> Any:
        """调用标准OpenAI API"""
        try:
            response = await asyncio.to_thread(
                self.client.chat.completions.create,
                model=config["model"],
                messages=[
                    {"role": "system", "content": "你是一位专业的营养师和食品安全专家。"},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=config.get("max_tokens", 400),
                temperature=config.get("temperature", 0.7)
            )
            return response
        except Exception as e:
            logger.error(f"OpenAI API调用失败: {e}")
            raise e
    
    def _extract_usage_info(self, response: Any) -> Dict[str, Any]:
        """提取使用信息"""
        try:
            # 标准OpenAI响应格式
            if hasattr(response, 'usage'):
                usage = response.usage
                return {
                    "total_tokens": getattr(usage, 'total_tokens', 0),
                    "prompt_tokens": getattr(usage, 'prompt_tokens', 0),
                    "completion_tokens": getattr(usage, 'completion_tokens', 0)
                }
            else:
                # 如果没有usage信息，估算token使用量
                content = response.choices[0].message.content if hasattr(response, 'choices') else ""
                estimated_completion_tokens = len(content.split()) * 1.3
                return {
                    "total_tokens": int(estimated_completion_tokens),
                    "prompt_tokens": 0,
                    "completion_tokens": int(estimated_completion_tokens),
                    "estimated": True
                }
        except Exception as e:
            logger.warning(f"提取usage信息失败: {e}")
            return {"total_tokens": 0, "estimated": True}
    
    def _update_usage_stats(self, response: Any, processing_time_ms: int):
        """更新使用统计"""
        usage_info = self._extract_usage_info(response)
        tokens_used = usage_info.get("total_tokens", 0)
        
        self.token_usage_stats["total_tokens"] += tokens_used
        
        # 估算成本（基于GPT-4-mini定价）
        estimated_cost = self._estimate_cost(usage_info)
        self.token_usage_stats["total_cost_usd"] += estimated_cost
        
        # 更新平均响应时间
        if self.response_times:
            self.token_usage_stats["average_response_time_ms"] = sum(self.response_times) / len(self.response_times)
    
    def _estimate_cost(self, usage_info: Dict) -> float:
        """估算API调用成本"""
        # GPT-4-mini 2025定价（估算）
        input_cost_per_1k = 0.00015  # $0.15/1K tokens
        output_cost_per_1k = 0.0006   # $0.60/1K tokens
        
        prompt_tokens = usage_info.get("prompt_tokens", 0)
        completion_tokens = usage_info.get("completion_tokens", 0)
        
        input_cost = (prompt_tokens / 1000) * input_cost_per_1k
        output_cost = (completion_tokens / 1000) * output_cost_per_1k
        
        return input_cost + output_cost
    
    def _get_fallback_response(self, prompt: str) -> str:
        """获取降级响应"""
        fallback_responses = {
            "recommendation": "基于商品营养数据，我们为您推荐了更健康的替代选择。建议查看具体的营养成分对比信息。",
            "analysis": "很抱歉，AI分析服务暂时不可用。请查看推荐商品的营养数据进行对比。",
            "receipt": "小票分析功能暂时不可用。建议手动查看各商品的营养信息。",
            "default": "AI分析服务暂时不可用，请稍后重试。您可以查看推荐结果的基础信息。"
        }
        
        # 根据prompt内容选择合适的降级响应
        prompt_lower = prompt.lower()
        if "推荐" in prompt_lower or "recommend" in prompt_lower:
            return fallback_responses["recommendation"]
        elif "小票" in prompt_lower or "receipt" in prompt_lower:
            return fallback_responses["receipt"]
        elif "分析" in prompt_lower or "analysis" in prompt_lower:
            return fallback_responses["analysis"]
        else:
            return fallback_responses["default"]
    
    def _format_error(self, error: Exception) -> Dict[str, Any]:
        """格式化错误信息为Spring Boot风格"""
        error_type = type(error).__name__
        error_message = str(error)
        
        # 分类错误类型
        if "rate limit" in error_message.lower():
            error_code = "RATE_LIMIT_EXCEEDED"
            user_message = "API调用频率过高，请稍后重试"
        elif "invalid api key" in error_message.lower():
            error_code = "INVALID_API_KEY"
            user_message = "API密钥无效"
        elif "timeout" in error_message.lower():
            error_code = "REQUEST_TIMEOUT"
            user_message = "请求超时，请重试"
        elif "insufficient_quota" in error_message.lower():
            error_code = "INSUFFICIENT_QUOTA"
            user_message = "API配额不足"
        else:
            error_code = "LLM_API_ERROR"
            user_message = "AI服务暂时不可用"
        
        return {
            "code": error_code,
            "message": user_message,
            "details": {
                "error_type": error_type,
                "original_message": error_message,
                "timestamp": datetime.now().isoformat()
            }
        }
    
    # 同步版本的API调用方法
    def generate_completion_sync(self, prompt: str, 
                               config_override: Optional[Dict] = None) -> LLMResponse:
        """同步版本的completion生成"""
        return asyncio.run(self.generate_completion(prompt, config_override))
    
    def validate_prompt(self, prompt: str) -> Dict[str, Any]:
        """验证prompt质量和安全性"""
        issues = []
        recommendations = []
        
        # 长度检查
        if len(prompt) > LLM_CONSTANTS["max_prompt_length"]:
            issues.append("Prompt过长，可能影响响应质量")
            recommendations.append("建议将prompt控制在4000字符以内")
        
        if len(prompt) < 50:
            issues.append("Prompt过短，可能影响分析质量")
            recommendations.append("建议提供更详细的上下文信息")
        
        # 安全关键词检查
        safety_keywords = LLM_CONSTANTS["safety_keywords"]
        for keyword in safety_keywords:
            if keyword in prompt:
                issues.append(f"包含医疗相关关键词: {keyword}")
                recommendations.append("请确保添加适当的医疗免责声明")
        
        # 结构化检查
        if "用户画像" not in prompt and "商品" not in prompt:
            issues.append("缺少必要的上下文信息")
            recommendations.append("建议包含用户画像和商品信息")
        
        return {
            "valid": len(issues) == 0,
            "issues": issues,
            "recommendations": recommendations,
            "estimated_tokens": len(prompt.split()) * 1.3,
            "estimated_cost": self._estimate_prompt_cost(prompt)
        }
    
    def _estimate_prompt_cost(self, prompt: str) -> float:
        """估算prompt成本"""
        estimated_tokens = len(prompt.split()) * 1.3
        input_cost_per_1k = 0.00015
        return (estimated_tokens / 1000) * input_cost_per_1k
    
    def get_usage_statistics(self) -> Dict[str, Any]:
        """获取使用统计信息"""
        stats = self.token_usage_stats.copy()
        
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
    
    def reset_statistics(self):
        """重置统计信息"""
        self.token_usage_stats = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "total_tokens": 0,
            "total_cost_usd": 0.0,
            "average_response_time_ms": 0.0
        }
        self.response_times = []
        logger.info("LLM使用统计已重置")
    
    def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        try:
            # 发送简单的测试请求
            test_prompt = "请回复'健康检查通过'"
            start_time = time.time()
            
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "user", "content": test_prompt}
                ],
                max_tokens=50,
                temperature=0.1
            )
            
            response_time = (time.time() - start_time) * 1000
            
            return {
                "status": "healthy",
                "model": self.model,
                "response_time_ms": response_time,
                "api_accessible": True,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "unhealthy",
                "model": self.model,
                "error": str(e),
                "api_accessible": False,
                "timestamp": datetime.now().isoformat()
            }

# 全局客户端实例
_global_client = None

def get_openai_client() -> OpenAIClient:
    """获取全局OpenAI客户端实例"""
    global _global_client
    if _global_client is None:
        _global_client = OpenAIClient()
    return _global_client

# 便捷函数
async def generate_ai_analysis(prompt: str, **kwargs) -> str:
    """便捷的AI分析生成函数"""
    client = get_openai_client()
    response = await client.generate_completion(prompt, kwargs)
    
    if response.success:
        return response.content
    elif response.fallback_used:
        logger.warning("使用了降级响应")
        return response.content
    else:
        logger.error(f"AI分析生成失败: {response.error}")
        return "AI分析暂时不可用，请稍后重试。"

def generate_ai_analysis_sync(prompt: str, **kwargs) -> str:
    """同步版本的AI分析生成"""
    return asyncio.run(generate_ai_analysis(prompt, **kwargs))