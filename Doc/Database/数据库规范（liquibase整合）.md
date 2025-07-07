# Grocery Guardian 数据库开发报告（Liquibase统一版）

## 项目概述

**项目名称**：Grocery Guardian - AI 驱动的杂货购物助手  
**数据库用途**：支持个性化商品推荐、过敏原检测、营养分析、用户偏好学习和健康管理  
**核心特性**：基于用户行为的动态偏好推断、实时推荐算法、LLM 驱动的个性化分析、糖分跟踪和月度统计  

---

## 需求分析

### 核心业务需求

1. **商品推荐系统**
   - 基于用户过敏原进行硬过滤
   - 根据营养目标提供个性化推荐
   - 支持协同过滤和内容过滤算法

2. **用户行为分析**
   - 条形码扫描：售前决策支持，不计入购买记录
   - 小票扫描：购买行为记录，用于偏好推断
   - 动态偏好更新：基于购买模式自动推断用户喜好
   - 完整的扫描历史管理和推荐信息存储

3. **营养分析策略**
   - 减脂策略：优先低热量、高纤维商品
   - 增肌策略：优先高蛋白、适量碳水商品
   - 维持策略：追求营养均衡的商品组合
   - 专门的糖分跟踪和目标管理

4. **数据处理流程**
   - 不追踪绝对摄入量，关注营养成分比例
   - 购买数量影响推荐权重
   - 时间衰减因子：近期购买权重更高
   - 月度数据汇总和趋势分析

5. **健康管理功能**
   - 糖分摄入目标设置和跟踪
   - 月度购买和营养数据统计
   - 用户档案管理

### 数据来源定义

- **预输入数据**：OpenFood API 商品数据（75,000+ 爱尔兰市场商品）
- **用户输入数据**：注册信息（身高、体重、年龄、性别、营养目标）
- **动态生成数据**：扫描记录、购买记录、偏好推断、推荐日志
- **健康数据**：糖分摄入记录、健康目标设置、月度统计汇总

---

## 数据库架构设计

### 整体架构原则

1. **以 barcode 为全局主键**：确保商品数据的一致性和完整性
2. **层次化数据结构**：基础数据 → 关联数据 → 行为数据 → 分析结果 → 健康管理
3. **支持动态偏好推断**：通过购买行为自动更新用户偏好
4. **优化查询性能**：针对推荐算法的频繁查询进行索引优化
5. **健康数据分离**：将健康管理相关数据独立存储，便于扩展
6. **字段命名统一**：遵循Liquibase实现的命名规范

### 商品分类体系

基于业务需求，采用5个精简类别：

1. **Food（食品类）**：主食、肉类海鲜、乳制品、果蔬、冷冻食品
2. **Beverages（饮品类）**：各种饮料、功能性饮品
3. **Snacks（零食类）**：零食小食、糖果甜品
4. **Health & Supplements（健康补剂类）**：营养补剂、健康食品
5. **Condiments & Others（调料及其他）**：调料酱汁、其他商品

### 表关系概览

```
PRODUCT (核心商品数据)
    ↓
ALLERGEN ← PRODUCT_ALLERGEN → PRODUCT
    ↓
USER → USER_ALLERGEN → ALLERGEN
    ↓
USER → USER_PREFERENCE (动态更新)
USER → SCAN_HISTORY → PRODUCT (增强版)
USER → PURCHASE_RECORD → PURCHASE_ITEM → PRODUCT
USER → PRODUCT_PREFERENCE → PRODUCT
USER → RECOMMENDATION_LOG
    ↓
USER → SUGAR_GOALS
USER → SUGAR_INTAKE_HISTORY → PRODUCT
USER → MONTHLY_STATISTICS
```

---

## 数据表详细设计

### 1. 基础数据表

#### PRODUCT（商品表）
**数据来源**：OpenFood API 预处理导入  
**更新频率**：批量更新，每周/月同步一次  

| 字段名 | 数据类型 | 约束 | 说明 | 推荐算法用途 |
|--------|----------|------|------|-------------|
| barcode | VARCHAR(255) | PK | 商品唯一标识 | 商品关联主键 |
| name | VARCHAR(255) | 非空 | 商品名称 | OCR 匹配，用户搜索 |
| brand | VARCHAR(255) | 可空 | 品牌名称 | 品牌偏好分析 |
| ingredients | TEXT | 可空 | 成分列表 | LLM 分析，过敏原检测 |
| allergens | TEXT | 可空 | 过敏原信息 | 过敏原提取源数据 |
| energy_100g | FLOAT | 可空 | 能量值（焦耳） | 营养计算辅助 |
| energy_kcal_100g | FLOAT | 可空 | 热量（卡路里） | 减脂目标核心指标 |
| fat_100g | FLOAT | 可空 | 脂肪含量 | 减脂策略筛选 |
| saturated_fat_100g | FLOAT | 可空 | 饱和脂肪 | 健康评分计算 |
| carbohydrates_100g | FLOAT | 可空 | 碳水化合物 | 增肌策略评估 |
| sugars_100g | FLOAT | 可空 | 糖分含量 | 糖分跟踪核心字段 |
| proteins_100g | FLOAT | 可空 | 蛋白质含量 | 增肌目标优先指标 |
| serving_size | VARCHAR(255) | 可空 | 建议食用份量 | 营养计算基准 |
| category | VARCHAR(255) | 非空 | 商品类别 | 同类商品推荐关键字段 |

#### USER（用户表）
**数据来源**：用户注册时填写  
**更新频率**：用户主动更新个人信息  

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| user_id | INT | PK 自增 | 用户唯一标识 | 所有关联表外键 |
| username | VARCHAR(255) | 非空 | 用户名 | 用户识别 |
| email | VARCHAR(255) | 可空 | 邮箱 | 用户识别 |
| password_hash | VARCHAR(255) | 非空 | 密码哈希 | 身份验证 |
| age | INT | 可空 | 年龄 | BMR 计算 |
| gender | VARCHAR(255) | 可空 | 性别 | BMR 性别系数 |
| height_cm | INT | 可空 | 身高 | BMR 计算 |
| weight_kg | FLOAT | 可空 | 体重 | BMR 和需求计算 |
| activity_level | VARCHAR(255) | 可空 | 活动水平 | 总能耗计算 |
| nutrition_goal | VARCHAR(255) | 可空 | 营养目标 | 推荐策略选择 |
| daily_calories_target | FLOAT | 可空 | 每日热量目标 | 推荐阈值设定 |
| daily_protein_target | FLOAT | 可空 | 每日蛋白质目标 | 高蛋白需求评估 |
| daily_carb_target | FLOAT | 可空 | 每日碳水目标 | 碳水摄入平衡 |
| daily_fat_target | FLOAT | 可空 | 每日脂肪目标 | 脂肪摄入控制 |
| date_of_birth | DATE | 可空 | 出生日期 | 年龄精确计算 |
| created_at | DATETIME | 可空 | 创建时间 | 用户注册时间追踪 |
| updated_at | DATETIME | 可空 | 更新时间 | 数据同步时间戳 |

### 2. 过敏原管理表

#### ALLERGEN（过敏原字典表）
**数据来源**：系统启动时从 PRODUCT.allergens 字段提取生成  

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| allergen_id | INT | PK 自增 | 过敏原唯一标识 |
| name | VARCHAR(255) | 非空 | 过敏原标准名称 |
| category | VARCHAR(255) | 可空 | 分类（nuts/dairy/grains 等） |
| is_common | BOOLEAN | 可空 | 是否为常见过敏原（EU 14 种） |
| description | TEXT | 可空 | 过敏原描述 |

#### USER_ALLERGEN（用户过敏原关联表）
**数据来源**：用户注册后选择，使用过程中可添加  
**作用**：推荐算法的硬过滤条件

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| user_allergen_id | INT | PK 自增 | 关联记录 ID | - |
| user_id | INT | FK 非空 | 用户 ID | 用户过敏原查询 |
| allergen_id | INT | FK 非空 | 过敏原 ID | 过敏原匹配 |
| severity_level | VARCHAR(255) | 可空 | 过敏严重程度 | 过滤严格程度 |
| confirmed | BOOLEAN | 默认TRUE | 是否确认过敏 | 是否参与过滤 |
| notes | TEXT | 可空 | 用户备注 | - |

**severity_level 枚举值**：mild, moderate, severe

#### PRODUCT_ALLERGEN（商品过敏原关联表）
**数据来源**：系统启动时解析 PRODUCT.allergens 字段生成  
**作用**：支持快速商品过敏原查询

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| product_allergen_id | INT | PK 自增 | 关联记录 ID | - |
| barcode | VARCHAR(255) | FK 非空 | 商品条码 | 商品过敏原查询 |
| allergen_id | INT | FK 非空 | 过敏原 ID | 过敏原筛选 |
| presence_type | VARCHAR(255) | 默认contains | 包含类型 | 过滤严格程度 |
| confidence_score | FLOAT | 默认1.0 | 解析置信度 | 数据质量评估 |

**presence_type 枚举值**：contains, may_contain, traces

### 3. 用户行为数据表

#### USER_PREFERENCE（用户动态偏好表）
**数据来源**：购买行为分析自动生成 + 用户手动调整  
**更新机制**：每次购买记录分析后更新

| 字段名 | 数据类型 | 约束 | 说明 | 推断逻辑 |
|--------|----------|------|------|---------|
| preference_id | INT | PK 自增 | 偏好记录 ID | - |
| user_id | INT | FK 非空 | 用户 ID | - |
| prefer_low_sugar | BOOLEAN | 默认FALSE | 偏好低糖 | 连续 3 次购买糖分 <5g/100g 商品 |
| prefer_low_fat | BOOLEAN | 默认FALSE | 偏好低脂 | 连续 3 次购买脂肪 <3g/100g 商品 |
| prefer_high_protein | BOOLEAN | 默认FALSE | 偏好高蛋白 | 连续 3 次购买蛋白质 >15g/100g 商品 |
| prefer_low_sodium | BOOLEAN | 默认FALSE | 偏好低钠 | 连续 3 次购买钠 <120mg/100g 商品 |
| prefer_organic | BOOLEAN | 默认FALSE | 偏好有机 | 连续购买有机标识商品 |
| prefer_low_calorie | BOOLEAN | 默认FALSE | 偏好低热量 | 连续购买热量 <100kcal/100g 商品 |
| preference_source | VARCHAR(255) | 默认USER_MANUAL | 偏好来源 | USER_MANUAL/SYSTEM_INFERRED/MIXED |
| inference_confidence | DECIMAL(3,2) | 默认0.0 | 推断置信度 | 基于购买一致性计算 |
| version | INT | 默认1 | 偏好版本 | 支持偏好变化追踪 |
| created_at | DATETIME | 非空 | 创建时间 | 数据审计 |
| updated_at | DATETIME | 非空 | 更新时间 | 数据审计 |

#### SCAN_HISTORY（扫描历史表）
**数据来源**：用户条形码扫描操作  
**作用**：记录用户兴趣，协同过滤辅助数据

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| scan_id | INT | PK 自增 | 扫描记录 ID | - |
| user_id | INT | FK 非空 | 用户 ID | 用户行为分析 |
| barcode | VARCHAR(255) | FK 可空 | 商品条码 | 兴趣商品记录 |
| scan_time | DATETIME | 非空 | 扫描时间 | 时间权重计算 |
| location | VARCHAR(255) | 可空 | 扫描地点 | 地理偏好分析 |
| allergen_detected | BOOLEAN | 默认FALSE | 是否检测到过敏原 | 用户安全意识评估 |
| scan_result | TEXT | 可空 | 扫描结果详情 | 扫描内容分析 |
| action_taken | VARCHAR(255) | 可空 | 后续行为 | 扫描-购买转化率 |
| scan_type | VARCHAR(255) | 可空 | 扫描类型 | 扫描场景分析 |
| recommendation_response | TEXT | 可空 | 推荐系统完整响应（JSON） | 推荐信息存储 |
| created_at | TIMESTAMP | 默认当前时间 | 创建时间 | 数据审计 |

**action_taken 枚举值**：unknown, purchased, avoided, no_action

#### PRODUCT_PREFERENCE（商品偏好表）
**数据来源**：用户在使用过程中手动设置  
**作用**：个性化推荐的精细调节

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| preference_id | INT | PK 自增 | 偏好记录 ID | - |
| user_id | INT | FK 非空 | 用户 ID | 用户偏好查询 |
| bar_code | VARCHAR(255) | FK 非空 | 商品条码 | 特定商品偏好 |
| preference_type | VARCHAR(50) | 非空 | 偏好类型 | 推荐权重调整 |
| reason | TEXT | 可空 | 设置原因 | 用户反馈分析 |
| created_at | TIMESTAMP | 默认当前时间 | 创建时间 | 数据审计 |

**preference_type 枚举值及影响权重**：
- `like`：推荐权重 × 1.5
- `dislike`：推荐权重 × 0.3
- `blacklist`：完全排除推荐

#### SUGAR_INTAKE_HISTORY（糖分摄入历史表）
**数据来源**：用户手动录入、扫描记录、小票解析  
**作用**：糖分摄入追踪和分析

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| id | VARCHAR(50) | PK | 记录ID（字符串，兼容UUID/雪花等） | 分布式ID支持 |
| user_id | INT | FK 非空 | 用户 ID | 用户糖分追踪 |
| food_name | VARCHAR(200) | 非空 | 食物名称 | 食物识别 |
| sugar_amount_mg | DECIMAL(10,2) | 非空 | 单个食品含糖量（毫克） | 基础糖分数据 |
| quantity | DECIMAL(8,2) | 非空 | 消费数量 | 实际摄入量计算因子 |
| consumed_at | TIMESTAMP | 非空 | 摄入时间 | 时间趋势分析 |
| barcode | VARCHAR(255) | FK 可空 | 商品条码（可选） | 商品关联 |
| created_at | TIMESTAMP | 默认当前时间 | 创建时间 | 数据审计 |

**表结构SQL**：
```sql
CREATE TABLE sugar_intake_history (
    id VARCHAR(50) PRIMARY KEY,              -- 记录ID（字符串，兼容UUID/雪花等）
    user_id INT NOT NULL,                    -- 用户ID
    food_name VARCHAR(200) NOT NULL,         -- 食物名称
    sugar_amount_mg DECIMAL(10,2) NOT NULL,  -- 单个食品含糖量
    quantity DECIMAL(8,2) NOT NULL,          -- 数量
    consumed_at TIMESTAMP NOT NULL,          -- 摄入时间
    barcode VARCHAR(255),                    -- 可选：商品条码
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (barcode) REFERENCES product(barcode) ON DELETE SET NULL,
    
    INDEX idx_user_date (user_id, consumed_at),
    INDEX idx_user_id (user_id),
    INDEX idx_sugar_intake_daily (user_id, DATE(consumed_at)),
    INDEX idx_sugar_intake_monthly (user_id, DATE_FORMAT(consumed_at, '%Y-%m')),
    INDEX idx_sugar_intake_food (user_id, food_name, consumed_at)
);
```

**计算逻辑**：
```sql
-- 实际糖分摄入计算
total_sugar_mg = sugar_amount_mg × quantity

-- 每日摄入统计
SELECT SUM(sugar_amount_mg * quantity) AS currentIntakeMg
FROM sugar_intake_history
WHERE user_id = ? AND DATE(consumed_at) = ?;

-- 进度百分比计算
progress_percentage = (currentIntakeMg / daily_goal_mg) × 100%

状态判断：
- <= 80%：'good'（绿色）
- 80%-100%：'warning'（橙色）
- > 100%：'over_limit'（红色）
```

### 4. 健康管理表

#### SUGAR_GOALS（糖分目标管理表）
**数据来源**：用户设置糖分摄入目标  

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| id | INT | PK 自增 | 目标ID | 主键标识 |
| user_id | INT | FK 非空 UNIQUE | 用户ID | 用户关联（一对一） |
| daily_goal_mg | DECIMAL(10,2) | 非空 | 日目标糖分摄入量（毫克） | 目标基准 |
| goal_level | VARCHAR(20) | 可空 | 目标等级 | 严格程度分类 |
| created_at | TIMESTAMP | 默认当前时间 | 创建时间 | 目标历史追踪 |
| updated_at | TIMESTAMP | 自动更新 | 更新时间 | 同步时间戳 |

**表结构SQL**：
```sql
CREATE TABLE sugar_goals (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    daily_goal_mg DECIMAL(10,2) NOT NULL,
    goal_level VARCHAR(20), -- 目标等级 ('Strict', 'Moderate', 'Relaxed', 'Custom')
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);
```

**goal_level 枚举值**：
- `Strict`：严格模式（600mg/天 = 0.6g）
- `Moderate`：适中模式（1000mg/天 = 1.0g）
- `Relaxed`：宽松模式（1500mg/天 = 1.5g）
- `Custom`：自定义模式（用户自定义数值）

**业务规则**：
- 每个用户只能有一个活跃的糖分目标
- 目标变更时，更新existing记录而非创建新记录
- goal_level用于数据分析、用户分群、个性化推荐摄入量（毫克） | 目标基准 |
| goal_level | VARCHAR(20) | 可空 | 目标等级 | 严格程度分类 |
| created_at | TIMESTAMP | 默认当前时间 | 创建时间 | 目标历史追踪 |
| updated_at | TIMESTAMP | 自动更新 | 更新时间 | 同步时间戳 |

**goal_level 枚举值**：
- `Strict`：严格模式（600mg/天 = 0.6g）
- `Moderate`：适中模式（1000mg/天 = 1.0g）
- `Relaxed`：宽松模式（1500mg/天 = 1.5g）
- `Custom`：自定义模式（用户自定义数值）

**业务规则**：
- 每个用户只能有一个活跃的糖分目标
- 目标变更时，更新existing记录而非创建新记录
- goal_level用于数据分析、用户分群、个性化推荐

#### MONTHLY_STATISTICS（月度统计缓存表）
**数据来源**：定时任务基于用户行为数据计算生成  

| 字段名 | 数据类型 | 约束 | 说明 | 前端对应 |
|--------|----------|------|------|---------|
| stat_id | INT | PK 自增 | 统计ID | 主键标识 |
| user_id | INT | FK 非空 | 用户ID | 用户关联 |
| year | INT | 可空 | 年份 | 时间维度 |
| month | INT | 可空 | 月份 | 时间维度 |
| receipt_uploads | INT | 可空 | 收据上传数量 | Receipt Uploads: 18 times |
| total_products | INT | 可空 | 总产品数 | Products Purchased: 156 items |
| total_spent | DECIMAL(10,2) | 可空 | 总花费金额 | Total Spent: $487.50 |
| category_breakdown | TEXT | 可空 | 类别分解统计（JSON） | Purchase Summary百分比 |
| popular_products | TEXT | 可空 | 热门产品列表（JSON） | Top Products列表 |
| nutrition_breakdown | TEXT | 可空 | 营养分解数据（JSON） | Nutrition Insights百分比和状态 |
| calculated_at | DATETIME | 可空 | 计算时间 | 缓存时效性 |
| updated_at | DATETIME | 可空 | 更新时间 | 数据同步 |

### 5. 购买行为表

#### PURCHASE_RECORD（购买记录表）
**数据来源**：用户上传小票，OCR 解析生成  
**作用**：提供购买行为的时间和地点信息

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| purchase_id | INT | PK 自增 | 购买记录 ID | 购买明细关联 |
| user_id | INT | FK 非空 | 用户 ID | 用户购买历史 |
| receipt_date | DATE | 可空 | 小票日期 | 时间权重计算 |
| store_name | VARCHAR(255) | 可空 | 购买商店 | 地理偏好分析 |
| total_amount | FLOAT | 可空 | 总金额 | 消费能力评估 |
| ocr_confidence | FLOAT | 可空 | OCR 解析置信度 | 数据质量评估 |
| raw_ocr_data | TEXT | 可空 | 原始 OCR 数据 | 调试和优化 |
| scan_id | INT | FK 可空 | 关联扫描记录 | 扫描-购买关联 |

#### PURCHASE_ITEM（购买商品明细表）
**数据来源**：PURCHASE_RECORD 商品明细，通过商品名匹配到 PRODUCT 表  
**作用**：协同过滤算法核心数据，构建用户-商品购买矩阵

| 字段名 | 数据类型 | 约束 | 说明 | 算法用途 |
|--------|----------|------|------|---------|
| item_id | INT | PK 自增 | 明细记录 ID | - |
| purchase_id | INT | FK 非空 | 购买记录 ID | 购买关联 |
| barcode | VARCHAR(255) | FK 非空 | 商品条码 | 商品识别 |
| item_name_ocr | VARCHAR(255) | 可空 | OCR 识别商品名 | 匹配验证 |
| match_confidence | FLOAT | 可空 | 商品名匹配置信度 | 数据质量 |
| quantity | INT | 可空 | 购买数量 | 协同过滤权重 |
| unit_price | FLOAT | 可空 | 单价 | 价格敏感度 |
| total_price | FLOAT | 可空 | 总价 | 消费分析 |
| estimated_servings | FLOAT | 可空 | 估算食用份数 | 营养计算基准 |
| total_calories | FLOAT | 可空 | 总热量贡献 | 营养比例分析 |
| total_proteins | FLOAT | 可空 | 总蛋白质贡献 | 蛋白质摄入分析 |
| total_carbs | FLOAT | 可空 | 总碳水贡献 | 碳水摄入分析 |
| total_fat | FLOAT | 可空 | 总脂肪贡献 | 脂肪摄入分析 |

### 6. 系统日志表

#### RECOMMENDATION_LOG（推荐日志表）
**数据来源**：每次推荐 API 调用生成  
**作用**：算法性能分析和用户行为分析

| 字段名 | 数据类型 | 约束 | 说明 | 用途 |
|--------|----------|------|------|------|
| log_id | INT | PK 自增 | 日志记录 ID | - |
| user_id | INT | FK 非空 | 用户 ID | 用户行为分析 |
| request_barcode | VARCHAR(255) | 可空 | 原商品条码 | 推荐场景分析 |
| request_type | VARCHAR(255) | 非空 | 推荐类型 | 算法类型统计 |
| recommended_products | TEXT | 可空 | 推荐商品列表 JSON | 推荐结果分析 |
| algorithm_version | VARCHAR(255) | 默认v1.0 | 算法版本 | A/B 测试支持 |
| llm_prompt | TEXT | 可空 | LLM 输入 prompt | prompt 优化 |
| llm_response | TEXT | 可空 | LLM 原始响应 | 响应质量分析 |
| llm_analysis | TEXT | 可空 | 解析后分析结果 | 最终输出记录 |
| processing_time_ms | INT | 可空 | 处理耗时 | 性能监控 |
| total_candidates | INT | 可空 | 候选商品总数 | 算法效果评估 |
| filtered_candidates | INT | 可空 | 过滤后候选数 | 过滤效果评估 |
| created_at | TIMESTAMP | 默认当前时间 | 创建时间 | 数据审计 |

---

## API字段映射设计

### 数据库与接口字段映射规则

为确保前后端接口的顺畅对接，采用以下映射策略：

#### 1. 字段命名映射
**数据库层（Liquibase命名）** ↔ **接口层（驼峰命名）**

| 数据库字段 | 接口字段 | 映射说明 |
|-----------|----------|----------|
| barcode | barcode | 商品条码统一使用 |
| name | productName | 商品名称映射 |
| username | userName | 用户名映射 |
| food_name | foodName | 食物名称映射 |
| sugar_amount_mg | sugarAmount | 糖分含量映射 |
| intake_time | intakeTime | 摄入时间映射 |
| source_type | sourceType | 来源类型映射 |
| serving_size | servingSize | 份量大小映射 |
| quantity | quantity | 数量字段保持一致 |

#### 2. 后端映射实现示例

```java
// Spring Boot 实体类字段映射
@Entity
@Table(name = "product")
public class Product {
    @Id
    @Column(name = "barcode")
    @JsonProperty("barcode")
    private String barcode;
    
    @Column(name = "name")
    @JsonProperty("productName")
    private String name;
    
    @Column(name = "sugars_100g")
    @JsonProperty("sugars100g")
    private Float sugars100g;
}

// 糖分摄入历史实体类
@Entity
@Table(name = "sugar_intake_history")
public class SugarIntakeHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "intake_id")
    @JsonProperty("intakeId")
    private Integer intakeId;
    
    @Column(name = "food_name")
    @JsonProperty("foodName")
    private String foodName;
    
    @Column(name = "sugar_amount_mg")
    @JsonProperty("sugarAmount")
    private Float sugarAmountMg;
    
    @Column(name = "intake_time")
    @JsonProperty("intakeTime")
    private LocalDateTime intakeTime;
    
    @Column(name = "source_type")
    @JsonProperty("sourceType")
    private String sourceType;
    
    @Column(name = "serving_size")
    @JsonProperty("servingSize")
    private String servingSize;
    
    @Column(name = "quantity")
    @JsonProperty("quantity")
    private Float quantity;
}
```

#### 3. 前端适配处理

```javascript
// 前端请求数据转换
const apiClient = {
    // 创建糖分记录
    async createSugarRecord(data) {
        const response = await fetch('/api/sugar-intake-history', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                foodName: data.foodName,      // 接口使用驼峰命名
                sugarAmount: data.sugarAmount,
                intakeTime: data.intakeTime,
                sourceType: data.sourceType,
                barcode: data.barcode,
                servingSize: data.servingSize,
                quantity: data.quantity || 1.0
            })
        });
        return response.json();
    },
    
    // 获取产品信息
    async getProduct(barcode) {
        const response = await fetch(`/api/products/${barcode}`);
        const data = await response.json();
        return {
            barcode: data.barcode,           // 后端自动映射字段
            productName: data.productName,
            brand: data.brand,
            sugars100g: data.sugars100g
        };
    }
};
```

---

## 业务流程设计

### 收据扫描完整流程

```
用户上传收据图片
    ↓
创建 SCAN_HISTORY（scan_type = 'receipt'）
    ↓
OCR 解析收据内容
    ↓
创建 PURCHASE_RECORD（关联scan_id）
    ↓
为每个识别的商品：
  - 创建 SCAN_HISTORY（scan_type = 'barcode'）
  - 调用推荐系统获取推荐响应
  - 存储推荐响应到recommendation_response
    ↓
创建 PURCHASE_ITEM 记录
    ↓
自动生成 SUGAR_INTAKE_HISTORY（基于购买商品）
    ↓
更新用户偏好和月度统计
```

### 糖分跟踪流程

```
用户手动添加糖分记录
    ↓
创建 SUGAR_INTAKE_HISTORY
    ↓
实时计算当日摄入总量
    ↓
对比糖分目标，计算进度和状态
    ↓
更新前端显示
```

### 月度统计生成流程

```
定时任务触发（每月1日）
    ↓
基于PURCHASE_RECORD计算基础统计
    ↓
分析商品类别分布
    ↓
计算营养摄入比例
    ↓
生成热门产品列表
    ↓
存储到MONTHLY_STATISTICS
```

---

## API接口映射

### 糖分跟踪相关API
```
GET /user/{userId}/sugar-tracking/daily/{date} 
    -> 查询：SUGAR_INTAKE_HISTORY (WHERE DATE(consumed_at) = date)
    -> 关联：SUGAR_GOALS (获取用户目标和goal_level)
    -> 计算：currentIntakeMg = SUM(sugar_amount_mg × quantity)
    -> 统计：topContributors（贡献最大的5个食物）

POST /user/{userId}/sugar-tracking/record 
    -> 插入：SUGAR_INTAKE_HISTORY 表
    -> 字段映射：foodName → food_name, sugarAmount → sugar_amount_mg
    -> ID生成：支持UUID/雪花ID等分布式ID

DELETE /user/{userId}/sugar-tracking/record/{recordId} 
    -> 删除：SUGAR_INTAKE_HISTORY WHERE id = recordId

GET /user/{userId}/sugar-tracking/goal 
    -> 查询：SUGAR_GOALS WHERE user_id = userId
    -> 返回：daily_goal_mg, goal_level

PUT /user/{userId}/sugar-tracking/goal 
    -> 更新：SUGAR_GOALS 目标记录（UPDATE模式，非INSERT）
    -> 支持：goal_level字段更新

GET /user/{userId}/sugar-tracking/history 
    -> 历史统计查询：按日期分组的糖分摄入统计
    -> 计算：averageDailyIntake, totalIntake, goalAchievementRate

GET /sugar-tracking/{userId}/monthly 
    -> 月度统计：topFoodContributors, weeklyTrends
    -> 聚合查询：食物贡献排名、周趋势分析
```

### 历史记录相关API
```
GET /user/{userId}/history 
    -> 查询：SCAN_HISTORY 关联 PRODUCT
    -> 字段映射：barcode → barcode, name → productName

GET /user/{userId}/history/{historyId} 
    -> 查询：SCAN_HISTORY WHERE scan_id = historyId
    -> 关联：PRODUCT 获取完整商品信息

DELETE /user/{userId}/history/{historyId} 
    -> 删除：SCAN_HISTORY WHERE scan_id = historyId

GET /user/{userId}/history/statistics 
    -> 聚合查询：基于SCAN_HISTORY的统计计算
```

### 月度概览相关API
```
GET /user/{userId}/monthly/overview/{year}/{month} 
    -> 查询：MONTHLY_STATISTICS WHERE year = {year} AND month = {month}

GET /user/{userId}/monthly/purchases/{year}/{month} 
    -> 解析：MONTHLY_STATISTICS.category_breakdown + popular_products JSON

GET /user/{userId}/monthly/nutrition/{year}/{month} 
    -> 解析：MONTHLY_STATISTICS.nutrition_breakdown JSON
```

---

## 索引优化策略

### 核心查询优化
```sql
-- 糖分跟踪相关索引（使用正确的表名）
CREATE INDEX idx_sugar_intake_user_date ON sugar_intake_history(user_id, consumed_at);
CREATE INDEX idx_sugar_intake_user_id ON sugar_intake_history(user_id);
CREATE INDEX idx_sugar_goals_user_id ON sugar_goals(user_id);

-- 每日糖分统计优化查询
CREATE INDEX idx_sugar_intake_daily ON sugar_intake_history(user_id, DATE(consumed_at));

-- 月度统计优化查询  
CREATE INDEX idx_sugar_intake_monthly ON sugar_intake_history(user_id, DATE_FORMAT(consumed_at, '%Y-%m'));

-- 食物贡献分析优化
CREATE INDEX idx_sugar_intake_food ON sugar_intake_history(user_id, food_name, consumed_at);

-- 历史记录查询索引
CREATE INDEX idx_scan_user_type_time ON scan_history(user_id, scan_type, scan_time DESC);
CREATE INDEX idx_scan_barcode ON scan_history(barcode);

-- 月度统计索引
CREATE INDEX idx_monthly_stats_user_date ON monthly_statistics(user_id, year DESC, month DESC);

-- 推荐算法核心索引
CREATE INDEX idx_user_allergen_confirmed ON user_allergen(user_id, confirmed);
CREATE INDEX idx_product_allergen_presence ON product_allergen(allergen_id, presence_type);
CREATE INDEX idx_category_nutrition ON product(category, energy_kcal_100g, proteins_100g);

-- 产品查询优化
CREATE INDEX idx_product_barcode ON product(barcode);
CREATE INDEX idx_product_name_search ON product(name);
CREATE INDEX idx_product_category ON product(category);

-- 用户偏好索引
CREATE INDEX idx_user_preference_source ON user_preference(preference_source);
CREATE INDEX idx_user_preference_version ON user_preference(user_id, version);

-- 产品偏好索引
CREATE INDEX idx_product_preference_user_id ON product_preference(user_id);
CREATE INDEX idx_product_preference_bar_code ON product_preference(bar_code);
CREATE INDEX idx_product_preference_type ON product_preference(preference_type);

-- 全文搜索索引
CREATE FULLTEXT INDEX idx_product_ingredients ON product(ingredients);
CREATE FULLTEXT INDEX idx_product_allergens ON product(allergens);
```

---

## 数据完整性约束

### 业务规则约束
```sql
-- 用户生理数据合理性检查
ALTER TABLE user ADD CONSTRAINT chk_user_physical 
CHECK (age IS NULL OR (age BETWEEN 13 AND 120));

ALTER TABLE user ADD CONSTRAINT chk_user_height 
CHECK (height_cm IS NULL OR (height_cm BETWEEN 100 AND 250));

ALTER TABLE user ADD CONSTRAINT chk_user_weight 
CHECK (weight_kg IS NULL OR (weight_kg BETWEEN 30 AND 300));

-- 糖分数据合理性检查
ALTER TABLE sugar_intake_history ADD CONSTRAINT chk_sugar_positive 
CHECK (sugar_amount_mg >= 0 AND quantity > 0);

ALTER TABLE sugar_intake_history ADD CONSTRAINT chk_intake_time_reasonable 
CHECK (intake_time <= NOW());

ALTER TABLE sugar_goals ADD CONSTRAINT chk_goal_reasonable 
CHECK (daily_goal_mg BETWEEN 100 AND 5000);

-- 营养数据合理性检查
ALTER TABLE product ADD CONSTRAINT chk_nutrition_positive 
CHECK (energy_kcal_100g IS NULL OR energy_kcal_100g >= 0);

ALTER TABLE product ADD CONSTRAINT chk_proteins_positive 
CHECK (proteins_100g IS NULL OR proteins_100g >= 0);

-- 月度统计数据合理性
ALTER TABLE monthly_statistics ADD CONSTRAINT chk_month_valid 
CHECK (month BETWEEN 1 AND 12 AND year BETWEEN 2020 AND 2050);

-- 扫描历史时间合理性
ALTER TABLE scan_history ADD CONSTRAINT chk_scan_time_reasonable
CHECK (scan_time <= NOW());

-- 用户偏好约束
ALTER TABLE user_preference ADD CONSTRAINT chk_preference_source 
CHECK (preference_source IN ('USER_MANUAL', 'SYSTEM_INFERRED', 'MIXED'));

ALTER TABLE user_preference ADD CONSTRAINT chk_inference_confidence 
CHECK (inference_confidence >= 0.0 AND inference_confidence <= 1.0);

-- 糖分摄入源类型约束
ALTER TABLE sugar_intake_history ADD CONSTRAINT chk_source_type 
CHECK (source_type IN ('scan', 'manual', 'receipt'));
```

### 外键约束
```sql
-- 确保外键关系完整性（使用正确的表名）
ALTER TABLE user_allergen 
ADD CONSTRAINT fk_user_allergen_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE user_allergen 
ADD CONSTRAINT fk_user_allergen_allergen 
FOREIGN KEY (allergen_id) REFERENCES allergen(allergen_id) ON DELETE CASCADE;

ALTER TABLE product_allergen 
ADD CONSTRAINT fk_product_allergen_product 
FOREIGN KEY (barcode) REFERENCES product(barcode) ON DELETE CASCADE;

ALTER TABLE sugar_intake_history 
ADD CONSTRAINT fk_sugar_intake_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE sugar_intake_history 
ADD CONSTRAINT fk_sugar_intake_product 
FOREIGN KEY (barcode) REFERENCES product(barcode) ON DELETE SET NULL;

ALTER TABLE scan_history 
ADD CONSTRAINT fk_scan_history_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE scan_history 
ADD CONSTRAINT fk_scan_history_product 
FOREIGN KEY (barcode) REFERENCES product(barcode) ON DELETE SET NULL;

ALTER TABLE user_preference 
ADD CONSTRAINT fk_user_preference_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE product_preference 
ADD CONSTRAINT fk_product_preference_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE product_preference 
ADD CONSTRAINT fk_product_preference_product 
FOREIGN KEY (bar_code) REFERENCES product(barcode) ON DELETE CASCADE;

ALTER TABLE sugar_goals 
ADD CONSTRAINT fk_sugar_goals_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE monthly_statistics 
ADD CONSTRAINT fk_monthly_stats_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE purchase_record 
ADD CONSTRAINT fk_purchase_record_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;

ALTER TABLE purchase_item 
ADD CONSTRAINT fk_purchase_item_purchase 
FOREIGN KEY (purchase_id) REFERENCES purchase_record(purchase_id) ON DELETE CASCADE;

ALTER TABLE purchase_item 
ADD CONSTRAINT fk_purchase_item_product 
FOREIGN KEY (barcode) REFERENCES product(barcode) ON DELETE CASCADE;

ALTER TABLE recommendation_log 
ADD CONSTRAINT fk_recommendation_log_user 
FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE;
```

### 唯一约束
```sql
-- 糖分目标唯一约束（更新为新表结构）
ALTER TABLE sugar_goals 
ADD CONSTRAINT uk_sugar_goals_user_id 
UNIQUE (user_id);

-- 产品偏好唯一约束
ALTER TABLE product_preference 
ADD CONSTRAINT uk_product_preference_user_product 
UNIQUE (user_id, bar_code);

-- 用户偏好唯一约束
ALTER TABLE user_preference 
ADD CONSTRAINT uk_user_preference_user_id 
UNIQUE (user_id);
```

### 触发器机制
```sql
-- 糖分记录时间验证触发器（使用正确的表名）
DELIMITER //
CREATE TRIGGER tr_sugar_intake_validation
    BEFORE INSERT ON sugar_intake_history
    FOR EACH ROW
BEGIN
    IF NEW.consumed_at > NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Consumed time cannot be in the future';
    END IF;
    
    -- 确保数量为正数
    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than 0';
    END IF;
    
    -- 确保糖分含量为非负数
    IF NEW.sugar_amount_mg < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sugar amount cannot be negative';
    END IF;
END//
DELIMITER ;

-- 糖分目标更新触发器
DELIMITER //
CREATE TRIGGER tr_sugar_goal_update
    BEFORE UPDATE ON sugar_goals
    FOR EACH ROW
BEGIN
    -- 自动更新updated_at字段
    SET NEW.updated_at = CURRENT_TIMESTAMP;
    
    -- 验证目标合理性
    IF NEW.daily_goal_mg < 100 OR NEW.daily_goal_mg > 5000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Daily goal must be between 100-5000mg';
    END IF;
END//
DELIMITER ;
```

---

## 数据质量监控

### 监控视图
```sql
-- 数据质量监控视图（更新为新表结构）
CREATE VIEW v_data_quality_metrics AS
SELECT 
    'products_without_nutrition' as metric,
    COUNT(*) as value,
    NOW() as checked_at
FROM product 
WHERE energy_kcal_100g IS NULL
UNION ALL
SELECT 
    'products_without_category' as metric,
    COUNT(*),
    NOW()
FROM product 
WHERE category IS NULL OR category = ''
UNION ALL
SELECT 
    'users_without_goals' as metric,
    COUNT(*),
    NOW()
FROM user 
WHERE nutrition_goal IS NULL
UNION ALL
SELECT 
    'sugar_records_without_barcode' as metric,
    COUNT(*),
    NOW()
FROM sugar_records 
WHERE barcode IS NULL
UNION ALL
SELECT 
    'users_without_sugar_goals' as metric,
    COUNT(*),
    NOW()
FROM user u
LEFT JOIN sugar_goals sg ON u.user_id = sg.user_id
WHERE sg.user_id IS NULL
UNION ALL
SELECT 
    'sugar_records_invalid_quantity' as metric,
    COUNT(*),
    NOW()
FROM sugar_records 
WHERE quantity IS NULL OR quantity <= 0;
```

### 性能监控查询（更新为新表结构）
```sql
-- 查询性能监控
CREATE VIEW v_performance_metrics AS
SELECT 
    'avg_sugar_records_per_user' as metric,
    AVG(record_count) as value,
    NOW() as checked_at
FROM (
    SELECT user_id, COUNT(*) as record_count
    FROM sugar_records 
    WHERE consumed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY user_id
) subquery
UNION ALL
SELECT 
    'avg_scans_per_user_daily' as metric,
    AVG(scan_count),
    NOW()
FROM (
    SELECT user_id, COUNT(*) as scan_count
    FROM scan_history 
    WHERE scan_time >= DATE_SUB(NOW(), INTERVAL 1 DAY)
    GROUP BY user_id
) subquery
UNION ALL
SELECT 
    'recommendation_log_processing_time' as metric,
    AVG(processing_time_ms),
    NOW()
FROM recommendation_log 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
UNION ALL
SELECT 
    'daily_sugar_tracking_usage' as metric,
    COUNT(DISTINCT user_id),
    NOW()
FROM sugar_records 
WHERE DATE(consumed_at) = CURDATE()
UNION ALL
SELECT 
    'avg_foods_per_day' as metric,
    AVG(food_count),
    NOW()
FROM (
    SELECT user_id, DATE(consumed_at) as date, COUNT(*) as food_count
    FROM sugar_records 
    WHERE consumed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY user_id, DATE(consumed_at)
) daily_foods;
```

---

## 部署策略

### 分阶段部署计划

#### 第一阶段：字段统一验证（1天）
```sql
-- 验证现有表字段是否与Liquibase一致
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME IN ('product', 'user', 'sugar_intake_history')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

#### 第二阶段：糖分追踪表结构调整（2-3天）
```sql
-- 检查现有表结构是否符合糖分追踪设计方案
-- 确保使用 sugar_intake_history 表名

-- 方案1：如果当前表名不是sugar_intake_history，进行重命名
-- RENAME TABLE existing_table_name TO sugar_intake_history;

-- 方案2：创建符合设计方案的sugar_intake_history表
CREATE TABLE sugar_intake_history (
    id VARCHAR(50) PRIMARY KEY,              -- 字符串ID支持分布式
    user_id INT NOT NULL,                    
    food_name VARCHAR(200) NOT NULL,         
    sugar_amount_mg DECIMAL(10,2) NOT NULL,  -- 精确的小数类型
    quantity DECIMAL(8,2) NOT NULL,          -- 精确的数量
    consumed_at TIMESTAMP NOT NULL,          -- 摄入时间
    barcode VARCHAR(255),                    -- 可选条码
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    FOREIGN KEY (barcode) REFERENCES product(barcode) ON DELETE SET NULL,
    
    INDEX idx_user_date (user_id, consumed_at),
    INDEX idx_user_id (user_id),
    INDEX idx_sugar_intake_daily (user_id, DATE(consumed_at)),
    INDEX idx_sugar_intake_monthly (user_id, DATE_FORMAT(consumed_at, '%Y-%m')),
    INDEX idx_sugar_intake_food (user_id, food_name, consumed_at)
);

-- 数据迁移（如果需要从其他表迁移数据）
-- INSERT INTO sugar_intake_history (id, user_id, food_name, sugar_amount_mg, quantity, consumed_at, barcode, created_at)
-- SELECT ... FROM old_table_name;

-- 方案3：调整sugar_goals表结构
ALTER TABLE sugar_goals 
MODIFY COLUMN daily_goal_mg DECIMAL(10,2) NOT NULL;

ALTER TABLE sugar_goals 
MODIFY COLUMN goal_level VARCHAR(20);

-- 添加唯一约束确保每用户一个目标
ALTER TABLE sugar_goals 
ADD CONSTRAINT uk_sugar_goals_user_id UNIQUE (user_id);

-- 更新goal_level枚举值为符合设计方案的格式
UPDATE sugar_goals SET goal_level = 'Strict' WHERE goal_level IN ('strict', 'Strict');
UPDATE sugar_goals SET goal_level = 'Moderate' WHERE goal_level IN ('moderate', 'Moderate');  
UPDATE sugar_goals SET goal_level = 'Relaxed' WHERE goal_level IN ('relaxed', 'Relaxed');
UPDATE sugar_goals SET goal_level = 'Custom' WHERE goal_level NOT IN ('Strict', 'Moderate', 'Relaxed');

-- 为现有用户创建默认糖分目标（如果不存在）
INSERT INTO sugar_goals (user_id, daily_goal_mg, goal_level)
SELECT 
    user_id, 
    CASE nutrition_goal
        WHEN 'lose_weight' THEN 600.00
        WHEN 'gain_muscle' THEN 1200.00
        WHEN 'maintain' THEN 1000.00
        ELSE 1000.00
    END,
    'Moderate'
FROM user 
WHERE user_id NOT IN (SELECT DISTINCT user_id FROM sugar_goals);
```

#### 第三阶段：索引和约束优化（3-4天）
```sql
-- 创建所有优化索引
-- 执行前面定义的所有CREATE INDEX语句

-- 添加所有约束条件
-- 执行前面定义的所有约束语句

-- 创建触发器
-- 执行前面定义的所有触发器
```

#### 第四阶段：API接口路径调整（4-5天）
```sql
-- 验证sugar_intake_history表数据完整性
SELECT COUNT(*) as total_records FROM sugar_intake_history;
SELECT COUNT(*) as users_with_goals FROM sugar_goals;
SELECT COUNT(DISTINCT user_id) as active_users FROM sugar_intake_history 
WHERE consumed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY);

-- 验证sugar_intake_history表约束和索引
SHOW INDEX FROM sugar_intake_history;
SHOW INDEX FROM sugar_goals;

-- 测试核心查询性能
EXPLAIN SELECT SUM(sugar_amount_mg * quantity) as daily_intake 
FROM sugar_intake_history 
WHERE user_id = 1 AND DATE(consumed_at) = CURDATE();

EXPLAIN SELECT sih.food_name, sih.sugar_amount_mg, sih.quantity, sih.consumed_at
FROM sugar_intake_history sih
WHERE sih.user_id = 1 AND DATE(sih.consumed_at) = CURDATE()
ORDER BY (sih.sugar_amount_mg * sih.quantity) DESC
LIMIT 5;
```

### API接口调整清单

#### 后端Controller调整
```java
// 原接口路径调整
@PostMapping("/users/{userId}/sugar/records")  // 旧路径
↓
@PostMapping("/users/{userId}/sugar-tracking/record")  // 新路径

@GetMapping("/users/{userId}/sugar/daily")  // 旧路径  
↓
@GetMapping("/users/{userId}/sugar-tracking/daily/{date}")  // 新路径

@DeleteMapping("/users/{userId}/sugar/record/{id}")  // 旧路径
↓  
@DeleteMapping("/users/{userId}/sugar-tracking/record/{recordId}")  // 新路径
```

#### 实体类字段调整
```java
// 糖分摄入历史实体类调整
@Entity
@Table(name = "sugar_intake_history")  // 使用正确的表名
public class SugarIntakeHistory {
    @Id
    @Column(name = "id")  // 字符串ID
    private String id;
    
    @Column(name = "consumed_at")  // 字段名更新
    @JsonProperty("consumedAt")
    private LocalDateTime consumedAt;
    
    @Column(name = "sugar_amount_mg", precision = 10, scale = 2)  // 精确类型
    @JsonProperty("sugarAmount")
    private BigDecimal sugarAmountMg;
    
    @Column(name = "quantity", precision = 8, scale = 2)  // 精确类型
    @JsonProperty("quantity")
    private BigDecimal quantity;
}

// 糖分目标实体类调整
@Entity
@Table(name = "sugar_goals")
public class SugarGoal {
    @Column(name = "goal_level")
    @Enumerated(EnumType.STRING)
    @JsonProperty("goalLevel")
    private GoalLevel goalLevel;  // Strict, Moderate, Relaxed, Custom
    
    @Column(name = "daily_goal_mg", precision = 10, scale = 2)
    @JsonProperty("dailyGoalMg")
    private BigDecimal dailyGoalMg;
}
```

### 回滚预案
```sql
-- 字段回滚（谨慎执行）
-- ALTER TABLE sugar_intake_history DROP COLUMN quantity;
-- ALTER TABLE sugar_goals DROP COLUMN is_active;

-- 索引删除
-- DROP INDEX IF EXISTS idx_sugar_intake_user_time;
-- DROP INDEX IF EXISTS idx_sugar_goals_active;
-- (其他索引删除语句)

-- 触发器删除
-- DROP TRIGGER IF EXISTS tr_sugar_goal_activate;
-- DROP TRIGGER IF EXISTS tr_sugar_intake_validation;

-- 约束删除
-- ALTER TABLE sugar_intake_history DROP CONSTRAINT chk_sugar_positive;
-- ALTER TABLE sugar_goals DROP CONSTRAINT chk_goal_reasonable;
-- (其他约束删除语句)
```

---

## 与Liquibase实现的兼容性

### 已统一的命名规范

1. **表名统一**：全部使用Liquibase中的小写下划线命名
2. **字段名统一**：
   - 商品字段：`barcode`, `name`
   - 用户字段：`username`, `created_at`, `updated_at`
   - 糖分字段：`intake_id`, `intake_time`, `source_type`

3. **数据类型统一**：遵循Liquibase的类型定义
4. **约束命名统一**：遵循`chk_`, `fk_`, `uk_`前缀规范

### 需要补充的功能

1. **quantity字段**：为sugar_intake_history表添加数量字段
2. **is_active字段**：为sugar_goals表添加激活状态字段
3. **完善约束**：添加业务规则验证约束
4. **优化索引**：添加高性能查询索引
5. **触发器**：自动化数据一致性维护

### API兼容性保证

通过Spring Boot的@JsonProperty注解确保：
- 数据库层使用Liquibase命名规范
- API层提供驼峰命名接口
- 前后端无缝对接

---

## 总结

### 主要统一改进点

1. **糖分追踪表结构优化**：
   - 统一使用 `sugar_records` 表名，消除重复表问题
   - 采用字符串ID主键，支持分布式ID生成（UUID/雪花ID）
   - 使用 DECIMAL 精确数据类型，避免浮点数精度问题
   - 字段名调整：`consumed_at` 替代 `intake_time`
   - 移除 `source_type`、`serving_size` 等非核心字段，简化设计

2. **糖分目标管理优化**：
   - 每用户仅一个目标，通过 UNIQUE 约束保证唯一性
   - 移除 `is_active` 字段，简化业务逻辑
   - `goal_level` 枚举值标准化：Strict/Moderate/Relaxed/Custom
   - 支持目标等级用于数据分析和用户分群

3. **API接口路径统一**：
   - 统一使用 `/sugar-tracking/` 路径前缀
   - 接口参数命名标准化：`recordId`、`date` 等
   - 支持更丰富的统计功能：历史趋势、月度分析

4. **索引优化策略**：
   - 针对糖分追踪的专用复合索引
   - 支持日统计、月统计、食物贡献分析的高效查询
   - 分布式查询友好的索引设计

5. **数据完整性保障**：
   - 完善的约束条件：数值范围、时间合理性检查
   - 触发器自动验证：时间、数量、糖分含量合理性
   - goal_level 枚举值约束确保数据一致性

### 技术优势

- **分布式友好**：字符串ID支持多种分布式ID生成策略
- **精确计算**：DECIMAL类型避免浮点数误差
- **高性能查询**：专门的复合索引优化统计查询
- **简化业务逻辑**：一对一目标关系，避免复杂的激活状态管理
- **扩展性强**：goal_level支持未来更多目标等级和个性化设置

### 业务价值

- **精确的糖分追踪**：支持小数数量和精确的含糖量计算
- **灵活的目标管理**：四种预设等级 + 自定义模式
- **丰富的统计分析**：日/周/月多维度统计，食物贡献排名
- **用户体验提升**：简化的API接口，更直观的数据结构
- **数据驱动决策**：goal_level支持用户行为分析和个性化推荐

该优化设计完全基于糖分追踪专项设计方案，通过统一表结构、简化业务逻辑、优化索引策略，实现了更高效、更精确的糖分追踪功能。同时保持了与现有系统的兼容性，支持平滑迁移和渐进式升级。