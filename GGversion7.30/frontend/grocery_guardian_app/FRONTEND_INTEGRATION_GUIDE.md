# Grocery Guardian 前端集成指南

## 📋 目录
1. [项目概述](#项目概述)
2. [功能清单](#功能清单)
3. [技术架构](#技术架构)
4. [快速部署](#快速部署)
5. [API接口规范](#api接口规范)
6. [数据格式规范](#数据格式规范)
7. [错误处理机制](#错误处理机制)
8. [配置说明](#配置说明)
9. [测试指南](#测试指南)
10. [问题排查](#问题排查)

---

## 📱 项目概述

Grocery Guardian 是一个智能食品安全助手应用，帮助用户管理食品过敏原和营养信息。前端采用 Flutter Web 技术栈，支持条码扫描、小票分析、过敏原管理等功能。

### 版本信息
- **前端版本**: v7.30 - demo/presentation-ready
- **Flutter版本**: 最新稳定版
- **目标平台**: Web (Chrome, Safari, Firefox, Edge)
- **API兼容性**: RESTful API, JSON格式

---

## ✅ 功能清单

### 🎯 已完成功能

#### 1. 用户认证系统
- ✅ 用户登录/注册
- ✅ 用户档案管理
- ✅ 会话管理和缓存
- ✅ 自动登录和记住用户

#### 2. 产品扫描功能
- ✅ 条码扫描
- ✅ 产品信息展示
- ✅ 成分和过敏原识别
- ✅ 智能推荐系统
- ✅ 扫描历史记录

#### 3. 小票分析功能
- ✅ 图片上传
- ✅ OCR文字识别
- ✅ 购买清单生成
- ✅ 营养分析报告

#### 4. 过敏原管理
- ✅ 个人过敏原设置
- ✅ 过敏原检测和警告
- ✅ 严重程度分级
- ✅ 备注和说明

#### 5. 健康档案
- ✅ 个人健康信息
- ✅ 营养目标设置
- ✅ 活动水平记录
- ✅ 档案编辑功能

#### 6. 糖分追踪
- ✅ 每日糖分记录
- ✅ 目标设定
- ✅ 进度追踪
- ✅ 历史数据查看

#### 7. 月度概览
- ✅ 购买历史统计
- ✅ 营养分析报告
- ✅ 健康趋势图表
- ✅ 对比分析

### ⚠️ 需要后端支持的功能

#### 1. OCR服务集成
- 📋 端点: `http://localhost:8000/ocr/scan`
- 📋 健康检查: `http://localhost:8000/health`

#### 2. 过敏原API服务
- 📋 用户过敏原: `http://localhost:8080/user/{userId}/allergens`
- 📋 添加过敏原: `http://localhost:8080/allergen/user/{userId}/add`

#### 3. 推荐系统API
- 📋 产品推荐: `http://localhost:8001/recommendations/barcode`

---

## 🏗️ 技术架构

### 前端技术栈
```yaml
Framework: Flutter Web
Language: Dart
State Management: StatefulWidget + Provider
HTTP Client: http package
Caching: SharedPreferences
Scanner: mobile_scanner
Image Picker: image_picker
Routing: Flutter Navigator 2.0
```

### 项目结构
```
lib/
├── domain/
│   └── entities/           # 数据模型
├── presentation/
│   ├── screens/           # 页面组件
│   ├── widgets/           # 共用组件
│   └── theme/             # 主题配置
├── services/              # 业务逻辑和API
└── main.dart             # 应用入口
```

---

## 🚀 快速部署

### 1. 环境要求
```bash
# 安装 Flutter
flutter --version  # 确保 Flutter SDK 已安装

# 检查 Web 支持
flutter config --enable-web
flutter devices    # 确保看到 Chrome/Edge 设备
```

### 2. 项目配置
```bash
# 克隆仓库
git clone <repository-url>
cd GGversion7.30/frontend/grocery_guardian_app

# 安装依赖
flutter pub get

# 配置API端点 (编辑 lib/services/api_config.dart)
vim lib/services/api_config.dart
```

### 3. API配置文件
编辑 `lib/services/api_config.dart`:
```dart
class ApiConfig {
  // 🔧 修改这些URL为你的后端地址
  static const String springBootBaseUrl = 'http://localhost:8080';  // 主后端
  static const String ocrBaseUrl = 'http://localhost:8000';         // OCR服务
  static const String recommendationBaseUrl = 'http://localhost:8001'; // 推荐服务
  
  // 超时配置
  static const Duration defaultTimeout = Duration(seconds: 8);
  static const Duration ocrTimeout = Duration(seconds: 20);
  static const Duration recommendationTimeout = Duration(seconds: 15);
}
```

### 4. 启动应用
```bash
# 开发模式
flutter run -d chrome

# 生产构建
flutter build web
```

---

## 🔌 API接口规范

### 1. 用户认证相关

#### 用户登录
```http
POST /user/login
Content-Type: application/json

Request Body:
{
  "userName": "string",      // 用户名
  "passwordHash": "string"   // 密码 (注意: 前端发送明文，后端需要处理)
}

Response (200):
{
  "success": true,
  "timestamp": "2025-06-30T21:46:21.734926+01:00",
  "data": {
    "userId": 13,
    "userName": "string",
    "email": "string",
    "passwordHash": "string",
    "age": 20,
    "gender": "MALE",
    "heightCm": 175,
    "weightKg": 70.0,
    "activityLevel": "MODERATELY_ACTIVE",
    "nutritionGoal": "gain_muscle",
    "dailyCaloriesTarget": null,
    "dailyProteinTarget": null,
    "dailyCarbTarget": null,
    "dailyFatTarget": null,
    "createdTime": "2025-06-30 21:32:17"
  }
}
```

#### 用户注册
```http
POST /user/register
Content-Type: application/json

Request Body:
{
  "userName": "string",
  "email": "string",
  "passwordHash": "string",
  "age": 20,
  "gender": "MALE",
  "heightCm": 175,
  "weightKg": 70.0,
  "activityLevel": "MODERATELY_ACTIVE",
  "nutritionGoal": "gain_muscle"
}
```

#### 获取用户档案
```http
GET /user/{userId}
Response (200):
{
  "success": true,
  "data": {
    "userId": 13,
    "userName": "string",
    "email": "string",
    // ... 其他用户信息
  }
}
```

#### 更新用户档案
```http
POST /user
Content-Type: application/json

Request Body:
{
  "userId": 13,
  "userName": "string",
  "email": "string",
  "age": 20,
  "gender": "MALE",
  "heightCm": 175,
  "weightKg": 70.0,
  "activityLevel": "MODERATELY_ACTIVE",
  "nutritionGoal": "gain_muscle"
}
```

### 2. 产品相关API

#### 根据条码获取产品信息
```http
GET /product/{barcode}
Response (200):
{
  "success": true,
  "data": {
    "barCode": "string",
    "productName": "string",
    "brand": "string",
    "category": "string",
    "ingredients": ["ingredient1", "ingredient2"],
    "allergens": ["allergen1", "allergen2"],
    "nutritionalInfo": {
      "calories": 250,
      "protein": 15.0,
      "carbs": 30.0,
      "fat": 10.0,
      "sugar": 5.0,
      "sodium": 400.0,
      "fiber": 3.0
    },
    "imageUrl": "string"
  }
}
```

#### 根据产品名称查询条码
```http
GET /product/name/{productName}
Response (200):
{
  "success": true,
  "data": {
    "barCode": "string",
    "productName": "string"
  }
}
```

### 3. 过敏原管理API

#### 获取所有过敏原列表
```http
GET /allergen/list
Response (200):
{
  "success": true,
  "data": [
    {
      "allergenId": 1,
      "name": "Milk",
      "category": "Dairy",
      "isCommon": true,
      "description": "Milk and dairy products"
    }
  ]
}
```

#### 获取用户过敏原
```http
GET /user/{userId}/allergens
Response (200):
{
  "success": true,
  "data": [
    {
      "userAllergenId": 1,
      "userId": 13,
      "allergenId": 1,
      "allergenName": "Milk",
      "severityLevel": "moderate",
      "notes": "Causes stomach upset",
      "confirmed": true
    }
  ]
}
```

#### 添加用户过敏原
```http
POST /user/{userId}/allergens
Content-Type: application/json

Request Body:
{
  "userId": 13,
  "allergenId": 1,
  "severityLevel": "moderate",  // mild, moderate, severe
  "notes": "string"
}

Response (200/201):
{
  "success": true,
  "data": {
    "userAllergenId": 1,
    "userId": 13,
    "allergenId": 1,
    "severityLevel": "moderate",
    "notes": "string"
  }
}
```

#### 删除用户过敏原
```http
DELETE /user/{userId}/allergens/{allergenId}
Response (200/204):
{
  "success": true
}
```

### 4. OCR服务API

#### 小票图片分析
```http
POST /ocr/scan
Content-Type: multipart/form-data

Request Body:
- file: (image file)
- userId: (string)
- priority: "high" (optional)

Response (200):
{
  "success": true,
  "data": {
    "products": [
      {
        "name": "Product Name",
        "quantity": 1
      }
    ]
  }
}
```

#### OCR服务健康检查
```http
GET /health
Response (200):
{
  "status": "healthy",
  "timestamp": "2025-06-30T21:46:21.734926+01:00"
}
```

### 5. 推荐系统API

#### 根据条码获取推荐
```http
POST /recommendations/barcode
Content-Type: application/json

Request Body:
{
  "userId": 13,
  "barcode": "string",
  "userAllergens": [1, 2, 3],
  "quickMode": true
}

Response (200):
{
  "success": true,
  "data": {
    "recommendations": ["recommendation1", "recommendation2"],
    "warnings": ["warning1"],
    "healthScore": 7.5,
    "summary": "Product analysis summary"
  }
}
```

#### 小票推荐分析
```http
POST /recommendations/receipt
Content-Type: application/json

Request Body:
{
  "userId": 13,
  "purchasedItems": [
    {
      "name": "Product Name",
      "quantity": 1,
      "barcode": "string"
    }
  ],
  "quickMode": true
}
```

---

## 📊 数据格式规范

### 1. 用户数据模型
```dart
class UserProfile {
  final int userId;
  final String userName;
  final String email;
  final String? passwordHash;
  final int? age;
  final String? gender;          // MALE, FEMALE, OTHER
  final int? heightCm;
  final double? weightKg;
  final String? activityLevel;   // SEDENTARY, LIGHTLY_ACTIVE, MODERATELY_ACTIVE, VERY_ACTIVE
  final String? nutritionGoal;   // lose_weight, maintain, gain_muscle
  final int? dailyCaloriesTarget;
  final double? dailyProteinTarget;
  final double? dailyCarbTarget;
  final double? dailyFatTarget;
  final String? createdTime;
}
```

### 2. 产品数据模型
```dart
class Product {
  final String barCode;
  final String productName;
  final String? brand;
  final String? category;
  final List<String> ingredients;
  final List<String> allergens;
  final NutritionalInfo? nutritionalInfo;
  final String? imageUrl;
}

class NutritionalInfo {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final double? sodium;
  final double? fiber;
}
```

### 3. 过敏原数据模型
```dart
class Allergen {
  final int allergenId;
  final String name;
  final String? category;
  final bool isCommon;
  final String? description;
}

class UserAllergen {
  final int userAllergenId;
  final int userId;
  final int allergenId;
  final String allergenName;
  final String severityLevel;    // mild, moderate, severe
  final String? notes;
  final bool confirmed;
}
```

### 4. 产品分析数据模型
```dart
class ProductAnalysis {
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> detectedAllergens;
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;
}
```

---

## ⚠️ 错误处理机制

### 1. HTTP状态码处理
```dart
// 前端会处理以下状态码
200: 成功
201: 创建成功
204: 删除成功(无内容)
400: 请求参数错误
401: 未授权
403: 权限不足
404: 资源未找到
405: 方法不允许
413: 请求体过大
500: 服务器内部错误
503: 服务不可用
```

### 2. 错误响应格式
```json
{
  "success": false,
  "timestamp": "2025-06-30T21:46:21.734926+01:00",
  "error": "Error Type",
  "message": "详细错误信息",
  "path": "/api/endpoint"
}
```

### 3. 前端错误处理策略
- **网络错误**: 自动重试机制，最多3次
- **超时错误**: 显示友好提示，提供重试选项
- **服务不可用**: 启用降级模式，使用缓存数据
- **权限错误**: 自动跳转到登录页面
- **数据格式错误**: 记录日志，使用默认值

---

## ⚙️ 配置说明

### 1. API端点配置
文件: `lib/services/api_config.dart`
```dart
class ApiConfig {
  // 🔧 后端服务地址 - 根据实际部署修改
  static const String springBootBaseUrl = 'http://localhost:8080';
  static const String ocrBaseUrl = 'http://localhost:8000';
  static const String recommendationBaseUrl = 'http://localhost:8001';
  
  // 🔧 超时配置 - 可根据网络环境调整
  static const Duration defaultTimeout = Duration(seconds: 8);
  static const Duration ocrTimeout = Duration(seconds: 20);
  static const Duration recommendationTimeout = Duration(seconds: 15);
  
  // 🔧 功能开关
  static const bool useMockData = false;
  static const bool enableQuickMode = true;
  static const bool showDetailedProgress = true;
  static const bool enableFallbackMode = true;
}
```

### 2. 缓存配置
文件: `lib/services/cache_service.dart`
```dart
// 缓存过期时间
static const Duration _defaultCacheExpiry = Duration(hours: 24);
static const Duration _productCacheExpiry = Duration(hours: 12);
static const Duration _userCacheExpiry = Duration(hours: 6);
static const Duration _allergenCacheExpiry = Duration(days: 7);
```

### 3. 主题配置
文件: `lib/presentation/theme/app_colors.dart`
```dart
// 🎨 主色调配置
static const Color primary = Color(0xFF4CAF50);
static const Color background = Color(0xFFF5F5F5);
static const Color white = Color(0xFFFFFFFF);
static const Color textDark = Color(0xFF333333);
static const Color textLight = Color(0xFF757575);
static const Color alert = Color(0xFFE53E3E);
```

---

## 🧪 测试指南

### 1. 功能测试清单

#### 用户认证测试
- [ ] 用户登录功能
- [ ] 用户注册功能
- [ ] 登录状态持久化
- [ ] 登出功能

#### 产品扫描测试
- [ ] 条码扫描功能
- [ ] 产品信息显示
- [ ] 过敏原警告
- [ ] 推荐信息显示

#### 小票分析测试
- [ ] 图片上传功能
- [ ] OCR识别结果
- [ ] 购买清单生成
- [ ] 错误处理

#### 过敏原管理测试
- [ ] 查看过敏原列表
- [ ] 添加过敏原
- [ ] 删除过敏原
- [ ] 过敏原搜索

### 2. 测试数据
```json
// 测试用户账号
{
  "userName": "tpz",
  "passwordHash": "123456"
}

// 测试条码
"7224" - 已知产品
"1234567890123" - 未知产品
```

### 3. 浏览器兼容性
- ✅ Chrome 90+
- ✅ Safari 14+
- ✅ Firefox 88+
- ✅ Edge 90+

---

## 🔍 问题排查

### 1. 常见问题

#### 前端无法连接后端
```bash
# 检查API配置
grep -r "localhost" lib/services/api_config.dart

# 检查网络连接
curl http://localhost:8080/health

# 检查CORS配置
# 后端需要允许前端域名的跨域请求
```

#### 过敏原功能不工作
```bash
# 检查过敏原API端点
curl -X GET http://localhost:8080/allergen/list
curl -X GET http://localhost:8080/user/13/allergens

# 检查数据库连接
# 确保过敏原表和用户过敏原表已创建
```

#### OCR服务无法使用
```bash
# 检查OCR服务状态
curl http://localhost:8000/health

# 检查OCR服务启动
# 确保OCR服务在端口8000运行
```

#### 推荐功能超时
```bash
# 检查推荐服务
curl http://localhost:8001/health

# 调整超时配置
# 修改 api_config.dart 中的 recommendationTimeout
```

### 2. 日志查看
前端应用在浏览器控制台输出详细日志，包括：
- 🔍 API请求和响应
- ⚡ 性能监控数据
- ❌ 错误详情和堆栈
- 📦 缓存操作记录

### 3. 性能优化建议
- 启用API响应缓存
- 优化图片上传大小
- 使用CDN加速静态资源
- 实施接口请求去重
- 配置合理的超时时间

---

## 📞 技术支持

### 联系方式
- **前端技术问题**: 查看本文档或检查浏览器控制台日志
- **API集成问题**: 参考接口规范章节
- **部署问题**: 参考快速部署章节

### 更新日志
- **v7.30**: 修复编译错误，优化错误处理，完善API集成
- **v7.29**: 添加OCR服务支持，优化用户体验
- **v7.28**: 实现过敏原管理功能，添加缓存机制

---

## 📝 许可证

本项目采用 MIT 许可证，详情请查看 LICENSE 文件。

---

**最后更新**: 2025-06-30
**文档版本**: v1.0
**前端版本**: v7.30 - demo/presentation-ready 