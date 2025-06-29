# Grocery Guardian 开发规范统一指南

## 📋 文档概述

本文档是Grocery Guardian项目的“单一事实来源”，整合了所有开发规范，为开发团队提供统一、准确的指导。

**版本**: v1.2 ✨ **SOTA标准对齐版**  
**最后更新**: 2025年6月29日  
**验证状态**: ✅ **所有核心服务及流程已通过实际运行验证**  
**适用范围**: Grocery Guardian 完整项目（Backend + Frontend + AI模块）

---

## 🏗️ 项目架构标准

### 技术栈规范

#### Backend (Java Spring Boot)
- **框架版本**: Spring Boot 3.3.12 ✅ **已验证**
- **Java版本**: JDK 17
- **构建工具**: Maven
- **数据库**: MySQL 8.0+ ✅ **连接正常**
- **API文档**: OpenAPI 3 (通过SpringDoc自动生成)

#### Frontend (Flutter)
- **框架版本**: Flutter 3.x+ ✅ **已验证**
- **Dart版本**: 2.17+
- **状态管理**: BLoC (推荐)
- **网络请求**: Dio
- **本地存储**: SharedPreferences/Hive

#### AI服务 (Python)
- **Python版本**: 3.8+ ✅ **已验证**
- **Web框架**: FastAPI ✅ **运行正常**
- **机器学习**: scikit-learn, pandas, numpy
- **LLM集成**: Azure OpenAI API

---

## 🌐 服务端口与网络配置

### 标准端口分配 ✅ **已验证**
| 服务名称 | 端口 | 用途 | 状态 | 健康检查端点 |
|---------|------|------|------|--------------|
| Backend (Spring Boot) | 8080 | 主后端服务API | ✅ 运行中 | `/user` (通过POST测试) |
| OCR Service | 8000 | 图片识别服务 | 🔄 **待启动** | `http://localhost:8000/` |
| Recommendation Service | 8001 | AI推荐系统服务 | ✅ 运行中 | `http://localhost:8001/health` |

### API路径规范 ✅ **实际验证**
```
统一API前缀: /api/v1/ (推荐)
Backend实际路径:
- POST /user (用户注册/管理)
- GET /products/* (商品服务)
- POST /recommendations/* (推荐服务代理)
- POST /ocr/* (OCR服务代理)

Python服务健康检查:
- GET http://localhost:8001/health (推荐系统)
- GET http://localhost:8000/ (OCR系统)
```

### 跨域配置 (CORS)
```yaml
# Spring Boot application.properties
# 允许来自Flutter Web (Chrome)的请求
allowed_origins: http://127.0.0.1:3000, http://localhost:3000
```

---

## 🗄️ 数据库设计标准

### 连接配置规范 ✅ **已验证可用**

#### 开发环境配置 (`application-dev.properties`)
```properties
spring.datasource.url=${DATABASE_URL:jdbc:mysql://localhost:3306/springboot_demo?createDatabaseIfNotExist=true&charset=utf8mb4&serverTimezone=UTC&useSSL=false&allowPublicKeyRetrieval=true}
spring.datasource.username=${DB_USERNAME:root}
spring.datasource.password=${DB_PASSWORD:20020213Lx}
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
```

#### Navicat连接配置 ✅ **验证成功**
```
连接名称:    Grocery Guardian DB
主机名/IP:   localhost
端口:        3306
用户名:      root  
密码:        20020213Lx
数据库:      springboot_demo
```

---

## 🔧 环境配置管理

### 环境变量标准 ✅ **实际验证**

#### 统一环境变量文件 (`.env`)
```bash
# .env（项目根目录）
# ============================================
# 数据库配置
# ============================================
DB_NAME=springboot_demo
DB_USERNAME=root
DB_PASSWORD=20020213Lx
DB_HOST=localhost
DB_PORT=3306

# ============================================
# 微服务端口配置
# ============================================
BACKEND_PORT=8080
OCR_SERVICE_PORT=8000
RECOMMENDATION_SERVICE_PORT=8001

# ============================================
# AI服务与Azure配置
# ============================================
OPENAI_API_KEY=sk-proj-....
AZURE_ENDPOINT=https://grocery-guardian.cognitiveservices.azure.com
AZURE_KEY=5z4tn....
```

#### Python服务专用环境 (`test_maven_db.env`)
```bash
# AI模块 test_maven_db.env 文件
# 此文件用于Java与Python集成测试
ENVIRONMENT=java_integration
DB_TYPE=mysql
JAVA_DB_CONNECTION_STRING=mysql+pymysql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?charset=utf8mb4
API_PORT=${RECOMMENDATION_SERVICE_PORT}
API_HOST=0.0.0.0
OPENAI_API_KEY=${OPENAI_API_KEY}
JAVA_BACKEND_URL=http://localhost:${BACKEND_PORT}
```

---

## 🚀 部署与启动流程 ✅ **SOTA验证版本**

### 1. 前置条件检查
```bash
# 检查MySQL服务状态 (macOS)
brew services list | grep mysql
# 如果stopped，启动：brew services start mysql

# 检查关键端口是否被占用
lsof -ti:8000 -ti:8001 -ti:8080 || echo "✅ 关键端口未被占用，可以启动"

# 验证数据库连接
mysql -u${DB_USERNAME} -p${DB_PASSWORD} -e "SHOW DATABASES;"
```

### 2. 标准服务启动顺序
```bash
# Step 1: 启动AI推荐服务 (端口 8001)
# 终端1:
echo "🚀 正在启动AI推荐服务..."
cd Team-Software-Project-2025/Backend/Team-Software-Project-2025-YanHaoSun/Recommendation/src/main/java/org/recommendation/Rec_LLM_Module
export PYTHON_API_PORT=$RECOMMENDATION_SERVICE_PORT
python start_with_maven_db.py
# 预期输出: "🚀 启动Grocery Guardian推荐系统API..."

# Step 2: 启动Backend主服务 (端口 8080)
# 终端2:
echo "🚀 正在启动Java Backend主服务..."
cd Team-Software-Project-2025
bash start_backend_test.sh
# 预期输出: Spring Boot应用启动日志

# Step 3: 启动前端应用 (端口 3000)
# 终端3:
echo "🚀 正在启动Flutter前端应用..."
cd frontend/g5
flutter pub get
flutter run -d chrome --web-port 3000
# 预期输出: Flutter应用在Chrome中打开

# Step 4 (可选): 启动OCR服务 (端口 8000)
# 终端4:
echo "🐍 正在启动Python OCR服务..."
cd Team-Software-Project-2025/Backend/Team-Software-Project-2025-YanHaoSun/Ocr/src/main/java/org/ocr/python/demo
pip install pyzbar python-multipart azure-ai-vision-imageanalysis
uvicorn main:app --host 0.0.0.0 --port $OCR_SERVICE_PORT
```

### 3. 健康检查与API验证
```bash
# 验证AI推荐服务
curl http://localhost:8001/health
# ✅ 预期: {"success":true,"message":"Grocery Guardian Recommendation Service is healthy",...}

# 验证Backend用户注册功能
curl -X POST http://localhost:8080/user -H "Content-Type: application/json" -d '{"userName":"test123","passwordHash":"test123","email":"test@example.com","gender":"MALE","heightCm":175.0,"weightKg":70.0}'
# ✅ 预期: 包含 "User registered successfully" 和 userId 的JSON响应

# 验证OCR服务 (如果已启动)
curl http://localhost:8000/
# ✅ 预期: {"message":"Welcome to the OCR service"}
```

---

## 🎨 UI/UX 设计规范

### 视觉设计标准

#### 颜色系统 ✅ **前端已应用**
```css
/* 主色调 */
--primary-green: #4CAF50;      /* 导航栏，主要按钮 */
--primary-light: #E8F5E8;      /* 卡片背景 */
--primary-dark: #2E7D32;       /* 文字，图标 */
```

#### 组件设计标准
```css
/* 卡片样式 */
.card {
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
/* 按钮样式 */
.button-primary {
  border-radius: 8px;
  background: linear-gradient(135deg, #4CAF50, #45A049);
}
```

---

## 📡 API接口规范

### RESTful API设计标准

#### 标准响应格式 (`ApiResponse<T>`)
```json
{
  "success": true,
  "timestamp": "2025-06-29T10:30:00Z",
  "data": { ... }, // 业务数据
  "error": null
}
```

#### 错误响应格式
```json
{
  "success": false,
  "timestamp": "2025-06-29T10:30:00Z",
  "data": null,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "未找到指定资源"
  }
}
```

---

## 📝 代码规范

### Java (`RecommendationService.java`)
```java
// 类命名：PascalCase
public class RecommendationService {
    // 常量：UPPER_SNAKE_CASE
    private static final String API_BASE_URL = "http://localhost:8001";
    // 方法/变量：camelCase
    public ResponseEntity<Object> getBarcodeRecommendation(BarcodeRecommendationRequest request) { ... }
}
```

### Dart (`product_scanner_page.dart`)
```dart
// 类命名：PascalCase
class ProductScannerPage extends StatefulWidget { ... }

// Gender选项标准化 ✅ 已修复
final List<String> _genderOptions = ['MALE', 'FEMALE', 'OTHER'];
String _selectedGender = 'MALE';
```

### Python (`recommendation_engine.py`)
```python
# 类命名：PascalCase
class RecommendationEngine:
    # 常量：UPPER_SNAKE_CASE
    MAX_RECOMMENDATIONS = 5
    # 函数/变量：snake_case
    def generate_barcode_recommendations(self, user_id: int, product_barcode: str): ...
```

---

## 🚨 故障排除指南 ✅ **SOTA验证版本**

### 数据库连接失败
```bash
# 1. 检查MySQL服务是否运行
brew services list | grep mysql
# 2. 如果未运行，启动服务
brew services start mysql
# 3. (备用) 手动启动
mysqld_safe --user=mysql --datadir=/opt/anaconda3/data &
# 4. 测试连接
mysql -uroot -p20020213Lx -e "SELECT 1"
```

### 前端API连接问题 (Chrome)
```dart
// 问题: 在Chrome中调试时，应使用127.0.0.1而不是localhost或10.0.2.2
// 修复 ✅:
const String baseUrl = 'http://127.0.0.1:8080';
```

### Python依赖缺失 (OCR服务)
```bash
# 问题: OCR服务启动时提示 "ModuleNotFoundError"
# 解决 ✅: 安装所需依赖
pip install pyzbar python-multipart azure-ai-vision-imageanalysis
```

### 端口冲突
```bash
# 1. 查找占用指定端口的进程 (例如 8080)
lsof -ti:8080
# 2. 强制终止该进程
kill -9 $(lsof -ti:8080)
```

---

## 🔄 版本控制规范

### Git工作流
- **主分支**: `main` (生产), `develop` (开发集成)
- **功能分支**: `feature/add-new-feature`
- **修复分支**: `fix/correct-a-bug`

### 提交信息规范
```
# 格式: type(scope): description
feat(api): add user profile endpoint
fix(ui): resolve login button alignment
docs(readme): update setup instructions
```

---

**注意**: 本文档是动态更新的，旨在反映项目最新、最准确的开发实践。所有标记为 ✅ **已验证** 的部分都经过了实际测试。