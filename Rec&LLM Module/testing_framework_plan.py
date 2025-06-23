# 测试文件构建开发档案 - Grocery Guardian

## 🎯 测试目标

构建全面的测试框架，验证推荐算法的准确性、LLM评估的质量、系统的鲁棒性和性能指标，确保demo模块达到生产级质量标准。

## 🏗️ 测试框架架构（Java兼容性重点）

### 测试层次设计
```
grocery_guardian_demo/tests/
├── unit_tests/                    # 单元测试
│   ├── test_database/             # 数据库适配器测试
│   │   ├── test_sqlite_adapter.py
│   │   ├── test_sqlserver_adapter.py
│   │   └── test_adapter_factory.py
│   ├── test_filters/              # 过滤器算法测试
│   ├── test_recommendation/       # 推荐算法测试
│   └── test_llm/                  # LLM集成测试
├── integration_tests/             # 集成测试
│   ├── test_recommendation_flow/  # 完整推荐流程测试
│   ├── test_api_endpoints/        # API接口测试
│   └── test_java_compatibility/   # Java兼容性测试 ⭐
├── compatibility_tests/           # 兼容性专项测试 ⭐
│   ├── test_dto_serialization/    # DTO序列化测试
│   ├── test_api_contracts/        # API契约测试
│   └── test_database_migration/   # 数据库迁移测试
├── performance_tests/             # 性能测试
│   ├── test_response_time/        # 响应时间测试
│   └── test_load_capacity/        # 负载能力测试
├── scenario_tests/                # 场景测试
│   ├── barcode_scenarios/         # 条形码扫描场景
│   └── receipt_scenarios/         # 小票分析场景
├── test_data/                     # 测试数据
│   ├── products/                  # 商品测试数据
│   ├── users/                     # 用户测试数据
│   ├── scenarios/                 # 测试场景配置
│   ├── java_dto_samples/          # Java DTO样本数据 ⭐
│   └── expected_outputs/          # 预期输出基准
└── test_utilities/                # 测试工具
    ├── data_generators.py         # 测试数据生成器
    ├── validators.py              # 结果验证器
    ├── mock_services.py           # 模拟服务
    └── java_compatibility_utils.py # Java兼容性工具 ⭐
```

## 🔗 Java兼容性测试框架（重点）

### 1. 数据库适配器兼容性测试
```python
class DatabaseAdapterCompatibilityTest:
    """数据库适配器兼容性测试"""
    
    def test_sqlite_to_sqlserver_schema_compatibility(self):
        """测试SQLite到SQL Server的schema兼容性"""
        # 验证数据类型映射正确性
        # 测试外键约束一致性
        # 验证索引转换准确性
        
        type_mappings = {
            "NVARCHAR(20)": "barcode字段",
            "NVARCHAR(200)": "name字段", 
            "NVARCHAR(MAX)": "ingredients字段",
            "FLOAT": "营养成分字段",
            "INT IDENTITY(1,1)": "自增主键",
            "BIT": "布尔字段",
            "DATETIME2": "时间戳字段"
        }
        
        for sql_server_type, description in type_mappings.items():
            # 验证每种数据类型的兼容性
            pass
    
    def test_adapter_factory_creation(self):
        """测试适配器工厂的创建逻辑"""
        # 测试SQLite适配器创建
        sqlite_config = {"type": "sqlite", "connection_string": "test.db"}
        sqlite_adapter = DatabaseAdapterFactory.create_adapter("sqlite", sqlite_config)
        assert isinstance(sqlite_adapter, SQLiteAdapter)
        
        # 测试SQL Server适配器创建
        sqlserver_config = {"type": "sqlserver", "connection_string": "test_connection"}
        sqlserver_adapter = DatabaseAdapterFactory.create_adapter("sqlserver", sqlserver_config)
        assert isinstance(sqlserver_adapter, SqlServerAdapter)
    
    def test_query_result_consistency(self):
        """测试不同适配器查询结果的一致性"""
        # 使用相同的测试数据，验证SQLite和SQL Server返回结果一致
        test_barcode = "1234567890123"
        
        sqlite_result = self.sqlite_adapter.get_product_by_barcode(test_barcode)
        sqlserver_result = self.sqlserver_adapter.get_product_by_barcode(test_barcode)
        
        # 验证关键字段一致性
        assert sqlite_result["barcode"] == sqlserver_result["barcode"]
        assert sqlite_result["name"] == sqlserver_result["name"]
        # ... 其他字段验证

class ApiContractTest:
    """API契约测试，确保与Java后端兼容"""
    
    def test_request_dto_compatibility(self):
        """测试请求DTO与Java实体的兼容性"""
        # Java风格的请求数据
        java_style_request = {
            "scanType": "barcode",  # Java驼峰命名
            "userId": 1,
            "productBarcode": "1234567890123",
            "scanContext": {
                "location": "Tesco",
                "timestamp": "2025-06-12T14:30:00Z"  # ISO格式
            }
        }
        
        # 验证Python API能正确解析Java风格请求
        parsed_request = BarcodeRecommendationRequest(**java_style_request)
        assert parsed_request.scan_type == "barcode"
        assert parsed_request.user_id == 1
    
    def test_response_dto_compatibility(self):
        """测试响应DTO与Java实体的兼容性"""
        # 生成推荐响应
        response = self.recommendation_engine.recommend_alternatives(test_request)
        
        # 验证响应格式符合Java期望
        assert "recommendationId" in response.dict(by_alias=True)
        assert "scanType" in response.dict(by_alias=True)
        assert "userProfileSummary" in response.dict(by_alias=True)
        
        # 验证日期格式
        timestamp = response.processing_metadata["timestamp"]
        assert re.match(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}', timestamp)
    
    def test_error_response_spring_boot_compatibility(self):
        """测试错误响应与Spring Boot异常格式兼容"""
        # 模拟错误情况
        invalid_request = {"scanType": "invalid"}
        
        response = self.api_client.post("/recommend", json=invalid_request)
        error_response = response.json()
        
        # 验证Spring Boot标准错误格式
        assert "success" in error_response
        assert "message" in error_response
        assert "error" in error_response
        assert "timestamp" in error_response
        assert error_response["success"] is False

class DataSerializationTest:
    """数据序列化兼容性测试"""
    
    def test_json_serialization_java_compatibility(self):
        """测试JSON序列化与Java Jackson兼容"""
        # 创建测试对象
        product = ProductDTO(
            barcode="1234567890123",
            name="Test Product",
            brand="Test Brand",
            category="Food",
            energyKcalPer100g=250.5
        )
        
        # 序列化为JSON
        json_data = product.json(by_alias=True)
        parsed_data = json.loads(json_data)
        
        # 验证Java期望的字段名
        assert "energyKcalPer100g" in parsed_data  # 驼峰命名
        assert "energy_kcal_100g" not in parsed_data  # 不包含下划线命名
    
    def test_datetime_serialization_compatibility(self):
        """测试日期时间序列化与Java LocalDateTime兼容"""
        from datetime import datetime
        
        test_datetime = datetime.now()
        iso_format = test_datetime.isoformat()
        
        # 验证ISO格式符合Java LocalDateTime解析要求
        assert "T" in iso_format
        assert len(iso_format.split("T")) == 2
    
    def test_null_value_handling(self):
        """测试空值处理与Java Optional兼容"""
        # 创建包含空值的对象
        product = ProductDTO(
            barcode="1234567890123",
            name="Test Product",
            brand=None,  # 空值
            category="Food"
        )
        
        json_data = json.loads(product.json(by_alias=True))
        
### 2. 数据库迁移测试
```python
class DatabaseMigrationTest:
    """数据库迁移兼容性测试"""
    
    def test_schema_migration_accuracy(self):
        """测试schema迁移的准确性"""
        # 比较SQLite和SQL Server的表结构
        sqlite_schema = self.get_sqlite_schema()
        sqlserver_schema = self.get_expected_sqlserver_schema()
        
        # 验证表数量一致
        assert len(sqlite_schema.tables) == len(sqlserver_schema.tables)
        
        # 验证关键表的字段映射
        for table_name in ["PRODUCT", "USER", "ALLERGEN"]:
            sqlite_table = sqlite_schema.tables[table_name]
            sqlserver_table = sqlserver_schema.tables[table_name]
            
            # 验证字段数量
            assert len(sqlite_table.columns) == len(sqlserver_table.columns)
            
            # 验证数据类型映射
            for col_name in sqlite_table.columns:
                sqlite_type = sqlite_table.columns[col_name].type
                sqlserver_type = sqlserver_table.columns[col_name].type
                assert self.is_compatible_type(sqlite_type, sqlserver_type)
    
    def test_data_migration_integrity(self):
        """测试数据迁移的完整性"""
        # 创建测试数据
        test_products = self.create_test_products(count=100)
        test_users = self.create_test_users(count=10)
        
        # 在SQLite中插入数据
        self.sqlite_adapter.bulk_insert_products(test_products)
        self.sqlite_adapter.bulk_insert_users(test_users)
        
        # 模拟迁移过程
        migrated_data = self.simulate_migration()
        
        # 验证数据完整性
        assert len(migrated_data["products"]) == len(test_products)
        assert len(migrated_data["users"]) == len(test_users)
        
        # 验证关键字段的数据一致性
        for original, migrated in zip(test_products, migrated_data["products"]):
            assert original["barcode"] == migrated["barcode"]
            assert original["name"] == migrated["name"]
            # 验证营养数据精度保持
            assert abs(original["energy_kcal_100g"] - migrated["energy_kcal_100g"]) < 0.01
    
    def test_constraint_migration(self):
        """测试约束迁移的正确性"""
        # 验证主键约束
        # 验证外键约束
        # 验证唯一性约束
        # 验证检查约束
        pass

## 📋 核心测试场景设计（保持原有设计）

### 1. 条形码扫描测试场景
```

#### 场景1: 减脂用户扫描高糖饮料
```json
{
  "scenario_id": "barcode_001_weight_loss_sugary_drink",
  "description": "减脂用户扫描高糖可乐，期望推荐无糖替代品",
  "test_data": {
    "user_profile": {
      "user_id": 1,
      "username": "weight_loss_user",
      "nutrition_goal": "lose_weight",
      "daily_calories_target": 1800,
      "allergens": ["caffeine_sensitive"]
    },
    "scanned_product": {
      "barcode": "5449000000996",
      "name": "Coca-Cola Classic",
      "brand": "Coca-Cola",
      "category": "Beverages",
      "energy_kcal_100g": 180,
      "sugars_100g": 39.0,
      "fat_100g": 0.0,
      "proteins_100g": 0.0
    }
  },
  "expected_outcomes": {
    "recommendation_count": 3,
    "sugar_reduction_min": 80,  # 至少减少80%糖分
    "calorie_reduction_min": 70, # 至少减少70%热量
    "allergen_safety": true,
    "category_constraint": "Beverages",
    "llm_analysis_keywords": ["无糖", "减脂", "健康替代", "卡路里控制"]
  }
}
```

#### 场景2: 增肌用户扫描普通面包
```json
{
  "scenario_id": "barcode_002_muscle_gain_bread",
  "description": "增肌用户扫描白面包，期望推荐高蛋白面包",
  "test_data": {
    "user_profile": {
      "user_id": 2,
      "username": "fitness_enthusiast",
      "nutrition_goal": "gain_muscle",
      "daily_protein_target": 150,
      "allergens": ["gluten_free"]
    },
    "scanned_product": {
      "barcode": "7622210951717",
      "name": "White Sliced Bread",
      "brand": "Brennans",
      "category": "Food",
      "energy_kcal_100g": 265,
      "proteins_100g": 8.5,
      "carbohydrates_100g": 49.0,
      "fat_100g": 3.2
    }
  },
  "expected_outcomes": {
    "recommendation_count": 4,
    "protein_increase_min": 50,  # 至少增加50%蛋白质
    "gluten_free": true,
    "category_constraint": "Food",
    "llm_analysis_keywords": ["高蛋白", "增肌", "无麸质", "营养增强"]
  }
}
```

#### 场景3: 过敏用户扫描含过敏原商品
```json
{
  "scenario_id": "barcode_003_allergen_conflict",
  "description": "坚果过敏用户扫描含坚果商品，期望安全替代品",
  "test_data": {
    "user_profile": {
      "user_id": 3,
      "username": "allergen_sensitive_user",
      "nutrition_goal": "maintain",
      "allergens": ["nuts", "almonds", "walnuts"]
    },
    "scanned_product": {
      "barcode": "20045325",
      "name": "Mixed Nuts Snack",
      "brand": "Planters",
      "category": "Snacks",
      "allergens": "Contains: Nuts, Almonds, Walnuts, May contain: Peanuts"
    }
  },
  "expected_outcomes": {
    "recommendation_count": 5,
    "allergen_safety": true,
    "nuts_free": true,
    "category_constraint": "Snacks",
    "llm_analysis_keywords": ["无坚果", "安全替代", "过敏友好", "营养相似"]
  }
}
```

### 2. 小票分析测试场景

#### 场景1: 不健康购物小票分析
```json
{
  "scenario_id": "receipt_001_unhealthy_pattern",
  "description": "分析高糖高脂购物模式，提供健康改进建议",
  "test_data": {
    "user_profile": {
      "user_id": 1,
      "nutrition_goal": "lose_weight",
      "daily_calories_target": 1800
    },
    "purchased_items": [
      {
        "barcode": "5449000000996",
        "item_name": "Coca-Cola Classic 500ml",
        "quantity": 6,
        "unit_price": 1.25,
        "category": "Beverages"
      },
      {
        "barcode": "7622210951717",
        "item_name": "Chocolate Chip Cookies",
        "quantity": 2,
        "unit_price": 3.99,
        "category": "Snacks"
      },
      {
        "barcode": "40822527",
        "item_name": "Frozen Pizza",
        "quantity": 3,
        "unit_price": 4.50,
        "category": "Food"
      }
    ],
    "receipt_context": {
      "store": "Tesco",
      "purchase_date": "2025-06-12",
      "total_amount": 29.47
    }
  },
  "expected_outcomes": {
    "overall_health_score": "需要改进",
    "calorie_excess_warning": true,
    "sugar_content_alert": true,
    "replacement_suggestions_count": 6,
    "llm_analysis_keywords": ["高糖警告", "卡路里超标", "健康替代", "营养平衡"]
  }
}
```

#### 场景2: 均衡购物小票分析
```json
{
  "scenario_id": "receipt_002_balanced_pattern",
  "description": "分析营养均衡的购物模式，提供维持建议",
  "test_data": {
    "user_profile": {
      "user_id": 3,
      "nutrition_goal": "maintain"
    },
    "purchased_items": [
      {
        "barcode": "5391518377133",
        "item_name": "Organic Chicken Breast",
        "quantity": 1,
        "unit_price": 8.99,
        "category": "Food"
      },
      {
        "barcode": "5391520001342",
        "item_name": "Brown Rice",
        "quantity": 1,
        "unit_price": 2.49,
        "category": "Food"
      },
      {
        "barcode": "5391518334527",
        "item_name": "Mixed Vegetables",
        "quantity": 2,
        "unit_price": 1.99,
        "category": "Food"
      }
    ]
  },
  "expected_outcomes": {
    "overall_health_score": "优秀",
    "nutrition_balance_score": ">85%",
    "protein_adequacy": true,
    "vegetable_variety": "充足",
    "llm_analysis_keywords": ["营养均衡", "健康选择", "继续保持", "多样化"]
  }
}
```

## 🧪 测试数据生成策略

### 测试商品数据库构建
```python
class TestProductGenerator:
    def generate_representative_products(self) -> List[dict]:
        """生成代表性商品测试数据"""
        categories = {
            'Food': ['高蛋白食品', '低脂食品', '高纤维食品', '加工食品'],
            'Beverages': ['高糖饮料', '无糖饮料', '功能饮料', '天然果汁'],
            'Snacks': ['健康零食', '高糖零食', '坚果类', '薯片类'],
            'Health & Supplements': ['蛋白粉', '维生素', '有机食品'],
            'Condiments & Others': ['调料', '油类', '香料']
        }
        
        for category, subcategories in categories.items():
            for subcategory in subcategories:
                # 为每个子类别生成5-10个代表性商品
                # 覆盖不同的营养特征和过敏原组合
                pass
    
    def create_edge_case_products(self) -> List[dict]:
        """创建边界情况测试商品"""
        edge_cases = [
            "营养信息缺失商品",
            "极高/极低营养值商品",
            "多种过敏原组合商品",
            "异常价格商品",
            "新品类商品"
        ]
        
    def generate_allergen_test_matrix(self) -> List[dict]:
        """生成过敏原测试矩阵"""
        # 创建包含不同过敏原组合的商品
        # 测试过敏原检测的准确性和覆盖度
```

### 测试用户画像生成
```python
class TestUserGenerator:
    def create_diverse_user_profiles(self) -> List[dict]:
        """创建多样化的测试用户画像"""
        user_templates = [
            {
                "category": "减脂用户",
                "variations": ["轻度超重", "中度肥胖", "产后恢复", "老年减脂"],
                "allergen_combinations": [[], ["lactose"], ["gluten", "nuts"], ["multiple_severe"]]
            },
            {
                "category": "增肌用户", 
                "variations": ["瘦体质增重", "健身爱好者", "专业运动员", "康复期增肌"],
                "allergen_combinations": [[], ["dairy"], ["soy"], ["comprehensive_restrictions"]]
            },
            {
                "category": "维持用户",
                "variations": ["健康成年人", "轻度活动", "办公室工作者", "退休人员"],
                "allergen_combinations": [[], ["environmental"], ["food_additives"], ["age_related"]]
            }
        ]
        
    def generate_purchase_history_patterns(self, user_profile: dict) -> List[dict]:
        """为测试用户生成逼真的购买历史"""
        # 基于用户目标生成符合逻辑的购买模式
        # 包含进步轨迹和偶尔的"作弊"购买
        # 季节性变化和特殊事件影响
```

## 🔍 测试验证框架

### 推荐质量验证器
```python
class RecommendationValidator:
    def validate_allergen_safety(self, recommendations: List[dict], 
                                user_allergens: List[str]) -> bool:
        """验证过敏原安全性 - 100%准确率要求"""
        for rec in recommendations:
            product_allergens = self.extract_product_allergens(rec['barcode'])
            for allergen in user_allergens:
                if allergen in product_allergens:
                    return False
        return True
    
    def validate_nutrition_improvement(self, original: dict, 
                                     recommendations: List[dict], 
                                     user_goal: str) -> dict:
        """验证营养改善度"""
        improvement_metrics = {
            'lose_weight': ['calories_reduction', 'fat_reduction', 'sugar_reduction'],
            'gain_muscle': ['protein_increase', 'calorie_adequacy', 'carb_balance'],
            'maintain': ['nutrition_balance', 'variety_score', 'natural_score']
        }
        
        results = {}
        for metric in improvement_metrics[user_goal]:
            results[metric] = self.calculate_improvement_metric(
                original, recommendations, metric)
        return results
    
    def validate_category_constraints(self, original_category: str, 
                                    recommendations: List[dict],
                                    scan_type: str) -> bool:
        """验证分类约束"""
        if scan_type == 'barcode':
            # 条形码扫描必须同分类
            return all(rec['category'] == original_category for rec in recommendations)
        else:
            # 小票分析可跨分类，但需合理
            return True
```

### LLM质量验证器  
```python
class LLMQualityValidator:
    def validate_analysis_accuracy(self, llm_response: str, 
                                  nutrition_data: dict) -> dict:
        """验证LLM分析的数据准确性"""
        extracted_numbers = self.extract_numbers_from_text(llm_response)
        nutrition_numbers = self.flatten_nutrition_data(nutrition_data)
        
        accuracy_score = self.calculate_number_accuracy(
            extracted_numbers, nutrition_numbers)
        
        return {
            'data_accuracy': accuracy_score,
            'calculation_errors': self.find_calculation_errors(llm_response),
            'factual_consistency': self.check_factual_consistency(llm_response)
        }
    
    def validate_personalization_quality(self, llm_response: str,
                                       user_profile: dict) -> dict:
        """验证个性化程度"""
        personalization_indicators = {
            'age_consideration': self.check_age_references(llm_response, user_profile['age']),
            'goal_alignment': self.check_goal_mentions(llm_response, user_profile['nutrition_goal']),
            'allergen_awareness': self.check_allergen_mentions(llm_response, user_profile['allergens']),
            'activity_consideration': self.check_activity_references(llm_response, user_profile['activity_level'])
        }
        
        return personalization_indicators
    
    def validate_safety_and_ethics(self, llm_response: str) -> dict:
        """验证安全性和伦理考虑"""
        safety_checks = {
            'medical_disclaimers': self.check_medical_disclaimers(llm_response),
            'absolute_claims_avoided': self.check_absolute_medical_claims(llm_response),
            'balanced_language': self.check_balanced_language(llm_response),
            'no_harmful_advice': self.check_harmful_advice(llm_response)
        }
        
        return safety_checks
```

## ⚡ 性能测试框架

### 响应时间测试
```python
class PerformanceTestSuite:
    def test_recommendation_response_time(self):
        """测试推荐响应时间"""
        test_cases = [
            {"complexity": "simple", "target_time": 1.0},  # 简单推荐<1秒
            {"complexity": "medium", "target_time": 1.5},  # 中等复杂度<1.5秒
            {"complexity": "complex", "target_time": 2.0}  # 复杂分析<2秒
        ]
        
        for case in test_cases:
            start_time = time.time()
            result = self.execute_recommendation_request(case)
            end_time = time.time()
            
            response_time = end_time - start_time
            assert response_time < case["target_time"], \
                f"Response time {response_time:.2f}s exceeds target {case['target_time']}s"
    
    def test_database_query_performance(self):
        """测试数据库查询性能"""
        query_benchmarks = {
            'single_product_lookup': 0.05,     # 50ms
            'category_filter': 0.1,            # 100ms
            'allergen_check': 0.03,            # 30ms
            'user_profile_load': 0.02,         # 20ms
            'purchase_history': 0.15           # 150ms
        }
        
        for query_type, target_time in query_benchmarks.items():
            actual_time = self.benchmark_query(query_type)
            assert actual_time < target_time, \
                f"Query {query_type} took {actual_time:.3f}s, target: {target_time:.3f}s"
    
    def test_llm_api_performance(self):
        """测试LLM API调用性能"""
        # 测试不同prompt长度下的响应时间
        # 测试并发调用处理能力
        # 测试错误恢复时间
```

### 负载测试
```python
class LoadTestSuite:
    def test_concurrent_recommendations(self):
        """测试并发推荐处理能力"""
        concurrent_users = [5, 10, 15, 20]
        
        for user_count in concurrent_users:
            with ThreadPoolExecutor(max_workers=user_count) as executor:
                futures = []
                for i in range(user_count):
                    future = executor.submit(self.simulate_user_session)
                    futures.append(future)
                
                success_count = 0
                total_time = 0
                
                for future in as_completed(futures):
                    try:
                        session_time = future.result()
                        success_count += 1
                        total_time += session_time
                    except Exception as e:
                        logger.error(f"Session failed: {e}")
                
                success_rate = success_count / user_count
                avg_response_time = total_time / success_count if success_count > 0 else float('inf')
                
                assert success_rate >= 0.95, f"Success rate {success_rate:.2%} below 95%"
                assert avg_response_time < 3.0, f"Average response time {avg_response_time:.2f}s too high"
```

## 📊 测试报告生成

### 自动化测试报告
```python
class TestReportGenerator:
    def generate_comprehensive_report(self, test_results: dict) -> str:
        """生成详细的测试报告"""
        report_sections = {
            'executive_summary': self.create_executive_summary(test_results),
            'recommendation_quality': self.analyze_recommendation_quality(test_results),
            'llm_performance': self.analyze_llm_performance(test_results),
            'system_performance': self.analyze_system_performance(test_results),
            'edge_case_handling': self.analyze_edge_cases(test_results),
            'recommendations': self.generate_improvement_recommendations(test_results)
        }
        
        return self.format_html_report(report_sections)
    
    def create_quality_dashboard(self, test_results: dict) -> dict:
        """创建质量指标仪表板"""
        dashboard_metrics = {
            'overall_score': self.calculate_overall_quality_score(test_results),
            'allergen_safety_rate': test_results['allergen_safety']['success_rate'],
            'nutrition_improvement_rate': test_results['nutrition']['improvement_rate'],
            'response_time_p95': test_results['performance']['response_time_p95'],
            'llm_quality_score': test_results['llm']['quality_score'],
            'edge_case_success_rate': test_results['edge_cases']['success_rate']
        }
        
        return dashboard_metrics
```

## 🎯 测试成功标准

### 功能测试标准
- **过敏原安全性**: 100%准确率，零容忍
- **营养改善率**: >80%的推荐商品营养指标优于原商品
- **分类约束遵守**: 条形码扫描100%同分类，小票分析合理性>90%
- **推荐多样性**: 品牌覆盖度>70%，价格范围合理

### 性能测试标准
- **响应时间**: 95%的请求<2秒，99%的请求<3秒
- **数据库查询**: 单次查询<100ms，复杂查询<200ms
- **并发处理**: 支持20个并发用户，成功率>95%
- **LLM调用**: API成功率>99%，平均响应时间<5秒

### LLM质量标准
- **数据准确性**: 营养数据引用准确率>95%
- **个性化程度**: 用户特征提及率>80%
- **安全合规**: 100%包含适当的医疗免责声明
- **可操作性**: 具体建议比例>70%

## 📋 实施步骤清单

### Phase 1: 测试框架搭建
- [ ] 创建测试项目结构和配置
- [ ] 实现测试数据生成器
- [ ] 开发模拟服务和工具类
- [ ] 建立CI/CD测试流水线

### Phase 2: 单元和集成测试
- [ ] 编写数据库操作单元测试
- [ ] 实现推荐算法组件测试
- [ ] 开发LLM集成测试套件
- [ ] 创建API端点集成测试

### Phase 3: 场景和功能测试
- [ ] 实现条形码扫描场景测试
- [ ] 开发小票分析场景测试
- [ ] 创建边界情况和异常测试
- [ ] 构建用户体验测试套件

### Phase 4: 性能和负载测试
- [ ] 实现响应时间基准测试
- [ ] 开发数据库查询性能测试
- [ ] 创建并发负载测试套件
- [ ] 建立性能监控和告警

### Phase 5: 质量验证和报告
- [ ] 实现推荐质量验证器
- [ ] 开发LLM输出质量检查
- [ ] 创建自动化测试报告生成
- [ ] 建立持续质量监控系统

### Phase 6: 测试优化和维护
- [ ] 优化测试执行效率
- [ ] 扩展测试覆盖范围
- [ ] 建立测试数据管理
- [ ] 创建测试文档和培训材料

## 🔧 Java兼容性测试工具

### Java兼容性验证工具类
```python
class JavaCompatibilityUtils:
    """Java兼容性测试工具类"""
    
    @staticmethod
    def validate_camel_case_conversion(python_dict: Dict, expected_java_fields: List[str]) -> bool:
        """验证Python字典到Java驼峰命名的转换"""
        converted = JavaCompatibilityUtils.to_camel_case_dict(python_dict)
        return all(field in converted for field in expected_java_fields)
    
    @staticmethod
    def to_camel_case_dict(snake_dict: Dict) -> Dict:
        """将下划线命名转换为驼峰命名"""
        camel_dict = {}
        for snake_key, value in snake_dict.items():
            camel_key = JavaCompatibilityUtils.snake_to_camel(snake_key)
            camel_dict[camel_key] = value
        return camel_dict
    
    @staticmethod
    def snake_to_camel(snake_str: str) -> str:
        """下划线转驼峰"""
        components = snake_str.split('_')
        return components[0] + ''.join(x.capitalize() for x in components[1:])
    
    @staticmethod
    def validate_spring_boot_error_format(error_response: Dict) -> bool:
        """验证错误响应格式符合Spring Boot标准"""
        required_fields = ["success", "message", "error", "timestamp"]
        return all(field in error_response for field in required_fields)
    
    @staticmethod
    def validate_iso_datetime_format(datetime_str: str) -> bool:
        """验证日期时间格式符合ISO标准"""
        try:
            from datetime import datetime
            datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
            return True
        except ValueError:
            return False
    
    @staticmethod
    def create_java_compatible_test_data() -> Dict:
        """创建Java兼容的测试数据"""
        return {
            "productData": {
                "barcode": "1234567890123",
                "name": "Test Product",
                "brand": "Test Brand",
                "category": "Food",
                "energyKcalPer100g": 250.5,
                "proteinsPer100g": 15.2,
                "fatPer100g": 8.1,
                "carbohydratesPer100g": 30.5
            },
            "userData": {
                "userId": 1,
                "username": "testUser",
                "email": "test@example.com",
                "age": 25,
                "gender": "male",
                "heightCm": 175,
                "weightKg": 70.5,
                "nutritionGoal": "lose_weight",
                "activityLevel": "moderate"
            },
            "requestData": {
                "scanType": "barcode",
                "userId": 1,
                "productBarcode": "1234567890123",
                "scanContext": {
                    "location": "Tesco",
                    "timestamp": "2025-06-12T14:30:00Z"
                }
            }
        }

class ApiContractValidator:
    """API契约验证器"""
    
    def __init__(self):
        self.java_field_mappings = {
            # Python字段名 -> Java字段名
            "user_id": "userId",
            "product_barcode": "productBarcode", 
            "scan_type": "scanType",
            "energy_kcal_100g": "energyKcalPer100g",
            "proteins_100g": "proteinsPer100g",
            "recommendation_id": "recommendationId",
            "created_at": "createdAt",
            "updated_at": "updatedAt"
        }
    
    def validate_request_contract(self, request_data: Dict, expected_schema: Dict) -> Dict:
        """验证请求契约"""
        validation_result = {
            "valid": True,
            "errors": [],
            "warnings": []
        }
        
        # 检查必需字段
        for required_field in expected_schema.get("required", []):
            if required_field not in request_data:
                validation_result["errors"].append(f"Missing required field: {required_field}")
                validation_result["valid"] = False
        
        # 检查字段类型
        for field_name, field_value in request_data.items():
            expected_type = expected_schema.get("properties", {}).get(field_name, {}).get("type")
            if expected_type and not self._validate_type(field_value, expected_type):
                validation_result["errors"].append(f"Field {field_name} has invalid type")
                validation_result["valid"] = False
        
        return validation_result
    
    def validate_response_contract(self, response_data: Dict, expected_schema: Dict) -> Dict:
        """验证响应契约"""
        validation_result = {
            "valid": True,
            "errors": [],
            "java_compatibility_score": 0.0
        }
        
        # 检查Java兼容性
        java_compatible_fields = 0
        total_fields = len(response_data)
        
        for python_field, java_field in self.java_field_mappings.items():
            if python_field in str(response_data).lower():
                # 检查是否使用了Java风格的字段名
                if java_field in response_data:
                    java_compatible_fields += 1
                else:
                    validation_result["warnings"].append(f"Field {python_field} should use Java naming: {java_field}")
        
        if total_fields > 0:
            validation_result["java_compatibility_score"] = java_compatible_fields / total_fields
        
        return validation_result
    
    def _validate_type(self, value, expected_type: str) -> bool:
        """验证数据类型"""
        type_validators = {
            "string": lambda x: isinstance(x, str),
            "integer": lambda x: isinstance(x, int),
            "number": lambda x: isinstance(x, (int, float)),
            "boolean": lambda x: isinstance(x, bool),
            "array": lambda x: isinstance(x, list),
            "object": lambda x: isinstance(x, dict)
        }
        
        validator = type_validators.get(expected_type.lower())
## 🔧 测试工具和依赖（Java兼容性增强）

### 核心测试库
```python
# requirements_test.txt
pytest>=7.0.0              # 测试框架
pytest-asyncio>=0.21.0     # 异步测试支持
pytest-mock>=3.10.0        # Mock对象
pytest-cov>=4.0.0          # 代码覆盖率
pytest-xdist>=3.2.0        # 并行测试执行
pytest-html>=3.1.0         # HTML测试报告

# Java兼容性测试专用
pydantic>=1.10.0           # 数据验证和序列化
jsonschema>=4.17.0         # JSON schema验证
requests>=2.28.0           # HTTP客户端测试
responses>=0.22.0          # HTTP响应Mock

# 数据库测试
sqlalchemy>=1.4.0          # 数据库ORM
pyodbc>=4.0.0              # SQL Server驱动（预留）
pytest-postgresql>=4.1.0   # PostgreSQL测试支持（备选）

# 性能测试
locust>=2.14.0              # 负载测试
memory-profiler>=0.60.0     # 内存性能分析
line-profiler>=4.0.0        # 代码性能分析

# 数据生成和验证
faker>=18.4.0               # 测试数据生成
hypothesis>=6.70.0          # 属性测试
factory-boy>=3.2.0          # 测试对象工厂
```

### Java兼容性测试配置
```python
# test_config_java_compatibility.py
JAVA_COMPATIBILITY_CONFIG = {
    "field_naming": {
        "style": "camelCase",
        "validation": True,
        "mapping_file": "tests/test_data/java_field_mappings.json"
    },
    "date_time": {
        "format": "ISO_8601",
        "timezone_handling": "UTC",
        "precision": "milliseconds"
    },
    "api_contracts": {
        "request_validation": True,
        "response_validation": True,
        "schema_directory": "tests/test_data/api_schemas/",
        "java_dto_samples": "tests/test_data/java_dto_samples/"
    },
    "database": {
        "test_migration": True,
        "constraint_validation": True,
        "data_type_mapping": True,
        "performance_comparison": True
    },
    "error_handling": {
        "spring_boot_format": True,
        "status_code_mapping": True,
        "exception_structure": True
    }
}
```
```

### 测试环境配置
```python
# test_config.py
TEST_CONFIG = {
    "database": {
        "path": "tests/test_data/test_grocery_guardian.db",
        "reset_on_start": True,
        "populate_test_data": True
    },
    "llm": {
        "use_mock": True,           # 使用Mock LLM避免API费用
        "mock_response_delay": 0.5, # 模拟API延迟
        "enable_real_api_tests": False  # 仅在必要时启用真实API测试
    },
    "performance": {
        "response_time_targets": {
            "simple_recommendation": 1.0,
            "complex_analysis": 2.0,
            "receipt_processing": 3.0
        },
        "load_test_users": 20,
        "load_test_duration": 60  # 秒
    }
}
```

这个全面的测试框架将确保Grocery Guardian推荐系统的质量、性能和可靠性，为后续的生产部署奠定坚实的基础。