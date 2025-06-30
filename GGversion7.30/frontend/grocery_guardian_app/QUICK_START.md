# 🚀 Grocery Guardian 前端快速部署指南

## 5分钟快速上手

### 1. 环境准备
```bash
# 检查Flutter环境
flutter --version
flutter config --enable-web
flutter doctor

# 如果没有安装Flutter，请访问: https://flutter.dev/docs/get-started/install
```

### 2. 获取项目
```bash
# 从GitHub拉取前端代码
git clone <your-repository-url>
cd GGversion7.30/frontend/grocery_guardian_app

# 安装依赖
flutter pub get
```

### 3. 配置后端地址
编辑 `lib/services/api_config.dart`：
```dart
static const String springBootBaseUrl = 'http://your-backend:8080';  // 👈 修改这里
static const String ocrBaseUrl = 'http://your-ocr-service:8000';     // 👈 修改这里
static const String recommendationBaseUrl = 'http://your-rec:8001';  // 👈 修改这里
```

### 4. 启动应用
```bash
# 开发模式启动
flutter run -d chrome

# 生产构建
flutter build web
```

## 🧪 快速测试

### 测试账号
```
用户名: tpz
密码: 123456
```

### 测试条码
- `7224` - 已知产品，会返回完整信息
- `1234567890123` - 未知产品，会触发推荐

## 📋 必需的后端API端点

### 核心功能 (必须实现)
```
POST /user/login          - 用户登录
POST /user/register       - 用户注册  
GET  /user/{userId}       - 获取用户信息
POST /user                - 更新用户信息
GET  /product/{barcode}   - 产品信息查询
```

### 过敏原功能 (可选)
```
GET  /allergen/list              - 过敏原列表
GET  /user/{userId}/allergens    - 用户过敏原
POST /user/{userId}/allergens    - 添加过敏原
```

### 外部服务 (可选)
```
POST /ocr/scan                   - OCR服务 (端口8000)
POST /recommendations/barcode    - 推荐服务 (端口8001)
```

## ⚠️ 常见问题

**Q: 前端启动失败？**
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

**Q: API连接失败？**
- 检查 `api_config.dart` 中的后端地址
- 确保后端服务正在运行
- 检查防火墙和CORS设置

**Q: 编译错误？**
```bash
flutter doctor          # 检查环境
flutter --version       # 确保Flutter版本兼容
```

## 📞 支持

- 详细文档: `FRONTEND_INTEGRATION_GUIDE.md`
- 浏览器控制台查看错误日志
- 检查网络请求状态

---
**版本**: v7.30 | **最后更新**: 2025-06-30 