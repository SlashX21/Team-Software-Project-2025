# 推荐系统API流程文档

## 系统架构概览

```
前端 Flutter App → Java Spring Boot Controller → Java Service Layer → Python FastAPI → 推荐引擎
```

## 1. 系统层级结构

### 1.1 技术栈
- **前端**: Flutter App
- **Java后端**: Spring Boot (端口: 8080)
- **Python推荐服务**: FastAPI (端口: 8000/8001)
- **数据库**: SQLite/MySQL/PostgreSQL (支持多种)

### 1.2 服务配置
```properties
# application.properties
recommendation.service.base-url=http://localhost:8001
recommendation.service.api-token=123456
```

## 2. 核心API流程

### 2.1 条码推荐流程 (Barcode Recommendation)

#### 步骤1: 前端请求Java API

**请求端点**: `POST /recommendations/barcode`

**请求格式**:
```json
{
    "userId": 2,
    "productBarcode": "45"
}
```

**Java Controller定义**:
```java
@PostMapping("/barcode")
public ResponseMessage<Map<String, Object>> getBarcodeRecommendation(
    @RequestBody BarcodeRecommendationRequest request
) {
    return recommendationService.getBarcodeRecommendation(
        request.getUserId(), 
        request.getProductBarcode()
    );
}

// 请求数据类
public static class BarcodeRecommendationRequest {
    private Integer userId;
    private String productBarcode;
    // getters and setters...
}
```

#### 步骤2: Java Service调用Python API

**Java Service调用**:
```java
// RecommendationService.java
String url = recommendationServiceBaseUrl + "/recommendations/barcode";

Map<String, Object> requestBody = Map.of(
    "userId", userId,
    "productBarcode", productBarcode
);

HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.APPLICATION_JSON);
headers.set("Authorization", "Bearer " + apiToken);

HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
```

#### 步骤3: Python FastAPI处理

**Python API端点**: `POST /recommendations/barcode`

**Python数据模型**:
```python
# api/models.py
class BarcodeRecommendationRequest(BaseModel):
    user_id: int = Field(..., alias='userId')
    product_barcode: str = Field(..., alias='productBarcode')

class ApiResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None
    error: Optional[dict] = None
    timestamp: str
```

**Python处理逻辑**:
```python
# api/endpoints.py
@router.post("/recommendations/barcode", response_model=ApiResponse)
async def recommend_barcode_alternatives(
    request: BarcodeRecommendationRequest,
    rec_engine: RecommendationEngine = Depends(get_recommendation_service)
) -> ApiResponse:
    # 转换为内部推荐请求格式
    internal_request = InternalRequest(
        user_id=request.user_id,
        product_barcode=request.product_barcode,
        max_recommendations=5
    )
    
    # 执行推荐
    recommendation_response = await rec_engine.recommend_alternatives(internal_request)
```

#### 步骤4: 推荐引擎处理

**核心推荐流程**:
```python
# recommendation/recommender.py
async def recommend_alternatives(self, request: BarcodeRecommendationRequest) -> RecommendationResponse:
    # 1. 加载基础数据
    original_product, user_profile, user_allergens = await self._load_basic_data(
        request.product_barcode, request.user_id
    )
    
    # 2. 获取候选商品
    candidates = self._get_candidate_products(original_product)
    
    # 3. 应用硬过滤器
    filtered_candidates, filter_stats = self._apply_hard_filters_with_stats(
        candidates, user_profile, original_product
    )
    
    # 4. 营养优化和评分
    recommendations = await self._optimize_nutrition(
        filtered_candidates, user_profile, original_product
    )
    
    # 5. LLM分析
    llm_analysis = await self._generate_llm_analysis(
        user_profile, original_product, recommendations, nutrition_comparison
    )
```

#### 步骤5: 响应数据结构

**Python API响应**:
```json
{
    "success": true,
    "message": "Recommendation generated successfully",
    "data": {
        "recommendationId": "rec_20250621_170836_0000",
        "scanType": "barcode_scan",
        "userProfileSummary": {
            "user_id": 2,
            "nutrition_goal": "lose_weight",
            "allergens_count": 2
        },
        "recommendations": [
            {
                "rank": 1,
                "product": {
                    "barCode": "25862775",
                    "productName": "30% Reduced Fat Mature Cheese",
                    "brand": "Tesco",
                    "energyKcal100g": 314,
                    "proteins100g": 27.9,
                    "fat100g": 22.0,
                    "carbohydrates100g": 0.1,
                    "sugars100g": 0.1,
                    "category": "dairy"
                },
                "recommendationScore": 0.579,
                "reasoning": "Higher protein content supports satiety, aiding weight loss effectively."
            }
        ],
        "llmAnalysis": {
            "summary": "建议选择高蛋白、低热量的替代品以支持减重目标...",
            "detailedAnalysis": "详细的营养分析...",
            "actionSuggestions": ["增加蛋白质摄入", "控制总热量"]
        },
        "processingMetadata": {
            "algorithmVersion": "v1.0",
            "processingTimeMs": 18700,
            "llmTokensUsed": 450,
            "confidenceScore": 0.85
        }
    },
    "timestamp": "2025-01-21T10:30:00Z"
}
```

**Java统一响应格式**:
```java
// ResponseMessage格式
{
    "code": 200,
    "message": "推荐获取成功",
    "data": {
        "recommendations": [...],
        "originalProduct": {...},
        "userProfile": {...},
        "processingTime": 18700
    },
    "success": true,
    "timestamp": "2025-01-21T10:30:00Z"
}
```

### 2.2 小票分析流程 (Receipt Analysis)

#### 步骤1: 前端请求

**请求端点**: `POST /recommendations/receipt`

**请求格式**:
```json
{
    "userId": 1,
    "purchasedItems": [
        {
            "productName": "Coca Cola Original 330ml",
            "quantity": 2
        },
        {
            "productName": "Organic Whole Wheat Bread",
            "quantity": 1
        }
    ]
}
```

**Java数据结构**:
```java
public static class ReceiptRecommendationRequest {
    private Integer userId;
    private List<PurchasedItem> purchasedItems;
}

public static class PurchasedItem {
    private String productName;
    private Integer quantity;
}
```

#### 步骤2: Python处理小票分析

**Python数据模型**:
```python
class PurchasedItem(BaseModel):
    barcode: str
    quantity: int

class ReceiptRecommendationRequest(BaseModel):
    user_id: int = Field(..., alias='userId')
    purchased_items: List[PurchasedItem] = Field(..., alias='purchasedItems')
```

#### 步骤3: 小票分析响应

**Python响应格式**:
```json
{
    "success": true,
    "message": "Receipt analysis completed successfully",
    "data": {
        "recommendationId": "rec_receipt_001",
        "scanType": "receipt",
        "userProfileSummary": {
            "userId": 1,
            "nutritionGoal": "maintain"
        },
        "itemAnalyses": [
            {
                "originalItem": {
                    "barcode": "45",
                    "quantity": 2,
                    "productInfo": {
                        "productName": "Original Product",
                        "energyKcal100g": 400,
                        "proteins100g": 15.0
                    }
                },
                "alternatives": [
                    {
                        "rank": 1,
                        "product": {...},
                        "recommendationScore": 0.85,
                        "reasoning": "Lower calorie alternative"
                    }
                ]
            }
        ],
        "overallNutritionAnalysis": {
            "totalCalories": 1200,
            "totalProtein": 45.0,
            "totalFat": 30.0,
            "goalMatchPercentage": 75.5
        },
        "llmInsights": {
            "summary": "整体营养分析摘要",
            "keyFindings": ["发现1", "发现2"],
            "improvementSuggestions": ["建议1", "建议2"]
        }
    }
}
```

## 3. 数据库模型

### 3.1 核心表结构

#### 用户表 (user)
```sql
CREATE TABLE user (
    user_id INTEGER PRIMARY KEY,
    user_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    nutrition_goal TEXT,
    daily_calories_target REAL,
    daily_protein_target REAL,
    activity_level TEXT,
    height_cm INTEGER,
    weight_kg REAL
);
```

#### 商品表 (product)
```sql
CREATE TABLE product (
    bar_code TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    brand TEXT,
    energy_kcal_100g REAL,
    proteins_100g REAL,
    fat_100g REAL,
    carbohydrates_100g REAL,
    sugars_100g REAL,
    category TEXT
);
```

#### 推荐日志表 (recommendation_log)
```sql
CREATE TABLE recommendation_log (
    log_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    request_barcode TEXT,
    request_type TEXT NOT NULL,
    recommended_products LONGTEXT,
    llm_analysis LONGTEXT,
    processing_time_ms INTEGER,
    created_at TIMESTAMP
);
```

### 3.2 Java实体类

```java
@Entity
@Table(name = "recommendation_log")
public class RecommendationLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer logId;
    
    @Column(name="user_id", nullable = false)
    private Integer userId;
    
    @Column(name="request_type", nullable = false)
    private String requestType;
    
    @Column(name="recommended_products", columnDefinition = "LONGTEXT")
    private String recommendedProducts;
    
    @Column(name="processing_time_ms")
    private Integer processingTimeMs;
}
```

## 4. 配置和环境

### 4.1 Python环境配置

**环境变量 (.env)**:
```env
ENVIRONMENT=java_integration
OPENAI_API_KEY=your_openai_api_key_here
DB_TYPE=mysql
JAVA_DB_CONNECTION_STRING=mysql+pymysql://username:password@localhost:3306/grocery_guardian?charset=utf8mb4
API_PORT=8000
API_HOST=0.0.0.0
```

**Python依赖 (requirements.txt)**:
```
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
pymysql==1.1.0
openai==1.3.7
pandas==2.1.3
```

### 4.2 启动命令

**Python服务启动**:
```bash
# 在Rec_LLM_Module目录下
ENVIRONMENT=java_integration uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

**Java服务启动**:
```bash
mvn spring-boot:run
```

## 5. 错误处理和响应码

### 5.1 Java错误响应格式

```java
// 成功响应
{
    "code": 200,
    "message": "成功",
    "data": {...},
    "success": true,
    "timestamp": "2025-01-21T10:30:00Z"
}

// 错误响应
{
    "code": 500,
    "message": "推荐服务调用失败",
    "data": null,
    "success": false,
    "timestamp": "2025-01-21T10:30:00Z"
}
```

### 5.2 Python错误响应格式

```json
{
    "success": false,
    "message": "Failed to generate recommendation",
    "error": {
        "code": "RECOMMENDATION_ERROR",
        "message": "详细错误信息",
        "details": {
            "user_id": 2,
            "barcode": "45"
        }
    },
    "timestamp": "2025-01-21T10:30:00Z"
}
```

## 6. 性能指标

### 6.1 响应时间目标

- **条码推荐**: ~18.7秒（包含LLM分析）
- **小票分析**: ~3.8秒
- **数据库查询**: <100ms
- **LLM调用**: <5秒

### 6.2 监控指标

**Python处理元数据**:
```json
{
    "processingMetadata": {
        "algorithmVersion": "v1.0",
        "processingTimeMs": 18700,
        "llmTokensUsed": 450,
        "confidenceScore": 0.85,
        "totalCandidates": 200,
        "filteredCandidates": 50
    }
}
```

## 7. 健康检查API

### 7.1 Java健康检查

**端点**: `GET /recommendations/health`

**响应**:
```json
{
    "code": 200,
    "message": "推荐服务正常运行",
    "data": {
        "status": "healthy",
        "pythonService": "connected",
        "database": "connected",
        "timestamp": "2025-01-21T10:30:00Z"
    },
    "success": true
}
```

### 7.2 Python健康检查

**端点**: `GET /health`

**响应**:
```json
{
    "success": true,
    "message": "Grocery Guardian API is running",
    "data": {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": "2025-01-21T10:30:00Z"
    }
}
```

## 8. 测试端点

### 8.1 Java测试端点

**端点**: `POST /recommendations/barcode/test`

**响应**: 返回模拟的推荐数据，用于前端调试

## 9. 数据库适配器支持

系统支持多种数据库：

- **SQLite**: 本地开发
- **MySQL**: Java Liquibase集成
- **PostgreSQL**: 生产环境

通过环境变量 `DB_TYPE` 和 `JAVA_DB_CONNECTION_STRING` 配置。

## 10. 安全考虑

- **API认证**: 使用Bearer Token
- **CORS配置**: 支持跨域请求
- **输入验证**: Pydantic模型验证
- **错误隐藏**: 不暴露内部错误详情

## 11. 数据转换流程详解

### 11.1 字段命名转换

系统在不同层级间进行字段命名转换：

| 前端/Java (camelCase) | Python API (camelCase) | Python内部 (snake_case) | 数据库 (snake_case) |
|---------------------|----------------------|------------------------|-------------------|
| `userId` | `userId` | `user_id` | `user_id` |
| `productBarcode` | `productBarcode` | `product_barcode` | `bar_code` |
| `energyKcal100g` | `energyKcal100g` | `energy_kcal_100g` | `energy_kcal_100g` |
| `recommendationScore` | `recommendationScore` | `recommendation_score` | - |

### 11.2 完整数据流转换示例

#### 原始数据库记录
```sql
-- 数据库中的商品记录
SELECT bar_code, product_name, energy_kcal_100g, proteins_100g, fat_100g 
FROM product WHERE bar_code = '25862775';

-- 结果：
-- bar_code: "25862775"
-- product_name: "30% Reduced Fat Mature Cheese"  
-- energy_kcal_100g: 314.0
-- proteins_100g: 27.9
-- fat_100g: 22.0
```

#### Python内部处理格式
```python
# recommendation/recommender.py 中的商品数据
product = {
    "bar_code": "25862775",
    "product_name": "30% Reduced Fat Mature Cheese",
    "brand": "Tesco",
    "energy_kcal_100g": 314.0,
    "proteins_100g": 27.9,
    "fat_100g": 22.0,
    "carbohydrates_100g": 0.1,
    "sugars_100g": 0.1,
    "category": "dairy"
}
```

#### Python API响应格式
```python
# api/endpoints.py 中的转换函数
def _convert_product_to_api_format(product: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "barCode": product.get("bar_code", ""),           # snake_case → camelCase
        "productName": product.get("product_name", ""),   # snake_case → camelCase
        "brand": product.get("brand", ""),
        "energyKcal100g": product.get("energy_kcal_100g"),
        "proteins100g": product.get("proteins_100g"),
        "fat100g": product.get("fat_100g"),
        "carbohydrates100g": product.get("carbohydrates_100g"),
        "sugars100g": product.get("sugars_100g"),
        "category": product.get("category", "")
    }
```

#### Java Service层处理
```java
// RecommendationService.java 中的响应格式化
private Map<String, Object> formatBarcodeRecommendationResponse(Map<String, Object> data) {
    Map<String, Object> result = new HashMap<>();
    
    // 提取推荐列表
    List<Map<String, Object>> recommendations = (List<Map<String, Object>>) data.get("recommendations");
    result.put("recommendations", recommendations);
    
    // 提取用户画像摘要
    Map<String, Object> userProfile = (Map<String, Object>) data.get("userProfileSummary");
    result.put("userProfile", userProfile);
    
    // 提取LLM分析
    Map<String, Object> llmAnalysis = (Map<String, Object>) data.get("llmAnalysis");
    result.put("llmAnalysis", llmAnalysis);
    
    // 提取处理元数据
    Map<String, Object> metadata = (Map<String, Object>) data.get("processingMetadata");
    if (metadata != null) {
        result.put("processingTime", metadata.get("processingTimeMs"));
        result.put("algorithmVersion", metadata.get("algorithmVersion"));
    }
    
    return result;
}
```

#### 最终前端接收格式
```json
{
    "code": 200,
    "message": "推荐获取成功",
    "data": {
        "recommendations": [
            {
                "rank": 1,
                "product": {
                    "barCode": "25862775",
                    "productName": "30% Reduced Fat Mature Cheese",
                    "brand": "Tesco",
                    "energyKcal100g": 314,
                    "proteins100g": 27.9,
                    "fat100g": 22.0,
                    "carbohydrates100g": 0.1,
                    "sugars100g": 0.1,
                    "category": "dairy"
                },
                "recommendationScore": 0.579,
                "reasoning": "Higher protein content supports satiety, aiding weight loss effectively."
            }
        ],
        "userProfile": {
            "user_id": 2,
            "nutrition_goal": "lose_weight",
            "allergens_count": 2
        },
        "llmAnalysis": {
            "summary": "建议选择高蛋白、低热量的替代品以支持减重目标...",
            "actionSuggestions": ["增加蛋白质摄入", "控制总热量"]
        },
        "processingTime": 18700,
        "algorithmVersion": "v1.0"
    },
    "success": true,
    "timestamp": "2025-01-21T10:30:00Z"
}
```

### 11.3 错误传播机制

当任一层级出现错误时，系统按如下方式传播和转换错误：

1. **数据库连接错误** → Python内部异常 → Python API错误响应 → Java Service处理 → 统一错误格式返回前端

2. **LLM调用失败** → 降级为本地分析 → 继续正常流程（fallback机制）

3. **用户不存在** → Python验证失败 → 400错误响应 → Java转换为业务错误 → 前端显示友好提示

### 11.4 缓存和性能优化

- **商品信息缓存**: 30分钟TTL
- **用户偏好缓存**: 1小时TTL  
- **推荐结果缓存**: 15分钟TTL
- **过敏原映射缓存**: 24小时TTL

这样确保了系统的高性能和用户体验。 