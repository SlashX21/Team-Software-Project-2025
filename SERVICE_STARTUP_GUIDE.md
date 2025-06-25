# 🚀 服务启动指南

本指南将帮助你按正确顺序启动所有服务组件。

## 📋 服务端口分配

| 服务名称 | 端口 | 说明 |
|---------|------|------|
| Backend (Spring Boot) | 8080 | 主后端服务 |
| OCR System | 8000 | 图片识别服务 |
| Recommendation System | 8001 | 推荐系统服务 |

## 🔧 启动步骤

### 1. 启动推荐系统 (端口 8001)

```bash
# ******1
# 进入推荐系统目录
cd Recommendation/src/main/java/org/recommendation/Rec_LLM_Module

# ******2
#创建虚拟环境(如果有的话不需要)
python3 -m venv venv 

# ******3
# 激活虚拟环境 并 安装依赖包(已经安装了则不需要)
source venv/bin/activate
pip install -r requirements.txt

# ******4
#创建 test_maven_db.env 文件(有则不需要, 如果有的话一定要把Open AI key配置好, 不然无法运行)
cd Recommendation/src/main/java/org/recommendation/Rec_LLM_Module
touch test_maven_db.env

# ******5
#给刚创建的文家中复制以下内容
# Grocery Guardian推荐系统环境配置
# 用于连接Maven Liquibase创建的数据库

# ============================================
# 基础配置
# ============================================
ENVIRONMENT=java_integration

# ============================================
# 数据库配置
# ============================================
# 数据库类型
DB_TYPE=mysql

# 数据库连接字符串（与后端Spring Boot配置保持一致）
JAVA_DB_CONNECTION_STRING=mysql+pymysql://root:sunyanhao@localhost:3306/springboot_demo?charset=utf8mb4

# ============================================
# OpenAI配置（如果需要）
# ============================================
OPENAI_API_KEY=your_openai_api_key_here

# ============================================
# API服务配置
# ============================================
API_PORT=8001
API_HOST=0.0.0.0

# ============================================
# 日志配置
# ============================================
LOG_LEVEL=INFO

# ============================================
# Java后端集成配置
# ============================================
JAVA_BACKEND_URL=http://localhost:8080

# ******6
# 启动推荐系统API
python start_with_maven_db.py
```

**验证推荐系统启动成功**:
- 访问 http://localhost:8001/health
- 访问 http://localhost:8001/docs (API文档)

### 2. 启动OCR系统 (端口 8000)

```bash
# 进入OCR系统目录
cd Ocr/src/main/java/org/ocr/python/demo

# 创建虚拟环境(有的话就不用)
python3 -m venv venv

# 激活虚拟环境 并 安装依赖包(已经安装了就不用了)
source venv/bin/activate
pip install -r requirements.txt

# 创建.env文件(如果有就不需要了)
OPENAI_API_KEY=yours
API_TOKEN=yours
AZURE_ENDPOINT=yours
AZURE_KEY=yours

# 启动OCR系统API
uvicorn main:app --host 0.0.0.0 --port 8000
```

**验证OCR系统启动成功**:
- 访问 http://localhost:8000/

### 3. 启动Backend主服务 (端口 8080)

```bash
# 在项目根目录
mvn spring-boot:run -pl Backend

# 或者使用IDE直接运行 SpringbootDemoApplication.java
```

**验证Backend启动成功**:
- 访问 http://localhost:8080/recommendations/health
- 访问 http://localhost:8080/ocr/health

## 🧪 API测试示例

### 测试推荐系统

#### 条码推荐
```bash
curl -X POST http://localhost:8080/recommendations/barcode \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "productBarcode": "45"
  }'
```

#### 小票分析
```bash
curl -X POST http://localhost:8080/recommendations/receipt \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "purchasedItems": [
      {
        "barcode": "45",
        "quantity": 2
      },
      {
        "barcode": "17",
        "quantity": 1
      }
    ]
  }'
```

### 测试OCR系统

```bash
# 使用Postman或其他工具上传图片文件到：
# POST http://localhost:8080/ocr/scan
# 参数名: file
# 类型: multipart/form-data
```

## 🔍 故障排除

### 端口占用问题
如果遇到端口占用错误：

```bash
# 查看端口占用
lsof -ti:8000
lsof -ti:8001
lsof -ti:8080

# 终止占用进程
kill <PID>
```

### 服务连接问题
1. 确保所有服务按顺序启动
2. 检查防火墙设置
3. 验证配置文件中的端口设置

### 数据库连接问题
确保MySQL数据库服务正在运行：
```bash
# macOS
brew services start mysql

# 验证数据库连接
mysql -u root -p -e "SHOW DATABASES;"
```

## 📝 配置文件位置

- **Backend配置**: `Backend/src/main/resources/application.properties`
- **OCR配置**: `Ocr/src/main/java/org/ocr/python/demo/requirements.txt`
- **推荐系统配置**: `Recommendation/src/main/java/org/recommendation/Rec_LLM_Module/test_maven_db.env`

## 🎯 成功启动的标志

当所有服务成功启动后，你应该能够：

1. ✅ 通过Backend API调用推荐系统
2. ✅ 通过Backend API调用OCR系统  
3. ✅ 所有健康检查接口返回正常状态
4. ✅ API文档页面可以正常访问

## 📞 获取帮助

如果遇到问题，请检查：
1. 控制台日志输出
2. 各服务的健康检查接口
3. 网络连接和端口配置
4. 数据库连接状态 