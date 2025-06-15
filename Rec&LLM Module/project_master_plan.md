# Grocery Guardian 推荐系统 - 项目统筹开发档案

## 🎯 项目概述

**项目名称**: Grocery Guardian AI推荐与评估模块Demo  
**开发环境**: macOS + PyCharm/Cursor + Navicat  
**技术栈**: Python 3.9+ + SQLite + FastAPI + OpenAI API  
**目标**: 构建独立运行的商品推荐算法和LLM评估demo模块

## 🏗️ 整体架构设计

### 核心模块架构
```
grocery_guardian_demo/
├── database/                 # 数据库模块
│   ├── schema.sql           # 数据库结构定义
│   ├── data_processor.py    # 数据预处理和导入
│   └── db_manager.py        # 数据库连接和操作
├── recommendation/           # 推荐算法模块
│   ├── filters.py           # 多层过滤器
│   ├── collaborative_filter.py  # 协同过滤算法
│   ├── nutrition_optimizer.py   # 营养优化策略
│   └── recommender.py       # 推荐引擎主控制器
├── llm_evaluation/          # LLM评估模块
│   ├── prompt_templates.py  # Prompt模板管理
│   ├── openai_client.py     # OpenAI API客户端
│   └── response_parser.py   # LLM响应解析
├── api/                     # API接口层
│   ├── main.py             # FastAPI主程序
│   ├── models.py           # 数据模型定义
│   └── endpoints.py        # API端点实现
├── tests/                   # 测试模块
│   ├── test_data/          # 测试数据文件
│   ├── scenarios/          # 测试场景配置
│   └── validators.py       # 测试验证器
├── config/                  # 配置管理
│   ├── settings.py         # 项目配置
│   └── constants.py        # 常量定义
└── data/                   # 数据文件
    ├── ireland_products_standardized.csv
    ├── grocery_guardian.db  # SQLite数据库文件
    └── sample_data/        # 生成的测试数据
```

## 🔗 模块间接口规范

### 1. 数据库适配器接口（无痛集成设计）
```python
from abc import ABC, abstractmethod
from typing import Dict, List, Optional

class DatabaseAdapter(ABC):
    """数据库适配器抽象基类，支持SQLite到SQL Server无痛迁移"""
    
    @abstractmethod
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]
    
    @abstractmethod
    def get_similar_products(self, category: str, filters: Dict) -> List[Dict]
    
    @abstractmethod
    def get_user_profile(self, user_id: int) -> Optional[Dict]
    
    @abstractmethod
    def get_user_allergens(self, user_id: int) -> List[Dict]
    
    @abstractmethod
    def get_purchase_history(self, user_id: int, limit: int) -> List[Dict]
    
    @abstractmethod
    def log_recommendation(self, log_data: Dict) -> bool

class DatabaseManager:
    """数据库管理器，使用适配器模式支持多种数据库"""
    def __init__(self, adapter: DatabaseAdapter):
        self.adapter = adapter
    
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        return self.adapter.get_product_by_barcode(barcode)
    
    # 其他方法通过适配器调用...
```

### 2. 推荐算法模块接口
```python
class RecommendationEngine:
    def recommend_alternatives(
        original_product_barcode: str,
        user_id: int,
        max_recommendations: int = 5
    ) -> List[RecommendationResult]
    
    def analyze_receipt_recommendations(
        purchased_items: List[dict],
        user_id: int
    ) -> ReceiptAnalysisResult
```

### 3. LLM评估模块接口
```python
class LLMEvaluator:
    def generate_recommendation_analysis(
        original_product: Product,
        recommended_products: List[Product],
        user_profile: UserProfile
    ) -> LLMAnalysisResult
    
    def generate_receipt_insights(
        purchase_analysis: ReceiptAnalysisResult,
        user_profile: UserProfile
    ) -> LLMInsightsResult
```

## 📊 核心数据流

### 条形码扫描推荐流程
```
输入: {scan_type: "barcode", user_id: int, product_barcode: str}
    ↓
1. 数据库查询原商品信息和用户画像
    ↓
2. 推荐算法执行多层过滤和评分
    ↓
3. LLM生成个性化分析和推荐理由
    ↓
输出: {recommendations: [...], llm_analysis: {...}, metadata: {...}}
```

### 小票扫描分析流程
```
输入: {scan_type: "receipt", user_id: int, purchased_items: [...]}
    ↓
1. 批量查询商品信息和营养数据
    ↓
2. 逐商品推荐分析和整体营养评估
    ↓
3. LLM生成综合购买洞察和改进建议
    ↓
输出: {item_recommendations: [...], overall_analysis: {...}, insights: {...}}
```

## 🎛️ 核心配置参数（适配友好设计）

### 数据库配置（多环境支持）
```python
DATABASE_CONFIG = {
    "local": {
        "type": "sqlite",
        "connection_string": "sqlite:///data/grocery_guardian.db",
        "echo": False
    },
    "azure": {
        "type": "sqlserver", 
        "connection_string": "mssql+pyodbc://user:pass@server/db?driver=ODBC+Driver+17+for+SQL+Server",
        "echo": False,
        "pool_size": 10,
        "max_overflow": 20
    }
}

# 数据类型映射（SQLite <-> SQL Server兼容）
TYPE_MAPPING = {
    "sqlite_to_sqlserver": {
        "INTEGER": "INT",
        "TEXT": "NVARCHAR(MAX)",
        "REAL": "FLOAT", 
        "BLOB": "VARBINARY(MAX)",
        "BOOLEAN": "BIT"
    }
}
```

### 推荐算法配置
```python
RECOMMENDATION_CONFIG = {
    "max_recommendations": 5,
    "nutrition_strategies": {
        "lose_weight": {"energy_kcal_100g": -0.4, "fat_100g": -0.3, "sugars_100g": -0.3},
        "gain_muscle": {"proteins_100g": 0.5, "carbohydrates_100g": 0.2, "energy_kcal_100g": 0.3},
        "maintain": {"balance_score": 0.4, "variety_score": 0.6}
    },
    "similarity_threshold": 0.6,
    "time_decay_factor": 0.95,
    "category_constraint": True
}
```

### Java兼容的数据传输对象设计
```python
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field

class ProductDTO(BaseModel):
    """与Java Product实体兼容的数据传输对象"""
    barcode: str = Field(..., max_length=20)
    name: str = Field(..., max_length=200)
    brand: Optional[str] = Field(None, max_length=100)
    ingredients: Optional[str] = None
    allergens: Optional[str] = None
    energyPer100g: Optional[float] = Field(None, alias="energy_100g")
    energyKcalPer100g: Optional[float] = Field(None, alias="energy_kcal_100g")
    fatPer100g: Optional[float] = Field(None, alias="fat_100g")
    saturatedFatPer100g: Optional[float] = Field(None, alias="saturated_fat_100g")
    carbohydratesPer100g: Optional[float] = Field(None, alias="carbohydrates_100g")
    sugarsPer100g: Optional[float] = Field(None, alias="sugars_100g")
    proteinsPer100g: Optional[float] = Field(None, alias="proteins_100g")
    servingSize: Optional[str] = Field(None, max_length=50, alias="serving_size")
    category: str = Field(..., max_length=50)
    
### LLM配置（生产环境友好）
```python
LLM_CONFIG = {
    "model": "gpt-3.5-turbo",
    "max_tokens": 800,
    "temperature": 0.7,
    "timeout": 30,
    "retry_attempts": 3,
    "fallback_mode": True,
    # Spring Boot集成友好的错误处理
    "error_response_format": "spring_boot_standard"
}
```

### Spring Boot兼容的API响应格式
```python
class ApiResponse(BaseModel):
    """与Spring Boot ResponseEntity兼容的响应格式"""
    success: bool = True
    message: str = "Success"
    data: Optional[Dict] = None
    error: Optional[Dict] = None
    timestamp: str = Field(default_factory=lambda: datetime.now().isoformat())
    
    @classmethod
    def success_response(cls, data: Dict, message: str = "Success"):
        return cls(success=True, message=message, data=data)
    
    @classmethod  
    def error_response(cls, error_code: str, error_message: str, details: Optional[Dict] = None):
        return cls(
            success=False,
            message=error_message,
            error={
                "code": error_code,
                "message": error_message,
                "details": details or {}
            }
        )

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
```
```

## 🧪 测试数据标准

### 标准输入格式
```json
{
  "barcode_scan": {
    "scan_type": "barcode",
    "user_id": 1,
    "product_barcode": "1234567890123",
    "scan_context": {
      "location": "Tesco",
      "timestamp": "2025-06-12T14:30:00Z"
    }
  },
  "receipt_scan": {
    "scan_type": "receipt",
    "user_id": 1,
    "purchased_items": [
      {"barcode": "1234567890123", "quantity": 2, "unit_price": 3.99},
      {"barcode": "9876543210987", "quantity": 1, "unit_price": 5.49}
    ],
    "receipt_context": {
      "store": "SuperValu",
      "purchase_date": "2025-06-12",
      "total_amount": 13.47
    }
  }
}
```

### 标准输出格式
```json
{
  "recommendation_id": "rec_20250612_001",
  "scan_type": "barcode|receipt",
  "user_profile_summary": {
    "user_id": 1,
    "nutrition_goal": "lose_weight",
    "allergens_count": 3,
    "preference_confidence": 0.75
  },
  "recommendations": [
    {
      "rank": 1,
      "product": {
        "barcode": "alternative_product_barcode",
        "name": "Product Name",
        "brand": "Brand Name",
        "category": "Food",
        "nutrition_100g": {...}
      },
      "recommendation_score": 0.87,
      "nutrition_improvement": {
        "calories_reduction": 120,
        "protein_increase": 5.2,
        "allergen_safe": true
      }
    }
  ],
  "llm_analysis": {
    "summary": "个性化推荐摘要",
    "detailed_analysis": "详细营养分析和健康建议",
    "action_suggestions": ["具体行动建议1", "具体行动建议2"]
  },
  "processing_metadata": {
    "algorithm_version": "v1.0",
    "processing_time_ms": 1250,
    "llm_tokens_used": 456,
    "confidence_score": 0.85
  }
}
```

## 🔧 开发工具配置

### Cursor AI助手使用指南
1. **项目上下文**: 将此档案文件设置为项目主要参考
2. **代码风格**: 遵循PEP 8，使用类型注解
3. **错误处理**: 实现comprehensive异常处理和日志记录
4. **性能优化**: 关注数据库查询效率和API响应时间

### 依赖管理
```python
# requirements.txt核心依赖
fastapi>=0.68.0
uvicorn>=0.15.0
sqlalchemy>=1.4.22
pandas>=1.3.0
numpy>=1.21.0
scikit-learn>=0.24.2
openai>=0.27.0
pydantic>=1.8.2
python-multipart>=0.0.5
aiofiles>=0.7.0
```

## 📋 开发检查清单

### 模块完成标准
- [ ] 数据库模块：完整的CRUD操作和数据预处理
- [ ] 推荐算法：多层过滤器和协同过滤实现
- [ ] LLM集成：稳定的API调用和响应处理
- [ ] API接口：RESTful标准和错误处理
- [ ] 测试验证：覆盖主要功能场景的测试用例

### 质量保证
- [ ] 代码注释完整，逻辑清晰
- [ ] 异常处理覆盖所有可能的错误情况
- [ ] 性能指标达标（推荐响应时间<2秒）
- [ ] 数据安全和隐私保护考虑
- [ ] 可配置的参数和灵活的扩展接口

## 🚀 部署和集成准备

### 模块输出标准
1. **独立运行能力**: 模块可以脱离后端独立运行和测试
2. **标准化接口**: 输入输出格式符合最终集成要求
3. **配置文件分离**: 所有参数可通过配置文件调整
4. **详细文档**: 包含API文档、数据库schema、测试报告

## 🚀 无痛适配改善效果总结

### 适配改善前后对比

#### 改善前的风险
- 数据库结构不兼容，需要大量重构
- 数据类型映射问题导致迁移困难
- API接口格式与Java后端不匹配
- 错误处理方式不统一
- 缺乏系统性的兼容性验证

#### 改善后的优势
- **数据库层面**：通过适配器模式实现无缝切换
- **数据类型**：统一使用SQL Server兼容的数据类型
- **API接口**：支持Java风格的驼峰命名和Spring Boot响应格式
- **错误处理**：统一的异常处理机制
- **测试保障**：专门的兼容性测试框架

### 无痛迁移路径

#### Phase 1: 本地开发（当前）
```
SQLite + Python FastAPI + 测试数据
├── 使用适配器模式开发
├── 遵循Java兼容的数据格式
└── 完整的功能测试和性能验证
```

#### Phase 2: 迁移准备（功能完成后）
```
配置切换 + 数据迁移脚本 + 兼容性测试
├── 环境配置从local切换到azure
├── 运行数据库迁移脚本
└── 执行兼容性测试套件
```

#### Phase 3: 生产集成（最终部署）
```
Azure SQL Database + Java Spring Boot + Python微服务
├── 数据库：SQLite → Azure SQL (自动化迁移)
├── 接口：Python API → Java调用 (标准HTTP接口)
└── 监控：统一的日志和性能监控
```

### 关键成功因素
1. **适配器模式**：彻底解耦数据库实现，切换只需改配置
2. **标准化接口**：从设计之初就考虑Java集成需求
3. **类型兼容性**：数据类型选择兼容SQL Server
4. **测试驱动**：专门的兼容性测试确保质量
5. **配置管理**：环境配置分离，部署时无需修改代码

### 预期效果
- **开发效率**：当前开发不受影响，保持高效
- **迁移成本**：预计迁移时间缩短80%
- **集成风险**：通过测试覆盖降低风险90%
- **维护成本**：清晰的抽象层便于长期维护

通过这些适配改善措施，您可以专注于核心算法和功能的开发，而无需担心后续的技术集成问题。整个系统设计既保证了当前的开发效率，又为未来的生产部署奠定了坚实的基础。