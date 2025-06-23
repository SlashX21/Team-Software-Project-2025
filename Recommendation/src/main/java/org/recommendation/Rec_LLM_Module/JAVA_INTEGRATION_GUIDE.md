# Java集成指南

## 概述

本指南详细说明如何将Grocery Guardian Python推荐系统API与Java应用集成，包括数据库配置和REST API调用。

## 🔧 环境配置

### 1. 配置环境变量

复制 `env.example` 为 `.env` 并配置：

```bash
# 基础配置
ENVIRONMENT=java_integration
OPENAI_API_KEY=your_openai_api_key_here

# 数据库配置
DB_TYPE=mysql  # 或 postgresql
JAVA_DB_CONNECTION_STRING=mysql+pymysql://username:password@localhost:3306/grocery_guardian?charset=utf8mb4

# API配置
API_PORT=8000
API_HOST=0.0.0.0
```

### 2. 安装Python依赖

```bash
pip install -r requirements.txt
```

## 📊 数据库集成

### 方案一：使用现有数据库结构

如果您的Liquibase已经创建了兼容的数据库结构，直接配置连接即可：

```bash
# 启动Python API服务
ENVIRONMENT=java_integration uvicorn api.main:app --host 0.0.0.0 --port 8000
```

### 方案二：数据迁移

如果需要将现有SQLite数据迁移到您的数据库：

```bash
# 迁移到MySQL
python database/migrate_to_java_db.py \
  --source data/grocery_guardian.db \
  --target-type mysql \
  --target-url "mysql+pymysql://user:pass@localhost:3306/grocery_guardian"

# 迁移到PostgreSQL  
python database/migrate_to_java_db.py \
  --source data/grocery_guardian.db \
  --target-type postgresql \
  --target-url "postgresql://user:pass@localhost:5432/grocery_guardian"
```

## 🔌 Java Controller集成

### 1. 添加依赖

在您的 `pom.xml` 中添加：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-web</artifactId>
    </dependency>
</dependencies>
```

### 2. 创建数据传输对象

```java
// BarcodeRecommendationRequest.java
public class BarcodeRecommendationRequest {
    private Integer userId;
    private String productBarcode;
    
    // getters and setters
}

// ReceiptRecommendationRequest.java  
public class ReceiptRecommendationRequest {
    private Integer userId;
    private List<PurchasedItem> purchasedItems;
    
    // getters and setters
}

// PurchasedItem.java
public class PurchasedItem {
    private String barcode;
    private Integer quantity;
    
    // getters and setters
}
```

### 3. 创建推荐服务

```java
@Service
public class RecommendationService {
    
    @Value("${python.api.base.url:http://localhost:8000}")
    private String pythonApiBaseUrl;
    
    private final RestTemplate restTemplate;
    
    public RecommendationService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }
    
    public ResponseEntity<Object> getBarcodeRecommendation(BarcodeRecommendationRequest request) {
        String url = pythonApiBaseUrl + "/recommendations/barcode";
        
        Map<String, Object> pythonRequest = Map.of(
            "userId", request.getUserId(),
            "productBarcode", request.getProductBarcode()
        );
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(pythonRequest, headers);
        
        return restTemplate.exchange(url, HttpMethod.POST, entity, Object.class);
    }
    
    public ResponseEntity<Object> getReceiptAnalysis(ReceiptRecommendationRequest request) {
        String url = pythonApiBaseUrl + "/recommendations/receipt";
        
        Map<String, Object> pythonRequest = Map.of(
            "userId", request.getUserId(),
            "purchasedItems", request.getPurchasedItems().stream()
                .map(item -> Map.of(
                    "barcode", item.getBarcode(),
                    "quantity", item.getQuantity()
                ))
                .collect(Collectors.toList())
        );
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(pythonRequest, headers);
        
        return restTemplate.exchange(url, HttpMethod.POST, entity, Object.class);
    }
}
```

### 4. 创建Controller

```java
@RestController
@RequestMapping("/api/recommendations")
@CrossOrigin(origins = "*")
public class RecommendationController {
    
    private final RecommendationService recommendationService;
    
    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }
    
    @PostMapping("/barcode")
    public ResponseEntity<Object> getBarcodeRecommendation(
            @RequestBody BarcodeRecommendationRequest request) {
        try {
            return recommendationService.getBarcodeRecommendation(request);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "success", false,
                    "message", "推荐服务调用失败",
                    "error", e.getMessage()
                ));
        }
    }
    
    @PostMapping("/receipt")
    public ResponseEntity<Object> getReceiptAnalysis(
            @RequestBody ReceiptRecommendationRequest request) {
        try {
            return recommendationService.getReceiptAnalysis(request);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                    "success", false,
                    "message", "小票分析服务调用失败",
                    "error", e.getMessage()
                ));
        }
    }
    
    @GetMapping("/health")
    public ResponseEntity<Object> checkHealth() {
        try {
            String url = pythonApiBaseUrl + "/health";
            return restTemplate.getForEntity(url, Object.class);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of(
                    "success", false,
                    "message", "Python推荐服务不可用",
                    "error", e.getMessage()
                ));
        }
    }
}
```

### 5. 配置RestTemplate

```java
@Configuration
public class RestTemplateConfig {
    
    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();
        
        // 设置超时时间
        HttpComponentsClientHttpRequestFactory factory = new HttpComponentsClientHttpRequestFactory();
        factory.setConnectTimeout(5000);
        factory.setReadTimeout(30000);
        restTemplate.setRequestFactory(factory);
        
        return restTemplate;
    }
}
```

## 🚀 启动服务

### 1. 启动Python API服务

```bash
# 在Rec_LLM_Module目录下
ENVIRONMENT=java_integration uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. 启动Java应用

```bash
# 在您的Java项目目录下
mvn spring-boot:run
```

### 3. 验证集成

```bash
# 测试Python API健康状态
curl http://localhost:8000/health

# 通过Java Controller测试推荐功能
curl -X POST http://localhost:8080/api/recommendations/barcode \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "productBarcode": "45"
  }'
```

## 📋 API响应格式

### 条码推荐响应

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
          "energyKcal100g": 314,
          "proteins100g": 27.9
        },
        "recommendationScore": 0.579,
        "reasoning": "Higher protein content supports satiety, aiding weight loss effectively."
      }
    ],
    "llmAnalysis": {
      "summary": "建议选择高蛋白、低热量的替代品以支持减重目标...",
      "actionSuggestions": ["增加蛋白质摄入", "控制总热量"]
    }
  },
  "timestamp": "2025-01-21T10:30:00Z"
}
```

## 🔍 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查数据库服务是否启动
   - 验证连接字符串格式
   - 确认用户权限

2. **Python API服务无响应**
   - 检查端口是否被占用
   - 验证环境变量配置
   - 查看Python服务日志

3. **Java调用超时**
   - 增加RestTemplate超时时间
   - 检查网络连接
   - 验证Python服务性能

### 日志配置

在 `application.properties` 中添加：

```properties
# Python API配置
python.api.base.url=http://localhost:8000

# 日志配置
logging.level.your.package.name=DEBUG
logging.level.org.springframework.web.client=DEBUG
```

## 📈 性能优化建议

1. **连接池优化**
   - 配置数据库连接池大小
   - 使用连接池监控

2. **缓存策略**
   - 缓存频繁查询的推荐结果
   - 使用Redis或内存缓存

3. **异步处理**
   - 对于耗时的推荐请求使用异步处理
   - 实现请求队列机制

4. **负载均衡**
   - 部署多个Python API实例
   - 使用负载均衡器分发请求

## 🔒 安全考虑

1. **API认证**
   - 实现JWT或API Key认证
   - 限制API访问频率

2. **数据加密**
   - 使用HTTPS传输
   - 敏感数据加密存储

3. **输入验证**
   - 验证请求参数
   - 防止SQL注入攻击 