# 🛒 Grocery Guardian API

**智能营养推荐系统API** - 基于商品扫描和小票分析的健康选择推荐服务

[![FastAPI](https://img.shields.io/badge/FastAPI-0.104.1-009688.svg?style=flat&logo=FastAPI)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg?style=flat&logo=python)](https://python.org)
[![SQLite](https://img.shields.io/badge/SQLite-3.0+-003B57.svg?style=flat&logo=sqlite)](https://sqlite.org)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-412991.svg?style=flat&logo=openai)](https://openai.com)

## 📋 项目简介

Grocery Guardian API 是一个智能营养推荐系统，通过商品条码扫描和购物小票分析，为用户提供个性化的健康饮食建议。系统结合用户画像、营养目标和过敏原信息，利用先进的LLM技术生成精准的商品推荐和营养分析。

### 🎯 核心功能

- **📱 商品条码推荐**: 扫描商品条码，获取基于个人营养目标的替代推荐
- **🧾 购物小票分析**: 分析购买历史，提供整体营养评估和改进建议
- **👤 个性化用户画像**: 支持营养目标、过敏原、饮食偏好等多维度用户信息
- **🤖 LLM智能分析**: 集成OpenAI GPT模型，提供自然语言营养建议
- **🔍 智能过滤系统**: 多层级商品筛选，确保推荐的安全性和准确性

## 🚀 技术特性

### 🏗️ 技术栈
- **Web框架**: FastAPI 0.104.1
- **数据库**: SQLite 3.0+
- **AI模型**: OpenAI GPT-4
- **数据处理**: Pandas, NumPy
- **API文档**: Swagger/OpenAPI 3.0

### ⚡ 性能指标
- **条码推荐响应时间**: ~18.7秒（包含LLM分析）
- **小票分析响应时间**: ~3.8秒
- **数据库记录**: 2643+商品，3464+过敏原关联
- **过滤效率**: 50.5%筛选率

## 📦 快速开始

### 环境要求
- Python 3.8+
- pip 包管理器
- OpenAI API密钥

### 1. 克隆项目
```bash
git clone <repository-url>
cd "Rec&LLM Module"
```

### 2. 创建虚拟环境
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或 venv\Scripts\activate  # Windows
```

### 3. 安装依赖
```bash
pip install -r requirements.txt
```

### 4. 环境配置
创建 `.env` 文件并配置必要的环境变量：
```env
OPENAI_API_KEY=your_openai_api_key_here
DATABASE_URL=data/grocery_guardian.db
LOG_LEVEL=INFO
```

### 5. 初始化数据库
```bash
# 完整数据库初始化（包含测试数据）
python database/populate_full_database.py

# 或仅创建表结构
python database/init_db.py
```

### 6. 启动API服务
```bash
# 开发模式
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload

# 生产模式
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

### 7. 访问API文档
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **健康检查**: http://localhost:8000/health

## 🔧 API 使用指南

### 核心端点

#### 1. 商品条码推荐
```http
POST /recommendations/barcode
Content-Type: application/json

{
  "userId": 2,
  "productBarcode": "45"
}
```

**响应示例**:
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
  }
}
```

#### 2. 购物小票分析
```http
POST /recommendations/receipt
Content-Type: application/json

{
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
}
```

### 健康检查
```http
GET /health
```

### 错误处理
API使用标准HTTP状态码，所有响应遵循统一格式：
```json
{
  "success": boolean,
  "message": "string",
  "data": object | null,
  "error": {
    "code": "string",
    "message": "string",
    "details": object
  } | null,
  "timestamp": "ISO8601 string"
}
```

## 📁 项目结构

```
├── api/                          # FastAPI应用
│   ├── __init__.py
│   ├── main.py                   # FastAPI主应用
│   ├── endpoints.py              # API端点定义
│   └── models.py                 # Pydantic数据模型
├── database/                     # 数据库相关
│   ├── init_db.py               # 数据库初始化
│   ├── db_manager.py            # 数据库管理
│   ├── schema.sql               # 数据库结构
│   └── populate_full_database.py # 完整数据填充
├── recommendation/               # 推荐算法
│   ├── recommender.py           # 核心推荐引擎
│   ├── filters.py              # 过滤器系统
│   └── llm_integration.py      # LLM集成
├── data/                        # 数据文件
│   ├── grocery_guardian.db      # SQLite数据库
│   └── en.openfoodfacts.org.products.csv
├── requirements.txt             # Python依赖
└── README.md                   # 项目文档
```

## 🗄️ 数据库设计

### 核心表结构
- **user** - 用户基本信息和营养目标
- **product** - 商品信息和营养数据
- **allergen** - 过敏原信息
- **user_allergen** - 用户过敏原关联
- **recommendation_log** - 推荐历史记录
- **purchase_record** - 购买记录

### 数据统计
- 📊 **商品数据**: 2643条记录
- 🔗 **过敏原关联**: 3464条记录  
- 👥 **测试用户**: 3个完整画像
- 🛒 **购买历史**: 56条购买记录

## 🧪 测试验证

项目包含完整的端到端测试验证：

```bash
# 运行完整测试套件
python database/populate_full_database.py

# 启动API服务
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload

# 执行API功能测试
curl -X POST http://localhost:8000/recommendations/barcode \
  -H "Content-Type: application/json" \
  -d '{"userId": 2, "productBarcode": "45"}'
```

### 测试覆盖范围
- ✅ 服务可用性测试
- ✅ 核心功能验证
- ✅ 错误处理测试
- ✅ 性能基准测试

## 🔧 配置说明

### 环境变量
| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `OPENAI_API_KEY` | OpenAI API密钥 | 必需 |
| `DATABASE_URL` | 数据库路径 | `data/grocery_guardian.db` |
| `LOG_LEVEL` | 日志级别 | `INFO` |
| `API_HOST` | API服务主机 | `0.0.0.0` |
| `API_PORT` | API服务端口 | `8000` |

### 推荐算法配置
- **候选商品数量**: 最多200个
- **最终推荐数量**: 5个
- **过滤器**: 可用性、营养数据、过敏原、分类
- **LLM分析**: GPT-4模型集成

## 🚀 部署指南

### Docker部署（推荐）
```dockerfile
# Dockerfile示例
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 云平台部署
支持部署到AWS、Google Cloud、Azure等主流云平台。

## 📈 监控和日志

### 日志配置
- **格式**: 结构化JSON日志
- **级别**: INFO/DEBUG/ERROR
- **输出**: 控制台 + 文件

### 性能监控
- **响应时间**: HTTP请求头 `X-Process-Time`
- **推荐质量**: 推荐分数和用户反馈
- **系统资源**: CPU、内存使用情况

## 🤝 贡献指南

### 开发流程
1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

### 代码规范
- 遵循PEP 8 Python代码规范
- 使用类型注解
- 编写详细的文档字符串
- 保持测试覆盖率

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持和联系

- **项目维护**: [Your Name](mailto:your.email@example.com)
- **问题反馈**: [GitHub Issues](https://github.com/your-repo/issues)
- **功能建议**: [GitHub Discussions](https://github.com/your-repo/discussions)

## 🙏 致谢

感谢以下开源项目和服务：
- [FastAPI](https://fastapi.tiangolo.com/) - 现代高性能Web框架
- [OpenAI](https://openai.com/) - GPT模型支持
- [Open Food Facts](https://openfoodfacts.org/) - 开放食品数据
- [SQLite](https://sqlite.org/) - 轻量级数据库

---

**Grocery Guardian API** - 让智能营养推荐触手可及 🌱 