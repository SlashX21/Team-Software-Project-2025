"""
AI客户端工厂模式
支持OpenAI和Azure OpenAI的统一接口和自动降级
"""

import asyncio
import logging
from typing import Optional, Any, Dict
from abc import ABC, abstractmethod

from config.settings import get_llm_config, LLMConfig

logger = logging.getLogger(__name__)

class BaseAIClient(ABC):
    """AI客户端抽象基类"""
    
    @abstractmethod
    async def generate_completion(self, prompt: str, config_override: Optional[Dict] = None) -> Any:
        """生成AI回复"""
        pass
    
    @abstractmethod
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        pass
    
    @abstractmethod
    def get_usage_statistics(self) -> Dict[str, Any]:
        """获取使用统计"""
        pass

class AIClientFactory:
    """AI客户端工厂，支持OpenAI和Azure OpenAI"""
    
    @staticmethod
    def create_client(provider: str = None) -> BaseAIClient:
        """创建AI客户端"""
        if provider is None:
            # 从配置中获取默认provider
            config = get_llm_config()
            provider = getattr(config, 'provider', 'azure')
        
        if provider == "azure":
            from llm_evaluation.azure_openai_client import AzureOpenAIClient
            return AzureOpenAIClient()
        elif provider == "openai":
            from llm_evaluation.openai_client import OpenAIClient
            return OpenAIClient(get_llm_config())
        else:
            raise ValueError(f"不支持的AI服务提供商: {provider}")
    
    @staticmethod
    def create_with_fallback() -> BaseAIClient:
        """创建带降级的客户端"""
        # 优先使用Azure
        try:
            azure_client = AIClientFactory.create_client("azure")
            logger.info("Azure OpenAI客户端初始化成功，将在运行时验证连接")
            return azure_client
        except Exception as e:
            logger.warning(f"Azure OpenAI初始化失败: {e}")
            
        # 降级到OpenAI
        try:
            openai_client = AIClientFactory.create_client("openai")
            logger.info("降级到OpenAI客户端")
            return openai_client
        except Exception as e:
            logger.error(f"OpenAI初始化也失败: {e}")
            raise Exception("所有AI服务提供商都不可用")
    
    @staticmethod
    def create_resilient_client() -> 'ResilientAIClient':
        """创建具有自动故障恢复能力的客户端"""
        return ResilientAIClient()

class ResilientAIClient(BaseAIClient):
    """具有故障恢复能力的AI客户端包装器"""
    
    def __init__(self):
        self.primary_client = None
        self.fallback_client = None
        self.last_health_check = 0
        self.health_check_interval = 300  # 5分钟
        self._initialize_clients()
    
    def _initialize_clients(self):
        """初始化客户端 - 双服务模式：Azure优先，OpenAI降级"""
        logger.info("🔄 双服务模式：初始化Azure (主要) + OpenAI (降级)")
        
        # 主要服务：Azure OpenAI
        try:
            self.primary_client = AIClientFactory.create_client("azure")
            logger.info("✅ 主要服务: Azure OpenAI 初始化成功")
        except Exception as e:
            logger.warning(f"⚠️ Azure OpenAI初始化失败: {e}")
            self.primary_client = None
        
        # 降级服务：OpenAI API
        try:
            self.fallback_client = AIClientFactory.create_client("openai")
            logger.info("✅ 降级服务: OpenAI API 初始化成功")
        except Exception as e:
            logger.warning(f"⚠️ OpenAI API初始化失败: {e}")
            self.fallback_client = None
        
        # 检查是否至少有一个服务可用
        if not self.primary_client and not self.fallback_client:
            raise Exception("❌ 所有AI服务都初始化失败，无法提供服务")
        
        logger.info(f"🎯 双服务配置完成: Azure={'可用' if self.primary_client else '不可用'}, OpenAI={'可用' if self.fallback_client else '不可用'}")
    
    async def generate_completion(self, prompt: str, config_override: Optional[Dict] = None) -> Any:
        """生成AI回复 - 双服务模式：Azure优先，OpenAI降级"""
        
        logger.info(f"🔍 [双服务] 开始AI调用，prompt长度: {len(prompt)}")
        
        # 优先尝试Azure OpenAI
        if self.primary_client:
            try:
                logger.info("🟡 [Azure] 尝试Azure OpenAI主要服务...")
                response = await self.primary_client.generate_completion(prompt, config_override)
                
                if hasattr(response, 'success') and response.success:
                    logger.info(f"✅ [Azure] Azure OpenAI调用成功！")
                    logger.info(f"📊 [Azure] 响应详情: model={getattr(response, 'model', 'unknown')}, tokens={getattr(response.usage, 'total_tokens', 0) if hasattr(response, 'usage') and response.usage else 0}, 处理时间={getattr(response, 'processing_time_ms', 0)}ms")
                    logger.info(f"📝 [Azure] 内容长度: {len(response.content) if hasattr(response, 'content') and response.content else 0} 字符")
                    return response
                else:
                    error_info = getattr(response, 'error', 'Unknown error')
                    logger.warning(f"⚠️ [Azure] Azure OpenAI返回失败: {error_info}")
                    raise Exception(f"Azure OpenAI failed: {error_info}")
                    
            except Exception as e:
                logger.warning(f"🔄 [Azure] Azure OpenAI失败，准备降级: {e}")
        
        # 降级到OpenAI API
        if self.fallback_client:
            try:
                logger.info("🟡 [OpenAI] 降级到OpenAI API...")
                response = await self.fallback_client.generate_completion(prompt, config_override)
                
                if hasattr(response, 'success') and response.success:
                    logger.info(f"✅ [OpenAI] OpenAI API降级成功！")
                    logger.info(f"📊 [OpenAI] 响应详情: model={getattr(response, 'model', 'unknown')}, tokens={getattr(response.usage, 'total_tokens', 0) if hasattr(response, 'usage') and response.usage else 0}, 处理时间={getattr(response, 'processing_time_ms', 0)}ms")
                    logger.info(f"📝 [OpenAI] 内容长度: {len(response.content) if hasattr(response, 'content') and response.content else 0} 字符")
                    return response
                else:
                    error_info = getattr(response, 'error', 'Unknown error')
                    logger.error(f"❌ [OpenAI] OpenAI API降级也失败: {error_info}")
                    raise Exception(f"OpenAI API failed: {error_info}")
                    
            except Exception as e:
                logger.error(f"💥 [OpenAI] OpenAI API异常: {e}")
                raise Exception(f"所有AI服务都失败: Azure不可用, OpenAI: {str(e)}")
        
        # 如果两个服务都不可用
        raise Exception("❌ 没有可用的AI服务: Azure和OpenAI都未初始化")
    
    async def health_check(self) -> Dict[str, Any]:
        """健康检查"""
        current_time = asyncio.get_event_loop().time()
        
        # 检查是否需要重新初始化客户端
        if current_time - self.last_health_check > self.health_check_interval:
            await self._periodic_health_check()
            self.last_health_check = current_time
        
        primary_health = {"status": "unavailable"}
        fallback_health = {"status": "unavailable"}
        
        if self.primary_client:
            try:
                primary_health = await self.primary_client.health_check()
            except Exception as e:
                primary_health = {"status": "unhealthy", "error": str(e)}
        
        if self.fallback_client:
            try:
                fallback_health = await self.fallback_client.health_check()
            except Exception as e:
                fallback_health = {"status": "unhealthy", "error": str(e)}
        
        overall_status = "healthy" if (
            primary_health.get("status") == "healthy" or 
            fallback_health.get("status") == "healthy"
        ) else "unhealthy"
        
        return {
            "status": overall_status,
            "primary_client": primary_health,
            "fallback_client": fallback_health,
            "last_health_check": self.last_health_check
        }
    
    async def _periodic_health_check(self):
        """定期健康检查和客户端重新初始化"""
        # 如果主要客户端不可用，尝试重新初始化
        if not self.primary_client:
            try:
                self.primary_client = AIClientFactory.create_client("azure")
                logger.info("成功重新初始化主要客户端")
            except Exception:
                pass
        
        # 如果备用客户端不可用，尝试重新初始化
        if not self.fallback_client:
            try:
                self.fallback_client = AIClientFactory.create_client("openai")
                logger.info("成功重新初始化备用客户端")
            except Exception:
                pass
    
    def get_usage_statistics(self) -> Dict[str, Any]:
        """获取使用统计"""
        stats = {
            "primary_client": {},
            "fallback_client": {},
            "resilient_mode": True
        }
        
        if self.primary_client:
            try:
                stats["primary_client"] = self.primary_client.get_usage_statistics()
            except Exception as e:
                stats["primary_client"] = {"error": str(e)}
        
        if self.fallback_client:
            try:
                stats["fallback_client"] = self.fallback_client.get_usage_statistics()
            except Exception as e:
                stats["fallback_client"] = {"error": str(e)}
        
        return stats
    
    def _get_local_fallback_response(self, prompt: str) -> str:
        """获取本地降级响应"""
        prompt_lower = prompt.lower()
        
        # 根据prompt内容选择合适的降级响应
        if "条码" in prompt_lower or "barcode" in prompt_lower or "推荐" in prompt_lower:
            return "基于商品营养数据，我们为您推荐了更健康的替代选择。建议查看具体的营养成分对比信息。AI分析服务暂时不可用。"
        elif "小票" in prompt_lower or "receipt" in prompt_lower:
            return "小票分析功能暂时不可用。建议手动查看各商品的营养信息，关注糖分、脂肪和钠含量。"
        elif "营养" in prompt_lower or "nutrition" in prompt_lower:
            return "营养分析服务暂时不可用。建议参考商品包装上的营养成分表，选择低糖、低脂的健康选项。"
        else:
            return "AI分析服务暂时不可用，请稍后重试。您可以查看推荐结果的基础营养信息。"

# 全局实例
_global_resilient_client = None

def get_ai_client() -> BaseAIClient:
    """获取全局AI客户端实例（推荐使用）"""
    global _global_resilient_client
    if _global_resilient_client is None:
        _global_resilient_client = ResilientAIClient()
    return _global_resilient_client

def get_simple_ai_client(provider: str = None) -> BaseAIClient:
    """获取简单AI客户端（不带故障恢复）"""
    return AIClientFactory.create_client(provider)

# 便捷函数
async def generate_ai_completion(prompt: str, **kwargs) -> str:
    """便捷的AI完成生成函数"""
    client = get_ai_client()
    response = await client.generate_completion(prompt, kwargs)
    
    if hasattr(response, 'success') and response.success:
        return response.content
    elif hasattr(response, 'fallback_used') and response.fallback_used:
        logger.warning("使用了降级响应")
        return response.content
    else:
        logger.error(f"AI生成失败: {getattr(response, 'error', 'Unknown error')}")
        return "AI服务暂时不可用，请稍后重试。"

def generate_ai_completion_sync(prompt: str, **kwargs) -> str:
    """同步版本的AI完成生成"""
    return asyncio.run(generate_ai_completion(prompt, **kwargs))