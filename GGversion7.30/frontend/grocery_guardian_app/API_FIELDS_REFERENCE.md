# 📋 API字段参考文档

## 用户认证相关字段

### 登录请求 (POST /user/login)
```json
{
  "userName": "string",      // 必填 - 用户名
  "passwordHash": "string"   // 必填 - 密码（前端发送明文）
}
```

### 登录响应 (成功)
```json
{
  "success": true,
  "timestamp": "2025-06-30T21:46:21.734926+01:00",
  "data": {
    "userId": 13,                           // 用户ID
    "userName": "string",                   // 用户名
    "email": "string",                      // 邮箱
    "passwordHash": "string",               // 密码哈希
    "age": 20,                             // 年龄
    "gender": "MALE",                      // 性别: MALE/FEMALE/OTHER
    "heightCm": 175,                       // 身高(厘米)
    "weightKg": 70.0,                      // 体重(公斤)
    "activityLevel": "MODERATELY_ACTIVE",  // 活动水平
    "nutritionGoal": "gain_muscle",        // 营养目标
    "dailyCaloriesTarget": null,           // 每日卡路里目标
    "dailyProteinTarget": null,            // 每日蛋白质目标
    "dailyCarbTarget": null,               // 每日碳水目标
    "dailyFatTarget": null,                // 每日脂肪目标
    "createdTime": "2025-06-30 21:32:17"  // 创建时间
  }
}
```

### 注册请求 (POST /user/register)
```json
{
  "userName": "string",                   // 必填 - 用户名
  "email": "string",                      // 必填 - 邮箱
  "passwordHash": "string",               // 必填 - 密码
  "age": 20,                             // 年龄
  "gender": "MALE",                      // 性别
  "heightCm": 175,                       // 身高
  "weightKg": 70.0,                      // 体重
  "activityLevel": "MODERATELY_ACTIVE",  // 活动水平
  "nutritionGoal": "gain_muscle"         // 营养目标
}
```

### 活动水平选项
```
SEDENTARY          - 久坐
LIGHTLY_ACTIVE     - 轻度活动
MODERATELY_ACTIVE  - 中度活动
VERY_ACTIVE        - 高度活动
```

### 营养目标选项
```
lose_weight  - 减重
maintain     - 维持
gain_muscle  - 增肌
```

## 产品相关字段

### 产品信息响应 (GET /product/{barcode})
```json
{
  "success": true,
  "data": {
    "barCode": "string",              // 条码
    "productName": "string",          // 产品名称
    "brand": "string",                // 品牌
    "category": "string",             // 分类
    "ingredients": [                  // 成分列表
      "ingredient1",
      "ingredient2"
    ],
    "allergens": [                    // 过敏原列表
      "allergen1",
      "allergen2"
    ],
    "nutritionalInfo": {              // 营养信息
      "calories": 250,                // 卡路里
      "protein": 15.0,                // 蛋白质(g)
      "carbs": 30.0,                  // 碳水化合物(g)
      "fat": 10.0,                    // 脂肪(g)
      "sugar": 5.0,                   // 糖分(g)
      "sodium": 400.0,                // 钠(mg)
      "fiber": 3.0                    // 纤维(g)
    },
    "imageUrl": "string"              // 产品图片URL
  }
}
```

## 过敏原相关字段

### 过敏原列表响应 (GET /allergen/list)
```json
{
  "success": true,
  "data": [
    {
      "allergenId": 1,                // 过敏原ID
      "name": "Milk",                 // 过敏原名称
      "category": "Dairy",            // 分类
      "isCommon": true,               // 是否常见
      "description": "Milk and dairy products"  // 描述
    }
  ]
}
```

### 用户过敏原响应 (GET /user/{userId}/allergens)
```json
{
  "success": true,
  "data": [
    {
      "userAllergenId": 1,            // 用户过敏原ID
      "userId": 13,                   // 用户ID
      "allergenId": 1,                // 过敏原ID
      "allergenName": "Milk",         // 过敏原名称
      "severityLevel": "moderate",    // 严重程度
      "notes": "Causes stomach upset", // 备注
      "confirmed": true               // 是否确认
    }
  ]
}
```

### 添加过敏原请求 (POST /user/{userId}/allergens)
```json
{
  "userId": 13,                      // 用户ID
  "allergenId": 1,                   // 过敏原ID
  "severityLevel": "moderate",       // 严重程度: mild/moderate/severe
  "notes": "string"                  // 备注（可选）
}
```

### 严重程度选项
```
mild     - 轻微
moderate - 中度
severe   - 严重
```

## OCR服务字段

### OCR扫描请求 (POST /ocr/scan)
**Content-Type**: multipart/form-data
```
file: (image file)        // 必填 - 图片文件
userId: "13"              // 用户ID (字符串)
priority: "high"          // 可选 - 优先级
```

### OCR扫描响应
```json
{
  "success": true,
  "data": {
    "products": [                    // 识别的产品列表
      {
        "name": "Product Name",      // 产品名称
        "quantity": 1                // 数量
      }
    ]
  }
}
```

## 推荐系统字段

### 条码推荐请求 (POST /recommendations/barcode)
```json
{
  "userId": 13,                      // 用户ID
  "barcode": "string",               // 条码
  "userAllergens": [1, 2, 3],        // 用户过敏原ID列表
  "quickMode": true                  // 快速模式
}
```

### 推荐响应
```json
{
  "success": true,
  "data": {
    "recommendations": [             // 推荐列表
      "recommendation1",
      "recommendation2"
    ],
    "warnings": ["warning1"],        // 警告信息
    "healthScore": 7.5,              // 健康评分
    "summary": "Product analysis summary"  // 分析摘要
  }
}
```

### 小票推荐请求 (POST /recommendations/receipt)
```json
{
  "userId": 13,                      // 用户ID
  "purchasedItems": [                // 购买商品列表
    {
      "name": "Product Name",        // 产品名称
      "quantity": 1,                 // 数量
      "barcode": "string"            // 条码（可选）
    }
  ],
  "quickMode": true                  // 快速模式
}
```

## 错误响应格式

### 标准错误响应
```json
{
  "success": false,
  "timestamp": "2025-06-30T21:46:21.734926+01:00",
  "error": "Error Type",             // 错误类型
  "message": "详细错误信息",          // 错误描述
  "path": "/api/endpoint"            // 请求路径
}
```

### 常见错误类型
```
ValidationError    - 请求参数验证失败
AuthenticationError - 认证失败
AuthorizationError - 权限不足
NotFoundError      - 资源未找到
ServerError        - 服务器内部错误
ServiceUnavailable - 服务不可用
```

## HTTP状态码说明

### 成功状态码
```
200 OK          - 请求成功
201 Created     - 资源创建成功
204 No Content  - 操作成功，无返回内容
```

### 客户端错误
```
400 Bad Request          - 请求参数错误
401 Unauthorized         - 未认证
403 Forbidden           - 权限不足
404 Not Found           - 资源未找到
405 Method Not Allowed  - 方法不允许
413 Payload Too Large   - 请求体过大
```

### 服务器错误
```
500 Internal Server Error - 服务器内部错误
503 Service Unavailable   - 服务不可用
504 Gateway Timeout       - 网关超时
```

## 前端处理说明

### 日期时间格式
- 前端发送: ISO 8601格式 (`2025-06-30T21:46:21.734926+01:00`)
- 后端响应: 可接受多种格式，前端会自动解析

### 数字精度
- 体重: 保留1位小数
- 营养信息: 保留1位小数
- 健康评分: 保留1位小数

### 字符串长度限制
```
用户名: 3-50字符
密码: 6-100字符
邮箱: 符合邮箱格式
备注: 最大500字符
```

### 文件上传限制
```
支持格式: JPG, PNG, WEBP
最大大小: 10MB
推荐尺寸: 最大边不超过2048px
```

---
**版本**: v7.30 | **最后更新**: 2025-06-30 