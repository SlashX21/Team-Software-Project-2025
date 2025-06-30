# Grocery Guardian - 健康食品助手

## 📱 项目简介

Grocery Guardian 是一个全栈健康食品助手应用，帮助用户扫描食品、追踪营养摄入、管理过敏原信息，并提供个性化的健康建议。

## 🏗️ 技术架构

### 后端服务
- **Spring Boot** - 主后端服务 (端口 8080)
- **Python FastAPI** - 推荐系统 (端口 8001)
- **Python FastAPI** - OCR图像识别系统 (端口 8000)
- **MySQL** - 数据库存储

### 前端应用
- **Flutter** - 跨平台移动应用
- **Material Design** - 现代化UI设计
- **响应式布局** - 支持多种屏幕尺寸

## 🚀 快速启动

### 环境要求
- Java 17+
- Python 3.8+
- Flutter 3.0+
- MySQL 8.0+
- Maven 3.6+

### 启动步骤

1. **启动MySQL数据库**
```bash
brew services start mysql
```

2. **启动后端服务**
```bash
cd backend
mvn spring-boot:run -pl Backend
```

3. **启动推荐系统**
```bash
cd backend/Recommendation/src/main/java/org/recommendation/Rec_LLM_Module
source venv/bin/activate
python start_with_maven_db.py
```

4. **启动OCR系统**
```bash
cd backend/Ocr/src/main/java/org/ocr/python/demo
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000
```

5. **启动前端应用**
```bash
cd frontend/grocery_guardian_app
flutter run -d chrome --web-port 3000
```

## 🌐 访问地址

- **前端应用**: http://localhost:3000
- **后端API**: http://localhost:8080
- **推荐系统**: http://localhost:8001
- **OCR系统**: http://localhost:8000

## 📱 功能特性

### 用户管理
- 用户注册/登录
- 个人信息管理
- 健康信息设置

### 产品扫描
- 条形码扫描
- 产品成分分析
- 过敏原检测

### 营养追踪
- 糖分摄入追踪
- 营养目标设置
- 进度可视化

### 健康建议
- 个性化推荐
- 月度健康报告
- 购买建议

### 历史记录
- 扫描历史
- 营养摄入记录
- 数据统计分析

## 📁 项目结构

```
Team- Project/
├── backend/                    # 后端服务
│   ├── Backend/               # Spring Boot主服务
│   ├── User/                  # 用户管理模块
│   ├── Product/               # 产品管理模块
│   ├── Allergen/              # 过敏原检测模块
│   ├── Ocr/                   # OCR图像识别模块
│   ├── Recommendation/        # 推荐系统模块
│   └── common/                # 公共模块
├── frontend/                   # 前端应用
│   └── grocery_guardian_app/  # Flutter应用
├── database/                   # 数据库文件
│   ├── allergen_dictionary.csv
│   ├── ireland_products_final.csv
│   └── *.sql                  # 数据库脚本
└── docs/                      # 项目文档
```

## 🔧 配置说明

### 数据库配置
- **数据库**: MySQL
- **主机**: localhost:3306
- **数据库名**: springboot_demo
- **用户名**: root
- **密码**: 123456+a

### 环境变量
- 后端配置: `backend/Backend/src/main/resources/application.properties`
- 推荐系统: `backend/Recommendation/src/main/java/org/recommendation/Rec_LLM_Module/test_maven_db.env`
- OCR系统: `backend/Ocr/src/main/java/org/ocr/python/demo/.env`

## 📊 API文档

### 用户API
- `POST /user` - 用户注册
- `POST /user/login` - 用户登录
- `PUT /user` - 更新用户信息

### 产品API
- `GET /product/{barcode}` - 获取产品信息
- `POST /product/scan` - 扫描产品

### 推荐API
- `POST /recommendations/barcode` - 基于条码推荐
- `POST /recommendations/receipt` - 基于小票推荐

### OCR API
- `POST /ocr/scan` - 图像识别

## 🛠️ 开发指南

### 后端开发
1. 使用Maven管理依赖
2. 遵循RESTful API设计规范
3. 使用JPA进行数据持久化
4. 集成Liquibase进行数据库版本管理

### 前端开发
1. 使用Flutter框架
2. 遵循Material Design规范
3. 实现响应式布局
4. 使用Provider进行状态管理

## 📝 许可证

本项目采用 MIT 许可证。

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📞 联系方式

如有问题或建议，请通过以下方式联系：
- 项目Issues: [GitHub Issues]
- 邮箱: [项目邮箱]

---

**Grocery Guardian** - 让健康饮食更简单！ # Team-Software-Project-2025
