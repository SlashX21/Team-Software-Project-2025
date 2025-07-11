# Grocery Guardian 测试数据导入工具

## 概述

本工具包用于将测试数据导入到Grocery Guardian项目的数据库中，已适配当前的数据库结构（`springboot_demo`）。

## 文件结构

```
TestData/
├── allergen_dictionary.csv        # 过敏原数据
├── ireland_products_final.csv     # 产品数据
├── data_import.sql                # SQL导入脚本（备用）
├── user_data_import.sql           # 完整SQL导入脚本
├── import_csv_data.py             # Python导入工具（推荐）
└── README.md                      # 本文档
```

## 数据结构适配

### 字段映射
我们已经将CSV字段映射到当前数据库结构：

| CSV字段 | 数据库字段 | 说明 |
|---------|------------|------|
| `barcode` | `bar_code` | 产品条形码 |
| `name` | `product_name` | 产品名称 |
| `is_common` | `is_common` | 转换为INTEGER (1/0) |

### 数据库信息
- **目标数据库**: `springboot_demo`
- **适配表**: `allergen`, `product`, `user`
- **字段验证**: 包含营养数据类型转换和空值处理

## 导入方式

### 方式一：Python工具（推荐）

Python工具提供完整的数据清理、验证和导入功能。

#### 1. 安装依赖

```bash
pip install pandas mysql-connector-python
```

#### 2. 修改数据库配置

编辑 `import_csv_data.py` 文件中的数据库配置：

```python
self.db_config = {
    'host': 'localhost',      # 数据库主机
    'port': 3306,            # 数据库端口
    'database': 'springboot_demo',  # 数据库名称
    'user': 'root',          # 数据库用户名
    'password': 'your_password',  # 数据库密码
    'charset': 'utf8mb4',
    'autocommit': False
}
```

#### 3. 运行导入工具

```bash
cd TestData
python import_csv_data.py
```

#### 4. 功能特性

- ✅ 自动字段映射（`barcode` → `bar_code`等）
- ✅ 数据清理和验证
- ✅ 营养数据类型转换
- ✅ 过敏原布尔值处理
- ✅ 导入前后数据统计
- ✅ 完整的错误日志
- ✅ 创建测试用户（3个不同营养目标）

### 方式二：SQL脚本

#### 使用完整SQL脚本：

```bash
mysql -u root -p springboot_demo < user_data_import.sql
```

**注意**：SQL脚本中包含了示例数据，如果要导入完整的CSV数据，需要：

1. 取消注释 `LOAD DATA LOCAL INFILE` 语句
2. 修改CSV文件路径为实际路径
3. 确保MySQL允许本地文件导入

## 测试数据说明

### 过敏原数据
- **记录数**: 约30个常见过敏原
- **分类**: dairy, grains, nuts, seafood等
- **字段**: ID, 名称, 分类, 是否常见, 描述

### 产品数据
- **记录数**: 约2600个产品
- **来源**: 爱尔兰产品数据库
- **营养信息**: 能量、蛋白质、脂肪、糖分等
- **过敏原**: 每个产品关联的过敏原信息

### 测试用户
自动创建3个测试用户：

| 用户ID | 用户名 | 营养目标 | 性别 | 年龄 |
|--------|--------|----------|------|------|
| 1 | test_user_1 | lose_weight | female | 28 |
| 2 | test_user_2 | gain_muscle | male | 35 |
| 3 | test_user_3 | maintain | female | 42 |

## 验证导入结果

### 检查数据统计

```sql
-- 查看各表记录数
SELECT 
    'allergen' AS table_name, COUNT(*) AS records FROM allergen
UNION ALL
SELECT 
    'product' AS table_name, COUNT(*) AS records FROM product
UNION ALL
SELECT 
    'user' AS table_name, COUNT(*) AS records FROM user;
```

### 检查数据质量

```sql
-- 有完整营养信息的产品
SELECT COUNT(*) AS complete_nutrition_products
FROM product 
WHERE energy_kcal_100g IS NOT NULL 
  AND proteins_100g IS NOT NULL 
  AND fat_100g IS NOT NULL 
  AND carbohydrates_100g IS NOT NULL;

-- 有过敏原信息的产品
SELECT COUNT(*) AS products_with_allergens
FROM product 
WHERE allergens IS NOT NULL AND allergens != '';

-- 产品类别分布
SELECT category, COUNT(*) AS count
FROM product 
GROUP BY category 
ORDER BY count DESC;
```

### 测试推荐系统查询

```sql
-- 高蛋白产品（适合增肌用户）
SELECT bar_code, product_name, brand, proteins_100g, category 
FROM product 
WHERE proteins_100g > 20 
ORDER BY proteins_100g DESC 
LIMIT 10;

-- 低糖产品（适合减重用户）
SELECT bar_code, product_name, brand, sugars_100g, category 
FROM product 
WHERE sugars_100g IS NOT NULL AND sugars_100g < 5
ORDER BY sugars_100g ASC 
LIMIT 10;
```

## 故障排除

### 常见问题

#### 1. 连接数据库失败
- 检查数据库配置信息
- 确认数据库服务已启动
- 验证用户权限

#### 2. CSV文件不存在
- 确保CSV文件在正确位置
- 检查文件名拼写

#### 3. 导入数据为空
- 检查CSV文件格式
- 验证文件编码（应为UTF-8）

#### 4. 字段类型错误
- 营养数据应为数值型
- 过敏原字段可以包含逗号分隔的值

### 日志文件

运行Python工具后会生成 `import_log.txt` 文件，包含详细的导入日志。

## 推荐系统集成测试

导入数据后，可以测试推荐系统的基本功能：

### 1. 启动推荐系统API
```bash
cd Recommendation/src/main/java/org/recommendation/Rec_LLM_Module
python start_with_maven_db.py
```

### 2. 测试API调用
```bash
curl -X POST http://localhost:8000/recommendation \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "nutrition_goal": "lose_weight",
    "allergens": ["milk"],
    "preferences": ["low_sugar"]
  }'
```

## 后续清理

如果需要清理测试数据：

```sql
-- 清理测试数据（谨慎操作！）
DELETE FROM product WHERE created_at >= '2024-01-01';
DELETE FROM allergen WHERE created_time >= '2024-01-01';
DELETE FROM user WHERE user_id IN (1, 2, 3);
```

## 联系信息

如有问题，请检查：
1. 项目文档：`Doc/` 目录
2. 推荐系统文档：`Recommendation/推荐系统API流程文档.md`
3. 数据库设计文档：`Doc/Database/` 目录

---

**注意**: 此工具仅用于开发和测试环境，请勿在生产环境中使用。 