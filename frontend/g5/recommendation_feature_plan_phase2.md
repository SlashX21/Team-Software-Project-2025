# Phase 2: 推荐功能集成实现方案

## 目标
在已有用户会话管理基础上，集成商品推荐功能，为扫描的商品提供个性化替代推荐。

## 前置条件确认
- ✅ UserService已实现，可通过 `UserService.getCurrentUserId()` 获取真实用户ID
- ✅ 用户登录状态正常管理
- ✅ 推荐服务运行在8001端口

## 实现方案

### 1. 创建推荐数据模型
**新建文件**: `lib/domain/entities/recommendation_response.dart`

**需要创建的模型类**:
```dart
// 主要数据模型
class RecommendationResponse
class RecommendedProduct  
class LLMAnalysis
class UserProfileSummary
class ProductInfo
```

**数据结构参考**（基于后端返回格式）:
- recommendationId: String
- scanType: String  
- userProfileSummary: UserProfileSummary对象
- recommendations: List<RecommendedProduct>
- llmAnalysis: LLMAnalysis对象

### 2. 扩展API服务
**修改文件**: `lib/services/api.dart`

**新增方法**: `getProductRecommendations()`

**接口配置**:
- URL: `http://10.0.2.2:8001/recommendations/barcode`
- 方法: POST
- 超时时间: 30秒
- 请求头: `Content-Type: application/json`

**请求参数**:
```json
{
  "userId": "从UserService获取",
  "productBarcode": "扫描的条码"
}
```

**错误处理要求**:
- 网络超时: 显示"推荐服务响应较慢，请稍等"
- HTTP错误: 显示状态码和响应内容
- JSON解析错误: 显示具体的数据格式异常
- 不使用降级处理，直接暴露错误便于调试

### 3. 修改扫描分析页面
**修改文件**: `lib/presentation/screens/analysis/analysis_result_screen.dart`

#### 3.1 状态变量扩展
**新增状态变量**:
```dart
RecommendationResponse? _recommendationData;
bool _isLoadingRecommendation = false;
String? _recommendationError;
```

#### 3.2 扫描流程改造
**修改 `_onBarcodeScanned` 方法**:
1. 获取产品信息成功后
2. 立即调用推荐接口
3. 自动触发，无需用户操作

**新增 `_getRecommendations` 方法**:
- 获取当前用户ID
- 调用推荐API
- 更新推荐状态
- 处理各种错误情况

#### 3.3 状态重置逻辑
**修改 `_resetScanningState` 方法**:
确保重置时清除推荐相关状态:
- _recommendationData = null
- _isLoadingRecommendation = false  
- _recommendationError = null

### 4. UI显示设计

#### 4.1 页面布局结构
```
现有扫描区域
│
现有产品信息卡片
│
推荐功能区域：
├── 推荐加载状态卡片
├── 推荐错误状态卡片（如果有错误）
└── 推荐结果显示区域
    ├── 推荐商品列表卡片
    └── LLM分析卡片
```

#### 4.2 新增UI组件方法

**`_buildRecommendationSection()`**: 推荐功能主入口
- 根据状态显示加载、错误或结果

**`_buildRecommendationLoading()`**: 加载状态
- 显示加载指示器
- 文字: "正在获取个性化推荐..."
- 提示用户推荐可能需要较长时间

**`_buildRecommendationError()`**: 错误状态  
- 显示具体错误信息
- 包含HTTP状态码、错误详情
- 红色主题，便于问题定位

**`_buildRecommendationsList()`**: 推荐商品列表
- 标题: "💡 推荐替代商品" 
- 每个推荐商品显示:
  - 排名 (#1, #2...)
  - 商品名称
  - 关键营养信息
  - 推荐分数
  - 推荐理由
- 绿色主题，卡片式布局

**`_buildLLMAnalysisCard()`**: LLM分析结果
- 标题: "🤖 智能营养分析"
- 分析摘要 (summary)
- 行动建议列表 (actionSuggestions)
- 温和的黄色背景

#### 4.3 卡片设计规范
- 圆角: 12px
- 阴影: `BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)`
- 间距: 16px margin
- 内边距: 20px padding
- 与现有产品信息卡片保持一致的设计风格

### 5. 错误处理策略

#### 5.1 用户未登录
```dart
final userId = await UserService.getCurrentUserId();
if (userId == null) {
  setState(() => _recommendationError = "用户未登录，无法获取推荐");
  return;
}
```

#### 5.2 网络相关错误
- **超时**: "推荐服务响应时间较长，请耐心等待"
- **网络断开**: "网络连接异常，请检查网络设置"
- **服务不可用**: "推荐服务暂时不可用"

#### 5.3 API响应错误
- **HTTP 4xx**: 显示"请求参数错误: [状态码] [响应内容]"
- **HTTP 5xx**: 显示"服务器错误: [状态码] [响应内容]"  
- **JSON解析失败**: 显示"数据格式异常: [异常详情]"

#### 5.4 业务逻辑错误
- **无推荐结果**: 显示"暂无适合的推荐商品"
- **用户画像不完整**: 显示相应提示信息

### 6. 性能优化考虑

#### 6.1 请求管理
- 避免重复请求：在加载中时忽略新的推荐请求
- 30秒超时设置
- 取消机制：用户重置扫描时取消进行中的推荐请求

#### 6.2 UI响应
- 推荐加载时不阻塞产品信息显示
- 长文本的适配显示（省略号、展开功能）
- 滚动性能优化

### 7. 集成步骤指导

#### Step 1: 数据模型创建
1. 创建recommendation_response.dart文件
2. 定义所有必要的数据模型类
3. 添加fromJson和toJson方法

#### Step 2: API集成
1. 在api.dart中添加getProductRecommendations方法
2. 实现完整的错误处理
3. 测试API调用是否正常

#### Step 3: 页面集成
1. 扩展analysis_result_screen.dart的状态管理
2. 修改扫描流程，添加推荐调用
3. 实现基础的推荐结果显示

#### Step 4: UI完善
1. 实现所有推荐相关UI组件
2. 优化卡片设计和布局
3. 完善加载和错误状态显示

#### Step 5: 测试验证
1. 测试正常推荐流程
2. 测试各种错误场景
3. 验证用户体验和性能

### 8. 测试验证要点

#### 8.1 正常流程测试
- 扫描商品后自动获取推荐
- 推荐数据完整显示
- 用户信息正确传递

#### 8.2 错误场景测试  
- 网络断开时的错误处理
- 推荐服务异常的错误显示
- 超时情况的用户提示
- 未登录用户的处理

#### 8.3 UI体验测试
- 长时间加载的用户反馈
- 大量推荐数据的显示适配
- 页面滚动和交互流畅性

### 9. 验收标准

Phase 2完成后应达到：
1. ✅ 扫描商品后自动调用推荐接口
2. ✅ 使用真实用户ID获取个性化推荐
3. ✅ 完整显示推荐结果（用户画像、商品列表、LLM分析）
4. ✅ 各种错误情况都有清晰的提示信息
5. ✅ 加载状态有友好的用户反馈
6. ✅ 重置扫描时正确清除推荐状态

## 下一步

Phase 2完成后，推荐功能将完全集成到扫描流程中，用户可以获得基于个人营养目标的智能商品推荐建议。