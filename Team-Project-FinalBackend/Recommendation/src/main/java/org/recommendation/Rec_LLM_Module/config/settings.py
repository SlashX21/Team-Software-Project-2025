"""
Grocery Guardian 项目配置文件
支持多环境配置和Java兼容性
"""

import os
from typing import Dict, Any
from dataclasses import dataclass, field
from enum import Enum
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

class Environment(Enum):
    """环境类型枚举"""
    LOCAL = "local"
    AZURE = "azure"
    TESTING = "testing"
    JAVA_INTEGRATION = "java_integration"  # 新增Java集成环境

@dataclass
class DatabaseConfig:
    """数据库配置"""
    type: str
    connection_string: str
    echo: bool = False
    pool_size: int = 10
    max_overflow: int = 20
    timeout: int = 30

@dataclass
class LLMConfig:
    """LLM配置"""
    provider: str = "azure"  # 默认使用Azure
    
    # OpenAI配置（备用）
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    
    # Azure OpenAI配置（主要）
    azure_api_key: str = ""
    azure_endpoint: str = ""
    azure_api_version: str = "2024-02-01"
    azure_deployment_name: str = "gpt-4o-mini-prod"
    
    # 通用配置
    api_key: str = ""  # 向后兼容
    model: str = "gpt-4o-mini"  # 向后兼容
    max_tokens: int = 1200  # Increased for o4-mini reasoning tokens
    # temperature removed for model compatibility
    timeout: int = 30
    retry_attempts: int = 3
    fallback_mode: bool = True
    cost_tracking: bool = True
    
    # Azure特定的并发配置
    max_requests_per_minute: int = 1000  # Azure限制
    max_tokens_per_minute: int = 100000  # Azure限制

@dataclass
class RecommendationConfig:
    """推荐算法配置"""
    max_recommendations: int = 5
    similarity_threshold: float = 0.6
    time_decay_factor: float = 0.95
    category_constraint: bool = True
    
    # 动态权重配置 - 核心优化
    scoring_weights: Dict[str, Dict[str, float]] = field(default_factory=lambda: {
        "lose_weight": {
            "nutrition_weight": 0.98,    # 减脂用户营养优先级极高
            "similarity_weight": 0.02,   # 相似度权重降到最低
            "collaborative_weight": 0.0  # 暂时禁用协同过滤避免干扰
        },
        "gain_muscle": {
            "nutrition_weight": 0.95,    # 增肌用户营养优先级很高
            "similarity_weight": 0.05,   # 相似度权重很低
            "collaborative_weight": 0.0  # 暂时禁用协同过滤
        },
        "maintain": {
            "nutrition_weight": 0.60,    # 维持健康用户平衡配置
            "similarity_weight": 0.25,   # 适度考虑相似度
            "collaborative_weight": 0.15 # 考虑用户偏好
        }
    })
    
    # 营养评分策略保持原有配置
    nutrition_strategies: Dict[str, Dict[str, float]] = field(default_factory=lambda: {
        "lose_weight": {
            "energy_kcal_100g": -0.4,
            "fat_100g": -0.3,
            "sugars_100g": -0.3,
            "proteins_100g": 0.2,
            "fiber_bonus": 0.3
        },
        "gain_muscle": {
            "proteins_100g": 0.5,
            "carbohydrates_100g": 0.2,
            "energy_kcal_100g": 0.3,
            "fat_100g": 0.1,
            "bcaa_bonus": 0.4
        },
        "maintain": {
            "balance_score": 0.4,
            "variety_score": 0.3,
            "natural_bonus": 0.3
        }
    })

class ConfigManager:
    """配置管理器 - 支持多环境和Java兼容性"""
    
    def __init__(self, environment: str = "local"):
        if isinstance(environment, str):
            self.environment = Environment(environment)
        else:
            self.environment = environment
        self._configs = self._load_configs()
        
    def _load_configs(self) -> Dict[str, Any]:
        """加载环境配置"""
        base_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(base_dir)
        openai_api_key = os.getenv("OPENAI_API_KEY")
        if not openai_api_key:
            raise ValueError("OPENAI_API_KEY环境变量未设置！请检查.env文件。")
        
        configs = {
            Environment.LOCAL: {
                "database": DatabaseConfig(
                    type="sqlite",
                    connection_string=f"sqlite:///{project_root}/data/grocery_guardian.db",
                    echo=False
                ),
                "llm": LLMConfig(
                    api_key=os.getenv("OPENAI_API_KEY", ""),
                    model="gpt-4o-mini",
                    max_tokens=1200,  # Increased for o4-mini reasoning tokens
                    fallback_mode=True,
                    cost_tracking=True
                ),
                "recommendation": RecommendationConfig(
                    max_recommendations=5,
                    similarity_threshold=0.6,
                    category_constraint=True
                )
            },
            
            # 新增Java集成环境配置
            Environment.JAVA_INTEGRATION: {
                "database": DatabaseConfig(
                    type=os.getenv("DB_TYPE", "mysql"),  # 支持mysql/postgresql
                    connection_string=os.getenv(
                        "JAVA_DB_CONNECTION_STRING",
                        # MySQL示例: "mysql+pymysql://user:password@localhost:3306/grocery_guardian"
                        # PostgreSQL示例: "postgresql://user:password@localhost:5432/grocery_guardian"
                        "mysql+pymysql://root:password@localhost:3306/grocery_guardian"
                    ),
                    echo=False,
                    pool_size=15,
                    max_overflow=25,
                    timeout=45
                ),
                "llm": LLMConfig(
                    provider="azure",
                    azure_api_key=os.getenv("AZURE_OPENAI_API_KEY", "a0aad09ad49949f8960ed30cc9d39c0a"),
                    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT", "https://xiangopenai2025.openai.azure.com/"),
                    azure_api_version="2024-12-01-preview",
                    azure_deployment_name="o4-mini",
                    openai_api_key=os.getenv("OPENAI_API_KEY", ""),  # 备用
                    api_key=os.getenv("OPENAI_API_KEY", ""),  # 向后兼容，使用OpenAI key
                    model="o4-mini",
                    max_tokens=1200,  # Increased for o4-mini reasoning tokens
                    fallback_mode=True,
                    cost_tracking=True,
                    max_requests_per_minute=1000,
                    max_tokens_per_minute=100000
                ),
                "recommendation": RecommendationConfig(
                    max_recommendations=5,
                    similarity_threshold=0.6,
                    category_constraint=True
                )
            },
            
            Environment.AZURE: {
                "database": DatabaseConfig(
                    type="sqlserver",
                    connection_string=os.getenv(
                        "AZURE_SQL_CONNECTION_STRING",
                        "mssql+pyodbc://user:pass@server/db?driver=ODBC+Driver+17+for+SQL+Server"
                    ),
                    echo=False,
                    pool_size=10,
                    max_overflow=20
                ),
                "llm": LLMConfig(
                    provider="azure",
                    azure_api_key=os.getenv("AZURE_OPENAI_API_KEY", "a0aad09ad49949f8960ed30cc9d39c0a"),
                    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT", "https://xiangopenai2025.openai.azure.com/"),
                    azure_api_version="2024-12-01-preview",
                    azure_deployment_name="o4-mini",
                    api_key=os.getenv("AZURE_OPENAI_API_KEY", "73540b77e3304ee8b9614e8593f08f02"),  # 向后兼容
                    model="o4-mini",
                    max_tokens=1200,  # Increased for o4-mini reasoning tokens
                    timeout=45,
                    fallback_mode=True,
                    cost_tracking=True,
                    max_requests_per_minute=1000,
                    max_tokens_per_minute=100000
                ),
                "recommendation": RecommendationConfig(
                    max_recommendations=5,
                    similarity_threshold=0.6,
                    category_constraint=True
                )
            },
            
            Environment.TESTING: {
                "database": DatabaseConfig(
                    type="sqlite",
                    connection_string="sqlite:///:memory:",
                    echo=True
                ),
                "llm": LLMConfig(
                    provider="mock",
                    api_key="test_key",
                    model="mock-gpt",
                    max_tokens=800,
                    timeout=10,
                    fallback_mode=True,
                    cost_tracking=False
                ),
                "recommendation": RecommendationConfig(
                    max_recommendations=3,
                    similarity_threshold=0.5,
                    category_constraint=True
                )
            }
        }
        
        return configs
    
    def get_database_config(self) -> DatabaseConfig:
        """获取数据库配置"""
        return self._configs[self.environment]["database"]
    
    def get_llm_config(self) -> LLMConfig:
        """获取LLM配置"""
        return self._configs[self.environment]["llm"]
    
    def get_recommendation_config(self) -> RecommendationConfig:
        """获取推荐算法配置"""
        return self._configs[self.environment]["recommendation"]
    
    def get_java_compatible_config(self) -> Dict[str, Any]:
        """获取Java兼容的配置格式"""
        config = self._configs[self.environment]
        
        # 转换为Java风格的配置
        java_config = {
            "databaseConfig": {
                "type": config["database"].type,
                "connectionString": config["database"].connection_string,
                "poolSize": config["database"].pool_size,
                "maxOverflow": config["database"].max_overflow,
                "timeout": config["database"].timeout
            },
            "llmConfig": {
                "provider": config["llm"].provider,
                "apiKey": config["llm"].api_key,
                "model": config["llm"].model,
                "maxTokens": config["llm"].max_tokens,
                # "temperature" removed for model compatibility
                "retryAttempts": config["llm"].retry_attempts,
                "fallbackMode": config["llm"].fallback_mode,
                "costTracking": config["llm"].cost_tracking
            },
            "recommendationConfig": {
                "maxRecommendations": config["recommendation"].max_recommendations,
                "similarityThreshold": config["recommendation"].similarity_threshold,
                "categoryConstraint": config["recommendation"].category_constraint,
                "nutritionStrategies": config["recommendation"].nutrition_strategies
            }
        }
        
        return java_config

# 全局配置实例
config_manager = ConfigManager(os.getenv("ENVIRONMENT", "local"))

# 便捷访问函数
def get_database_config() -> DatabaseConfig:
    """获取数据库配置"""
    return config_manager.get_database_config()

def get_llm_config() -> LLMConfig:
    """获取LLM配置"""
    return config_manager.get_llm_config()

def get_recommendation_config() -> RecommendationConfig:
    """获取推荐算法配置"""
    return config_manager.get_recommendation_config()