"""
Grocery Guardian 常量定义
包含营养策略、过敏原类型、API响应格式等
"""

from typing import Dict, List, Any
from enum import Enum

class NutritionGoal(Enum):
    """营养目标枚举"""
    LOSE_WEIGHT = "lose_weight"
    GAIN_MUSCLE = "gain_muscle"
    MAINTAIN = "maintain"
    GENERAL_HEALTH = "general_health"

class AllergenPresenceType(Enum):
    """过敏原包含类型"""
    CONTAINS = "contains"
    MAY_CONTAIN = "may_contain"
    TRACES = "traces"

class ActivityLevel(Enum):
    """活动水平枚举"""
    SEDENTARY = "sedentary"
    LIGHT = "light"
    MODERATE = "moderate"
    ACTIVE = "active"
    VERY_ACTIVE = "very_active"

class RecommendationType(Enum):
    """推荐类型枚举"""
    BARCODE_SCAN = "barcode_scan"
    RECEIPT_ANALYSIS = "receipt_analysis"

class PreferenceType(Enum):
    """用户偏好类型"""
    LIKE = "like"
    DISLIKE = "dislike"
    BLACKLIST = "blacklist"

# 营养策略权重配置
NUTRITION_STRATEGIES = {
    NutritionGoal.LOSE_WEIGHT.value: {
        "energy_kcal_100g": -0.4,    # 低热量优先
        "fat_100g": -0.3,            # 低脂肪
        "sugars_100g": -0.3,         # 低糖分
        "proteins_100g": 0.2,        # 适量蛋白质
        "fiber_bonus": 0.3           # 高纤维加分
    },
    NutritionGoal.GAIN_MUSCLE.value: {
        "proteins_100g": 0.5,        # 高蛋白质优先
        "carbohydrates_100g": 0.2,   # 适量碳水
        "energy_kcal_100g": 0.3,     # 充足热量
        "fat_100g": 0.1,             # 适量脂肪
        "bcaa_bonus": 0.4            # 支链氨基酸加分
    },
    NutritionGoal.MAINTAIN.value: {
        "balance_score": 0.4,        # 营养均衡
        "variety_score": 0.3,        # 营养多样性
        "natural_bonus": 0.3         # 天然成分加分
    },
    NutritionGoal.GENERAL_HEALTH.value: {
        "nutrient_density": 0.4,     # 营养密度
        "natural_bonus": 0.3,        # 天然成分
        "balance_score": 0.3         # 营养平衡
    }
}

# 商品分类标准化映射
CATEGORY_MAPPING = {
    'Food': [
        'food', 'meat', 'seafood', 'dairy', 'vegetables', 'fruits',
        'grains', 'cereals', 'bread', 'pasta', 'frozen-foods'
    ],
    'Beverages': [
        'beverages', 'drinks', 'water', 'juices', 'soft-drinks',
        'coffee', 'tea', 'alcoholic-beverages'
    ],
    'Snacks': [
        'snacks', 'candy', 'chocolate', 'cookies', 'chips',
        'crackers', 'nuts-seeds', 'desserts'
    ],
    'Health & Supplements': [
        'supplements', 'vitamins', 'protein-powder', 'health-food',
        'organic', 'diet-products', 'baby-food'
    ],
    'Condiments & Others': [
        'condiments', 'sauces', 'spices', 'oils', 'vinegar',
        'household', 'personal-care', 'others'
    ]
}

# 常见过敏原关键词映射
ALLERGEN_KEYWORDS = {
    'milk': ['milk', 'dairy', 'lactose', 'casein', 'whey', 'butter', 'cream'],
    'eggs': ['egg', 'albumin', 'lecithin', 'ovomucin', 'ovalbumin'],
    'nuts': ['nuts', 'almond', 'walnut', 'pecan', 'cashew', 'hazelnut', 'pistachio'],
    'gluten': ['wheat', 'gluten', 'barley', 'rye', 'oats', 'spelt', 'kamut'],
    'soy': ['soy', 'soya', 'soybean', 'tofu', 'tempeh', 'miso'],
    'fish': ['fish', 'salmon', 'tuna', 'cod', 'mackerel', 'sardine'],
    'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster', 'oyster', 'mussel'],
    'sesame': ['sesame', 'tahini', 'sesame oil', 'sesamum'],
    'peanuts': ['peanut', 'groundnut', 'arachis', 'peanut oil'],
    'tree_nuts': ['tree nuts', 'brazil nut', 'macadamia', 'pine nut'],
    'celery': ['celery', 'celeriac', 'celery seed'],
    'mustard': ['mustard', 'mustard seed', 'dijon'],
    'lupin': ['lupin', 'lupine', 'lupin flour'],
    'sulphites': ['sulphite', 'sulfite', 'sulphur dioxide', 'SO2']
}

# 偏好推断触发条件
PREFERENCE_INFERENCE_CONFIG = {
    "trigger_threshold": 3,          # 连续3次购买触发推断
    "confidence_threshold": 0.7,     # 置信度阈值
    "time_window_days": 30,          # 时间窗口30天
    "time_decay_factor": 0.95,       # 时间衰减因子
    "purchase_weight_multiplier": 2.0 # 购买行为权重倍数
}

# 营养数据验证范围
NUTRITION_VALIDATION_RANGES = {
    "energy_kcal_100g": (0, 2000),
    "proteins_100g": (0, 200),
    "fat_100g": (0, 200),
    "carbohydrates_100g": (0, 200),
    "sugars_100g": (0, 200),
    "fiber_100g": (0, 100),
    "sodium_100g": (0, 10000)  # mg
}

# 用户生理数据验证范围
USER_VALIDATION_RANGES = {
    "age": (13, 120),
    "height_cm": (100, 250),
    "weight_kg": (30, 300),
    "daily_calories_target": (800, 5000),
    "daily_protein_target": (20, 300),
    "daily_carb_target": (50, 800),
    "daily_fat_target": (20, 200)
}

# HTTP状态码与Spring Boot对齐
HTTP_STATUS_MAPPING = {
    "success": 200,
    "created": 201,
    "bad_request": 400,
    "unauthorized": 401,
    "forbidden": 403,
    "not_found": 404,
    "internal_error": 500,
    "service_unavailable": 503
}

# API响应格式模板
API_RESPONSE_TEMPLATE = {
    "success": True,
    "message": "Success",
    "data": None,
    "error": None,
    "timestamp": None,
    "processing_metadata": {
        "algorithm_version": "v1.0",
        "processing_time_ms": 0,
        "llm_tokens_used": 0,
        "confidence_score": 0.0
    }
}

# LLM相关常量
LLM_CONSTANTS = {
    "max_prompt_length": 4000,
    "max_response_length": 1000,
    "default_temperature": 0.7,
    "safety_keywords": [
        "医疗建议", "治疗", "诊断", "疾病", "药物", "医生"
    ],
    "quality_keywords": {
        "high_quality": ["具体数据", "营养成分", "健康建议", "科学依据"],
        "medium_quality": ["推荐", "建议", "改善", "优化"],
        "low_quality": ["可能", "或许", "大概", "一般来说"]
    }
}

# 性能监控指标
PERFORMANCE_METRICS = {
    "target_response_times": {
        "simple_recommendation": 1.0,      # 简单推荐<1秒
        "complex_analysis": 2.0,           # 复杂分析<2秒  
        "receipt_processing": 3.0,         # 小票处理<3秒
        "database_query": 0.1,             # 数据库查询<100ms
        "llm_call": 5.0                    # LLM调用<5秒
    },
    "quality_thresholds": {
        "allergen_safety_rate": 1.0,       # 100%过敏原安全率
        "nutrition_improvement_rate": 0.8,  # 80%营养改善率
        "recommendation_diversity": 0.7,    # 70%推荐多样性
        "user_goal_alignment": 0.85,        # 85%用户目标匹配度
        "llm_quality_score": 0.7            # 70%LLM质量分数
    }
}

# 缓存配置
CACHE_CONFIG = {
    "ttl": {
        "product_info": 1800,          # 商品信息缓存30分钟
        "user_preferences": 3600,      # 用户偏好缓存1小时
        "recommendation_results": 900,  # 推荐结果缓存15分钟
        "allergen_mapping": 86400,     # 过敏原映射缓存1天
        "similarity_matrix": 3600      # 相似度矩阵缓存1小时
    },
    "max_cache_size": 1000,            # 最大缓存条数
    "cleanup_interval": 3600           # 清理间隔1小时
}

# 测试数据常量
TEST_DATA_CONFIG = {
    "test_users": {
        "fitness_enthusiast": {
            "nutrition_goal": "gain_muscle",
            "allergens": ["milk", "nuts"],
            "daily_protein_target": 150
        },
        "weight_loss_user": {
            "nutrition_goal": "lose_weight", 
            "allergens": ["gluten", "soy"],
            "daily_calories_target": 1800
        },
        "maintenance_user": {
            "nutrition_goal": "maintain",
            "allergens": ["shellfish"],
            "daily_calories_target": 2200
        }
    },
    "test_scenarios": {
        "barcode_scan_count": 50,
        "receipt_analysis_count": 20,
        "edge_case_count": 15
    }
}

# 日志配置
LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "standard": {
            "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
        },
        "detailed": {
            "format": "%(asctime)s [%(levelname)s] %(name)s:%(lineno)d: %(message)s"
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": "INFO",
            "formatter": "standard"
        },
        "file": {
            "class": "logging.FileHandler",
            "filename": "logs/grocery_guardian.log",
            "level": "DEBUG",
            "formatter": "detailed"
        }
    },
    "root": {
        "level": "INFO",
        "handlers": ["console", "file"]
    }
}