# Grocery Guardian 数据库开发报告

## 项目概述

**项目名称**：Grocery Guardian - AI 驱动的杂货购物助手  
**数据库用途**：支持个性化商品推荐、过敏原检测、营养分析和用户偏好学习  
**核心特性**：基于用户行为的动态偏好推断、实时推荐算法、LLM 驱动的个性化分析  


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

3. **营养分析策略**
   - 减脂策略：优先低热量、高纤维商品
   - 增肌策略：优先高蛋白、适量碳水商品
   - 维持策略：追求营养均衡的商品组合

4. **数据处理流程**
   - 不追踪绝对摄入量，关注营养成分比例
   - 购买数量影响推荐权重
   - 时间衰减因子：近期购买权重更高

### 数据来源定义

- **预输入数据**：OpenFood API 商品数据（75,000+ 爱尔兰市场商品）
- **用户输入数据**：注册信息（身高、体重、年龄、性别、营养目标）
- **动态生成数据**：扫描记录、购买记录、偏好推断、推荐日志

---

## 数据库架构设计

### 整体架构原则

1. **以 barcode 为全局主键**：确保商品数据的一致性和完整性
2. **层次化数据结构**：基础数据 → 关联数据 → 行为数据 → 分析结果
3. **支持动态偏好推断**：通过购买行为自动更新用户偏好
4. **优化查询性能**：针对推荐算法的频繁查询进行索引优化

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
USER → SCAN_HISTORY → PRODUCT
USER → PURCHASE_RECORD → PURCHASE_ITEM → PRODUCT
USER → PRODUCT_PREFERENCE → PRODUCT
USER → RECOMMENDATION_LOG
```

---

## 数据表详细设计

### 1. 基础数据表

#### PRODUCT（商品表）
**数据来源**：OpenFood API 预处理导入  
**更新频率**：批量更新，每周/月同步一次  

| 字段名 | 类型 | 说明 | 推荐算法用途 |
|--------|------|------|-------------|
| barcode | VARCHAR(20) PK | 商品唯一标识 | 商品关联主键 |
| name | VARCHAR(200) | 商品名称 | OCR 匹配，用户搜索 |
| brand | VARCHAR(100) | 品牌名称 | 品牌偏好分析 |
| ingredients | TEXT | 成分列表 | LLM 分析，过敏原检测 |
| allergens | TEXT | 过敏原信息 | 过敏原提取源数据 |
| energy_100g | FLOAT | 能量值（焦耳） | 营养计算辅助 |
| energy_kcal_100g | FLOAT | 热量（卡路里） | 减脂目标核心指标 |
| fat_100g | FLOAT | 脂肪含量 | 减脂策略筛选 |
| saturated_fat_100g | FLOAT | 饱和脂肪 | 健康评分计算 |
| carbohydrates_100g | FLOAT | 碳水化合物 | 增肌策略评估 |
| sugars_100g | FLOAT | 糖分含量 | 低糖偏好筛选 |
| proteins_100g | FLOAT | 蛋白质含量 | 增肌目标优先指标 |
| serving_size | VARCHAR(50) | 建议食用份量 | 营养计算基准 |
| category | VARCHAR(50) | 商品类别 | 同类商品推荐关键字段 |

**索引策略**：
- `idx_name_fuzzy`：支持 OCR 商品名模糊匹配
- `idx_brand`：品牌筛选优化
- `idx_category`：商品分类筛选（推荐算法核心）
- `FULLTEXT idx_ingredients`：成分文本搜索
- `FULLTEXT idx_allergens`：过敏原文本搜索

#### USER（用户表）
**数据来源**：用户注册时填写  
**更新频率**：用户主动更新个人信息  

| 字段名 | 类型 | 说明 | 算法用途 |
|--------|------|------|---------|
| user_id | INT PK | 用户唯一标识 | 所有关联表外键 |
| username | VARCHAR(50) | 用户名 | 用户识别 |
| email | VARCHAR(100) | 邮箱 | 用户识别 |
| password_hash | VARCHAR(255) | 密码哈希 | 身份验证 |
| age | INT | 年龄 | BMR 计算 |
| gender | ENUM | 性别 | BMR 性别系数 |
| height_cm | INT | 身高 | BMR 计算 |
| weight_kg | FLOAT | 体重 | BMR 和需求计算 |
| activity_level | ENUM | 活动水平 | 总能耗计算 |
| nutrition_goal | ENUM | 营养目标 | 推荐策略选择 |
| daily_calories_target | FLOAT | 每日热量目标 | 推荐阈值设定 |
| daily_protein_target | FLOAT | 每日蛋白质目标 | 高蛋白需求评估 |
| daily_carb_target | FLOAT | 每日碳水目标 | 碳水摄入平衡 |
| daily_fat_target | FLOAT | 每日脂肪目标 | 脂肪摄入控制 |

**营养目标枚举值**：
- `lose_weight`：减脂策略（低热量、高纤维优先）
- `gain_muscle`：增肌策略（高蛋白、适量碳水优先）
- `maintain`：维持策略（营养均衡优先）
- `general_health`：一般健康（营养密度优先）

### 2. 过敏原管理表

#### ALLERGEN（过敏原字典表）
**数据来源**：系统启动时从 PRODUCT.allergens 字段提取生成  
**记录数量**：预计 300+ 种过敏原  

| 字段名 | 类型 | 说明 |
|--------|------|------|
| allergen_id | INT PK | 过敏原唯一标识 |
| name | VARCHAR(100) | 过敏原标准名称 |
| category | VARCHAR(50) | 分类（nuts/dairy/grains 等） |
| is_common | BOOLEAN | 是否为常见过敏原（EU 14 种） |
| description | TEXT | 过敏原描述 |

#### USER_ALLERGEN（用户过敏原关联表）
**数据来源**：用户注册后选择，使用过程中可添加  
**作用**：推荐算法的硬过滤条件  

| 字段名 | 类型 | 说明 | 算法用途 |
|--------|------|------|---------|
| user_allergen_id | INT PK | 关联记录 ID | - |
| user_id | INT FK | 用户 ID | 用户过敏原查询 |
| allergen_id | INT FK | 过敏原 ID | 过敏原匹配 |
| severity_level | ENUM | 过敏严重程度 | 过滤严格程度 |
| confirmed | BOOLEAN | 是否确认过敏 | 是否参与过滤 |
| notes | TEXT | 用户备注 | - |

#### PRODUCT_ALLERGEN（商品过敏原关联表）
**数据来源**：系统启动时解析 PRODUCT.allergens 字段生成  
**作用**：支持快速商品过敏原查询  

| 字段名 | 类型 | 说明 | 算法用途 |
|--------|------|------|---------|
| product_allergen_id | INT PK | 关联记录 ID | - |
| barcode | VARCHAR(20) FK | 商品条码 | 商品过敏原查询 |
| allergen_id | INT FK | 过敏原 ID | 过敏原筛选 |
| presence_type | ENUM | 包含类型 | 过滤严格程度 |
| confidence_score | FLOAT | 解析置信度 | 数据质量评估 |

**presence_type 枚举值**：
- `contains`：明确包含
- `may_contain`：可能包含
- `traces`：可能含有痕量

### 3. 用户行为数据表

#### USER_PREFERENCE（用户动态偏好表）
**数据来源**：购买行为分析自动生成 + 用户手动调整  
**更新机制**：每次购买记录分析后更新  

| 字段名 | 类型 | 说明 | 推断逻辑 |
|--------|------|------|---------|
| preference_id | INT PK | 偏好记录 ID | - |
| user_id | INT FK | 用户 ID | - |
| prefer_low_sugar | BOOLEAN | 偏好低糖 | 连续 3 次购买糖分 <5g/100g 商品 |
| prefer_low_fat | BOOLEAN | 偏好低脂 | 连续 3 次购买脂肪 <3g/100g 商品 |
| prefer_high_protein | BOOLEAN | 偏好高蛋白 | 连续 3 次购买蛋白质 >15g/100g 商品 |
| prefer_low_sodium | BOOLEAN | 偏好低钠 | 连续 3 次购买钠 <120mg/100g 商品 |
| prefer_organic | BOOLEAN | 偏好有机 | 连续购买有机标识商品 |
| prefer_low_calorie | BOOLEAN | 偏好低热量 | 连续购买热量 <100kcal/100g 商品 |
| preference_source | ENUM | 偏好来源 | user_manual/system_inferred/mixed |
| inference_confidence | FLOAT | 推断置信度 | 基于购买一致性计算 |
| version | INT | 偏好版本 | 支持偏好变化追踪 |

**偏好推断触发条件**：
- 触发阈值：同类偏好连续 3 次购买
- 置信度计算：一致性购买次数 / 总购买次数
- 时间权重：近 30 天购买权重 × 2

#### SCAN_HISTORY（扫描历史表）
**数据来源**：用户条形码扫描操作  
**作用**：记录用户兴趣，协同过滤辅助数据  

| 字段名 | 类型 | 说明 | 算法用途 |
|--------|------|------|---------|
| scan_id | INT PK | 扫描记录 ID | - |
| user_id | INT FK | 用户 ID | 用户行为分析 |
| barcode | VARCHAR(20) FK | 商品条码 | 兴趣商品记录 |
| scan_time | DATETIME | 扫描时间 | 时间权重计算 |
| location | VARCHAR(100) | 扫描地点 | 地理偏好分析 |
| allergen_detected | BOOLEAN | 是否检测到过敏原 | 用户安全意识评估 |
| scan_result | TEXT | 扫描分析结果 | LLM 分析历史 |
| action_taken | ENUM | 后续行为 | 扫描-购买转化率 |

**action_taken 枚举值**：
- `unknown`：未知（默认值）
- `purchased`：扫描后购买
- `avoided`：扫描后避开
- `no_action`：仅查看信息

#### PURCHASE_RECORD（购买记录表）
**数据来源**：用户上传小票，OCR 解析生成  
**作用**：提供购买行为的时间和地点信息  

| 字段名 | 类型 | 说明 | 算法用途 |
|--------|------|------|---------|
| purchase_id | INT PK | 购买记录 ID | 购买明细关联 |
| user_id | INT FK | 用户 ID | 用户购买历史 |
| receipt_date | DATE | 小票日期 | 时间权重计算 |
| store_name | VARCHAR(100) | 购买商店 | 地理偏好分析 |
| total_amount | FLOAT | 总金额 | 消费能力评估 |
| ocr_confidence | FLOAT | OCR 解析置信度 | 数据质量评估 |
| raw_ocr_data | TEXT | 原始 OCR 数据 | 调试和优化 |

#### PURCHASE_ITEM（购买商品明细表）
**数据来源**：PURCHASE_RECORD 商品明细，通过商品名匹配到 PRODUCT 表  
**作用**：协同过滤算法核心数据，构建用户-商品购买矩阵  

| 字段名 | 类型 | 说明 | 算法用途 |
|--------|------|------|---------|
| item_id | INT PK | 明细记录 ID | - |
| purchase_id | INT FK | 购买记录 ID | 购买关联 |
| barcode | VARCHAR(20) FK | 商品条码 | 商品识别 |
| item_name_ocr | VARCHAR(200) | OCR 识别商品名 | 匹配验证 |
| match_confidence | FLOAT | 商品名匹配置信度 | 数据质量 |
| quantity | INT | 购买数量 | 协同过滤权重 |
| unit_price | FLOAT | 单价 | 价格敏感度 |
| total_price | FLOAT | 总价 | 消费分析 |
| estimated_servings | FLOAT | 估算食用份数 | 营养计算基准 |
| total_calories | FLOAT | 总热量贡献 | 营养比例分析 |
| total_proteins | FLOAT | 总蛋白质贡献 | 蛋白质摄入分析 |
| total_carbs | FLOAT | 总碳水贡献 | 碳水摄入分析 |
| total_fat | FLOAT | 总脂肪贡献 | 脂肪摄入分析 |

**营养贡献计算公式**：
```
estimated_servings = quantity × (标准包装量 / serving_size)
total_nutrition = estimated_servings × (nutrition_100g / 100) × serving_size
```

#### PRODUCT_PREFERENCE（商品偏好表）
**数据来源**：用户在使用过程中手动设置  
**作用**：个性化推荐的精细调节  

| 字段名 | 类型 | 说明 | 算法用途 |
|--------|------|------|---------|
| pref_id | INT PK | 偏好记录 ID | - |
| user_id | INT FK | 用户 ID | 用户偏好查询 |
| barcode | VARCHAR(20) FK | 商品条码 | 特定商品偏好 |
| preference_type | ENUM | 偏好类型 | 推荐权重调整 |
| reason | TEXT | 设置原因 | 用户反馈分析 |

**preference_type 影响权重**：
- `like`：推荐权重 × 1.5
- `dislike`：推荐权重 × 0.3
- `blacklist`：完全排除推荐

### 4. 系统日志表

#### RECOMMENDATION_LOG（推荐日志表）
**数据来源**：每次推荐 API 调用生成  
**作用**：算法性能分析和用户行为分析  

| 字段名 | 类型 | 说明 | 用途 |
|--------|------|------|------|
| log_id | INT PK | 日志记录 ID | - |
| user_id | INT FK | 用户 ID | 用户行为分析 |
| request_barcode | VARCHAR(20) | 原商品条码 | 推荐场景分析 |
| request_type | ENUM | 推荐类型 | 算法类型统计 |
| recommended_products | TEXT | 推荐商品列表 JSON | 推荐结果分析 |
| algorithm_version | VARCHAR(20) | 算法版本 | A/B 测试支持 |
| llm_prompt | TEXT | LLM 输入 prompt | prompt 优化 |
| llm_response | TEXT | LLM 原始响应 | 响应质量分析 |
| llm_analysis | TEXT | 解析后分析结果 | 最终输出记录 |
| processing_time_ms | INT | 处理耗时 | 性能监控 |
| total_candidates | INT | 候选商品总数 | 算法效果评估 |
| filtered_candidates | INT | 过滤后候选数 | 过滤效果评估 |

---

## 推荐策略设计

### 同类推荐逻辑

#### 条形码扫描推荐
- **原则**：必须推荐同 category 的商品
- **示例**：用户扫描有糖可乐 → 推荐无糖可乐、其他低糖饮料
- **算法**：category 硬约束 + 营养优化排序

#### 小票扫描推荐
- **原则**：分析购买商品，建议下次替换为同类更优选择
- **示例**：用户购买白面包 → 建议下次购买全麦面包
- **算法**：逐商品分析 + 同类优化建议

### 营养策略配置

```python
NUTRITION_STRATEGIES = {
    'lose_weight': {
        'priority': ['low_calories', 'low_fat', 'low_sugar'],
        'weights': {'energy_kcal_100g': -0.4, 'fat_100g': -0.3, 'sugars_100g': -0.3}
    },
    'gain_muscle': {
        'priority': ['high_protein', 'complex_carbs', 'moderate_calories'],
        'weights': {'proteins_100g': 0.5, 'carbohydrates_100g': 0.2, 'energy_kcal_100g': 0.3}
    },
    'maintain': {
        'priority': ['balanced', 'low_processed', 'nutrient_dense'],
        'weights': {'balance_score': 0.4, 'variety_score': 0.6}
    }
}
```

---

## 索引优化策略

### 查询性能优化

#### 1. 推荐算法核心查询优化
```sql
-- 用户过敏原快速查询
CREATE INDEX idx_user_allergen_confirmed ON USER_ALLERGEN(user_id, confirmed);

-- 商品过敏原快速过滤
CREATE INDEX idx_product_allergen_presence ON PRODUCT_ALLERGEN(allergen_id, presence_type);

-- 用户购买历史查询（协同过滤）
CREATE INDEX idx_purchase_user_time ON PURCHASE_ITEM(purchase_id, barcode);
CREATE INDEX idx_purchase_time_weight ON PURCHASE_RECORD(user_id, receipt_date);

-- 商品营养信息查询（内容过滤）
CREATE INDEX idx_product_nutrition ON PRODUCT(energy_kcal_100g, proteins_100g, fat_100g);

-- 同类商品查询（推荐核心）
CREATE INDEX idx_category_nutrition ON PRODUCT(category, energy_kcal_100g, proteins_100g);
```

#### 2. 用户行为分析优化
```sql
-- 偏好推断相关查询
CREATE INDEX idx_user_preference_latest ON USER_PREFERENCE(user_id, version DESC);

-- 扫描行为时间序列查询
CREATE INDEX idx_scan_user_time ON SCAN_HISTORY(user_id, scan_time DESC);

-- 商品偏好快速查询
CREATE INDEX idx_product_pref_type ON PRODUCT_PREFERENCE(user_id, preference_type);
```

#### 3. 复合索引策略
```sql
-- 推荐算法复合查询优化
CREATE INDEX idx_user_nutrition_goal ON USER(user_id, nutrition_goal);
CREATE INDEX idx_product_category_nutrition ON PRODUCT(category, energy_kcal_100g, proteins_100g);
CREATE INDEX idx_purchase_quantity_weight ON PURCHASE_ITEM(user_id, barcode, quantity, purchase_id);
```

---

## 数据流程设计

### 1. 系统初始化流程

```
OpenFood API 数据
    ↓
PRODUCT 表批量导入
    ↓
解析 allergens 字段
    ↓
生成 ALLERGEN 字典表
    ↓
建立 PRODUCT_ALLERGEN 关联
    ↓
系统就绪
```

### 2. 用户注册流程

```
用户填写注册信息
    ↓
创建 USER 记录
    ↓
用户选择过敏原
    ↓
创建 USER_ALLERGEN 记录
    ↓
初始化 USER_PREFERENCE 默认值
    ↓
计算营养需求目标
    ↓
注册完成
```

### 3. 条形码扫描流程

```
用户扫描商品条码
    ↓
查询 PRODUCT 表获取商品信息
    ↓
查询 USER_ALLERGEN 检测过敏原
    ↓
基于 category 筛选同类候选商品
    ↓
应用营养策略排序
    ↓
记录 SCAN_HISTORY
    ↓
调用 LLM 生成个性化分析
    ↓
返回推荐结果
```

### 4. 小票扫描流程

```
用户上传小票图片
    ↓
OCR 解析小票内容
    ↓
创建 PURCHASE_RECORD
    ↓
逐项匹配商品名到 PRODUCT 表
    ↓
创建 PURCHASE_ITEM 记录
    ↓
计算营养贡献数据
    ↓
触发偏好推断分析
    ↓
更新 USER_PREFERENCE
    ↓
分析每个商品，生成替换建议
    ↓
调用 LLM 生成综合分析
```

### 5. 推荐算法流程

```
用户请求推荐
    ↓
查询用户画像和偏好
    ↓
基于 category 筛选同类商品
    ↓
过敏原硬过滤
    ↓
营养目标内容过滤
    ↓
协同过滤评分
    ↓
综合排序选择 Top 3-5
    ↓
构造 LLM Prompt
    ↓
调用 Azure OpenAI
    ↓
解析 LLM 响应
    ↓
记录 RECOMMENDATION_LOG
    ↓
返回推荐结果
```





