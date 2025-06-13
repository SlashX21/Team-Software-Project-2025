# 数据库搭建开发档案 - Grocery Guardian

## 🎯 模块目标

构建完整的SQLite数据库系统，包含商品数据、用户画像、购买历史、过敏原管理等核心表结构，并实现高效的数据预处理和查询接口。

## 🗄️ 数据库设计

### 核心表结构设计

#### 1. PRODUCT 商品主表（SQL Server兼容设计）
```sql
CREATE TABLE PRODUCT (
    barcode NVARCHAR(20) PRIMARY KEY,
    name NVARCHAR(200) NOT NULL,
    brand NVARCHAR(100),
    ingredients NVARCHAR(MAX),
    allergens NVARCHAR(MAX),
    energy_100g FLOAT,
    energy_kcal_100g FLOAT,
    fat_100g FLOAT,
    saturated_fat_100g FLOAT,
    carbohydrates_100g FLOAT,
    sugars_100g FLOAT,
    proteins_100g FLOAT,
    serving_size NVARCHAR(50),
    category NVARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
```

#### 2. USER 用户表（枚举改为字符串）
```sql
CREATE TABLE USER (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(50) UNIQUE NOT NULL,
    email NVARCHAR(100) UNIQUE NOT NULL,
    age INT,
    gender NVARCHAR(10), -- 'male', 'female', 'other'
    height_cm INT,
    weight_kg FLOAT,
    activity_level NVARCHAR(20), -- 'sedentary', 'light', 'moderate', 'active', 'very_active'
    nutrition_goal NVARCHAR(20), -- 'lose_weight', 'gain_muscle', 'maintain', 'general_health'
    daily_calories_target FLOAT,
    daily_protein_target FLOAT,
    daily_carb_target FLOAT,
    daily_fat_target FLOAT,
    created_at DATETIME2 DEFAULT GETDATE()
);
```

#### 3. ALLERGEN 过敏原字典表
```sql
CREATE TABLE ALLERGEN (
    allergen_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE NOT NULL,
    category NVARCHAR(50),
    is_common BIT DEFAULT 0,
    description NVARCHAR(MAX)
);
```

#### 4. USER_ALLERGEN 用户过敏原关联表
```sql
CREATE TABLE USER_ALLERGEN (
    user_allergen_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    allergen_id INT,
    severity_level NVARCHAR(10), -- 'mild', 'moderate', 'severe'
    confirmed BIT DEFAULT 1,
    notes NVARCHAR(MAX),
    FOREIGN KEY (user_id) REFERENCES [USER](user_id),
    FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id)
);
```

#### 5. PRODUCT_ALLERGEN 商品过敏原关联表
```sql
CREATE TABLE PRODUCT_ALLERGEN (
    product_allergen_id INT IDENTITY(1,1) PRIMARY KEY,
    barcode NVARCHAR(20),
    allergen_id INT,
    presence_type NVARCHAR(12), -- 'contains', 'may_contain', 'traces'
    confidence_score FLOAT DEFAULT 1.0,
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode),
    FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id)
);
```

#### 6. PURCHASE_RECORD 购买记录表
```sql
CREATE TABLE PURCHASE_RECORD (
    purchase_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    receipt_date DATE,
    store_name NVARCHAR(100),
    total_amount FLOAT,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES [USER](user_id)
);
```

#### 7. PURCHASE_ITEM 购买商品明细表
```sql
CREATE TABLE PURCHASE_ITEM (
    item_id INT IDENTITY(1,1) PRIMARY KEY,
    purchase_id INT,
    barcode NVARCHAR(20),
    item_name_ocr NVARCHAR(200),
    quantity INT,
    unit_price FLOAT,
    total_price FLOAT,
    estimated_servings FLOAT,
    total_calories FLOAT,
    total_proteins FLOAT,
    total_carbs FLOAT,
    total_fat FLOAT,
    FOREIGN KEY (purchase_id) REFERENCES PURCHASE_RECORD(purchase_id),
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode)
);
```

#### 8. USER_PREFERENCE 用户动态偏好表
```sql
CREATE TABLE USER_PREFERENCE (
    preference_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    prefer_low_sugar BIT DEFAULT 0,
    prefer_low_fat BIT DEFAULT 0,
    prefer_high_protein BIT DEFAULT 0,
    prefer_low_sodium BIT DEFAULT 0,
    prefer_organic BIT DEFAULT 0,
    prefer_low_calorie BIT DEFAULT 0,
    preference_source NVARCHAR(15) DEFAULT 'system_inferred', -- 'user_manual', 'system_inferred', 'mixed'
    inference_confidence FLOAT DEFAULT 0.5,
    version INT DEFAULT 1,
    updated_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES [USER](user_id)
);
```

#### 9. RECOMMENDATION_LOG 推荐日志表
```sql
CREATE TABLE RECOMMENDATION_LOG (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    request_barcode NVARCHAR(20),
    request_type NVARCHAR(20), -- 'barcode_scan', 'receipt_analysis'
    recommended_products NVARCHAR(MAX), -- JSON格式
    algorithm_version NVARCHAR(20),
    llm_prompt NVARCHAR(MAX),
    llm_response NVARCHAR(MAX),
    llm_analysis NVARCHAR(MAX),
    processing_time_ms INT,
    total_candidates INT,
    filtered_candidates INT,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES [USER](user_id)
);
```

### 数据库索引优化策略

```sql
-- 商品查询优化
CREATE INDEX idx_product_category ON PRODUCT(category);
CREATE INDEX idx_product_nutrition ON PRODUCT(energy_kcal_100g, proteins_100g, fat_100g);
CREATE INDEX idx_product_brand ON PRODUCT(brand);

-- 用户查询优化
CREATE INDEX idx_user_nutrition_goal ON USER(nutrition_goal);
CREATE INDEX idx_user_allergen_user ON USER_ALLERGEN(user_id, confirmed);

-- 过敏原查询优化
CREATE INDEX idx_product_allergen_barcode ON PRODUCT_ALLERGEN(barcode);
CREATE INDEX idx_product_allergen_type ON PRODUCT_ALLERGEN(allergen_id, presence_type);

-- 购买历史优化
CREATE INDEX idx_purchase_user_date ON PURCHASE_RECORD(user_id, receipt_date DESC);
CREATE INDEX idx_purchase_item_barcode ON PURCHASE_ITEM(barcode, quantity);

-- 推荐日志优化
CREATE INDEX idx_recommendation_user_time ON RECOMMENDATION_LOG(user_id, created_at DESC);
```

## 📊 数据预处理策略

### 1. 爱尔兰产品数据清洗流程

#### 数据质量检查
```python
class DataQualityChecker:
    def validate_barcode_format(self, barcode: str) -> bool:
        """验证条形码格式（8-13位数字）"""
        
    def validate_nutrition_data(self, nutrition_dict: dict) -> dict:
        """验证营养数据合理性，处理异常值"""
        
    def standardize_category(self, raw_category: str) -> str:
        """标准化商品分类到5大类"""
        # Food, Beverages, Snacks, Health & Supplements, Condiments & Others
        
    def clean_ingredients_text(self, ingredients: str) -> str:
        """清洗成分列表文本，移除无效字符"""
```

#### 过敏原解析策略
```python
class AllergenParser:
    # 常见过敏原关键词映射
    ALLERGEN_KEYWORDS = {
        'milk': ['milk', 'dairy', 'lactose', 'casein', 'whey'],
        'eggs': ['egg', 'albumin', 'lecithin'],
        'nuts': ['nuts', 'almond', 'walnut', 'pecan', 'cashew'],
        'gluten': ['wheat', 'gluten', 'barley', 'rye', 'oats'],
        'soy': ['soy', 'soya', 'soybean'],
        'fish': ['fish', 'salmon', 'tuna', 'cod'],
        'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster'],
        'sesame': ['sesame', 'tahini']
    }
    
    def extract_allergens_from_text(self, allergen_text: str) -> List[dict]:
        """从过敏原文本中提取结构化过敏原信息"""
        
    def determine_presence_type(self, context: str) -> str:
        """判断过敏原存在类型：contains/may_contain/traces"""
```

### 2. 商品分类标准化

#### 分类映射规则
```python
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
```

## 👥 测试用户数据生成

### 用户画像模板
```python
TEST_USERS = [
    {
        "username": "fitness_enthusiast",
        "email": "fit@test.com",
        "age": 28,
        "gender": "male",
        "height_cm": 180,
        "weight_kg": 75.0,
        "activity_level": "active",
        "nutrition_goal": "gain_muscle",
        "allergens": ["milk", "nuts"],
        "daily_calories_target": 2500,
        "daily_protein_target": 150,
        "purchase_pattern": "high_protein_focus"
    },
    {
        "username": "weight_loss_user",
        "email": "health@test.com",
        "age": 35,
        "gender": "female",
        "height_cm": 165,
        "weight_kg": 70.0,
        "activity_level": "moderate",
        "nutrition_goal": "lose_weight",
        "allergens": ["gluten", "soy"],
        "daily_calories_target": 1800,
        "daily_protein_target": 90,
        "purchase_pattern": "low_calorie_focus"
    },
    {
        "username": "maintenance_user",
        "email": "balanced@test.com",
        "age": 42,
        "gender": "male",
        "height_cm": 175,
        "weight_kg": 80.0,
        "activity_level": "light",
        "nutrition_goal": "maintain",
        "allergens": ["shellfish"],
        "daily_calories_target": 2200,
        "daily_protein_target": 110,
        "purchase_pattern": "balanced_variety"
    }
]
```

### 购买历史生成策略
```python
class PurchaseHistoryGenerator:
    def generate_user_purchases(self, user_profile: dict, num_records: int = 40) -> List[dict]:
        """基于用户营养目标生成符合逻辑的购买历史"""
        
    def select_products_by_goal(self, nutrition_goal: str, category: str) -> List[str]:
        """根据营养目标选择相应的商品类型"""
        
    def apply_seasonal_patterns(self, base_purchases: List[dict]) -> List[dict]:
        """应用季节性购买模式"""
        
    def add_noise_and_variety(self, structured_purchases: List[dict]) -> List[dict]:
        """添加随机性和多样性，使数据更真实"""
```

## 🔧 数据库适配器模式设计（无痛迁移）

### 数据库适配器抽象层
```python
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Union
import logging

class DatabaseAdapter(ABC):
    """数据库适配器抽象基类，支持SQLite到SQL Server的无痛迁移"""
    
    def __init__(self, connection_config: Dict):
        self.config = connection_config
        self.logger = logging.getLogger(self.__class__.__name__)
    
    @abstractmethod
    def connect(self) -> bool:
        """建立数据库连接"""
        pass
    
    @abstractmethod
    def execute_query(self, query: str, params: Optional[Dict] = None) -> List[Dict]:
        """执行查询并返回结果"""
        pass
    
    @abstractmethod
    def execute_update(self, query: str, params: Optional[Dict] = None) -> int:
        """执行更新操作并返回受影响行数"""
        pass
    
    # 商品相关操作
    @abstractmethod
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        """根据条形码查询商品信息"""
        pass
    
    @abstractmethod
    def get_products_by_category(self, category: str, limit: int = 100) -> List[Dict]:
        """查询指定分类的商品列表"""
        pass
    
    @abstractmethod
    def search_products_by_nutrition(self, filters: Dict) -> List[Dict]:
        """根据营养条件筛选商品"""
        pass
    
    # 用户相关操作
    @abstractmethod
    def get_user_profile(self, user_id: int) -> Optional[Dict]:
        """获取用户完整画像"""
        pass
    
    @abstractmethod
    def get_user_allergens(self, user_id: int) -> List[Dict]:
        """获取用户过敏原列表"""
        pass
    
    @abstractmethod
    def get_user_preferences(self, user_id: int) -> Optional[Dict]:
        """获取用户动态偏好"""
        pass
    
    # 购买历史操作
    @abstractmethod
    def get_purchase_history(self, user_id: int, days: int = 90) -> List[Dict]:
        """获取用户购买历史记录"""
        pass
    
    @abstractmethod
    def get_user_purchase_matrix(self, user_id: int) -> Dict:
        """获取用户-商品购买矩阵（用于协同过滤）"""
        pass
    
    # 过敏原管理操作
    @abstractmethod
    def check_product_allergens(self, barcode: str, user_allergens: List[int]) -> Dict:
        """检查商品是否包含用户过敏原"""
        pass
    
    @abstractmethod
    def get_allergen_by_name(self, allergen_name: str) -> Optional[Dict]:
        """根据名称查询过敏原信息"""
        pass
    
    # 日志记录操作
    @abstractmethod
    def log_recommendation(self, log_data: Dict) -> bool:
        """记录推荐请求和结果"""
        pass
    
    @abstractmethod
    def get_recommendation_stats(self, user_id: int) -> Dict:
        """获取用户推荐统计信息"""
        pass

class SQLiteAdapter(DatabaseAdapter):
    """SQLite数据库适配器实现"""
    
    def __init__(self, connection_config: Dict):
        super().__init__(connection_config)
        self.connection_string = connection_config["connection_string"]
        self.engine = None
    
    def connect(self) -> bool:
        try:
            from sqlalchemy import create_engine
            self.engine = create_engine(self.connection_string)
            return True
        except Exception as e:
            self.logger.error(f"SQLite connection failed: {e}")
            return False
    
    def execute_query(self, query: str, params: Optional[Dict] = None) -> List[Dict]:
        # SQLite特定的查询实现
        pass
    
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        # SQLite特定的商品查询实现
        query = "SELECT * FROM PRODUCT WHERE barcode = ?"
        # 实现具体逻辑...
        pass

class SqlServerAdapter(DatabaseAdapter):
    """SQL Server数据库适配器实现（预留）"""
    
    def __init__(self, connection_config: Dict):
        super().__init__(connection_config)
        self.connection_string = connection_config["connection_string"]
        self.engine = None
    
    def connect(self) -> bool:
        try:
            from sqlalchemy import create_engine
            self.engine = create_engine(
                self.connection_string,
                pool_size=connection_config.get("pool_size", 10),
                max_overflow=connection_config.get("max_overflow", 20)
            )
            return True
        except Exception as e:
            self.logger.error(f"SQL Server connection failed: {e}")
            return False
    
    def execute_query(self, query: str, params: Optional[Dict] = None) -> List[Dict]:
        # SQL Server特定的查询实现
        pass
    
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        # SQL Server特定的商品查询实现
        query = "SELECT * FROM PRODUCT WHERE barcode = @barcode"
        # 实现具体逻辑...
        pass

class DatabaseAdapterFactory:
    """数据库适配器工厂"""
    
    @staticmethod
    def create_adapter(db_type: str, config: Dict) -> DatabaseAdapter:
        """根据数据库类型创建相应的适配器"""
        if db_type.lower() == "sqlite":
            return SQLiteAdapter(config)
        elif db_type.lower() == "sqlserver":
            return SqlServerAdapter(config)
        else:
            raise ValueError(f"Unsupported database type: {db_type}")
```

### 环境配置管理
```python
class ConfigManager:
    """环境配置管理器"""
    
    def __init__(self, environment: str = "local"):
        self.environment = environment
        self.config = self._load_config()
    
    def _load_config(self) -> Dict:
        """加载环境配置"""
        configs = {
            "local": {
                "database": {
                    "type": "sqlite",
                    "connection_string": "sqlite:///data/grocery_guardian.db",
                    "echo": False
                }
            },
            "azure": {
                "database": {
                    "type": "sqlserver",
                    "connection_string": "mssql+pyodbc://user:pass@server/db?driver=ODBC+Driver+17+for+SQL+Server",
                    "echo": False,
                    "pool_size": 10,
                    "max_overflow": 20
                }
            }
        }
        return configs.get(self.environment, configs["local"])
    
    def get_database_config(self) -> Dict:
        """获取数据库配置"""
        return self.config["database"]
```

### 批量数据操作
```python
class BatchDataProcessor:
    def bulk_insert_products(self, products_df: pd.DataFrame) -> bool:
        """批量导入商品数据"""
        
    def bulk_update_allergen_mapping(self, mappings: List[dict]) -> bool:
        """批量更新商品-过敏原映射"""
        
    def generate_test_purchase_data(self, users: List[dict]) -> bool:
        """为测试用户生成购买历史数据"""
        
    def rebuild_indexes(self) -> bool:
        """重建数据库索引"""
```

## 📋 实施步骤清单

### Phase 1: 数据库结构搭建
- [ ] 创建SQLite数据库文件
- [ ] 执行核心表结构创建SQL
- [ ] 建立外键约束和索引
- [ ] 创建数据验证触发器

### Phase 2: 数据预处理和导入
- [ ] 实现CSV数据质量检查器
- [ ] 开发过敏原文本解析算法
- [ ] 执行商品分类标准化
- [ ] 批量导入处理后的商品数据

### Phase 3: 过敏原数据库构建
- [ ] 从商品数据中提取过敏原词典
- [ ] 建立过敏原标准化映射
- [ ] 创建商品-过敏原关联数据
- [ ] 验证过敏原检测准确性

### Phase 4: 测试用户和历史数据生成
- [ ] 创建3-5个典型测试用户
- [ ] 为每个用户生成30-50条购买记录
- [ ] 分配用户过敏原和偏好设置
- [ ] 验证用户数据的逻辑一致性

### Phase 5: 数据访问接口开发
- [ ] 实现DatabaseManager核心方法
- [ ] 开发批量数据处理工具
- [ ] 添加查询性能监控
- [ ] 创建数据备份和恢复机制

### Phase 6: 数据质量验证
- [ ] 执行数据完整性检查
- [ ] 验证查询性能指标
- [ ] 测试异常情况处理
- [ ] 生成数据质量报告

## 🎯 质量保证标准

### 数据质量指标
- **商品数据完整性**: >95%的商品有完整的营养信息
- **过敏原识别准确率**: >90%的过敏原正确识别和分类
- **用户数据逻辑性**: 100%的测试用户数据符合现实逻辑
- **查询性能**: 单次商品查询<50ms，复杂过滤查询<200ms

### 错误处理标准
- 数据库连接失败的自动重试机制
- 无效输入参数的友好错误提示
- 数据不一致的自动修复或警告
- 完整的操作日志记录

### 扩展性考虑
- 支持商品数据的增量更新
- 用户偏好的版本控制和历史追踪
- 灵活的过敏原映射扩展
- 数据库schema的向前兼容性