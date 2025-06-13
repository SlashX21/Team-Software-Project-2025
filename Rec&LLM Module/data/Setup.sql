-- ============================================
-- Grocery Guardian 数据库表结构创建
-- 设计目标：SQLite本地开发 + SQL Server生产兼容
-- ============================================

-- 1. 商品主表 (核心表)
CREATE TABLE PRODUCT (
    barcode VARCHAR(20) PRIMARY KEY,           -- 商品条形码，全局主键
    name VARCHAR(200) NOT NULL,               -- 商品名称
    brand VARCHAR(100),                       -- 品牌名称
    ingredients TEXT,                         -- 成分列表 (NLP分析源)
    allergens TEXT,                          -- 过敏原信息 (解析源)
    energy_100g REAL,                        -- 能量值(焦耳)
    energy_kcal_100g REAL,                   -- 热量(卡路里) - 减脂核心指标
    fat_100g REAL,                           -- 脂肪含量
    saturated_fat_100g REAL,                 -- 饱和脂肪
    carbohydrates_100g REAL,                 -- 碳水化合物
    sugars_100g REAL,                        -- 糖分含量 - 减脂重要指标
    proteins_100g REAL,                      -- 蛋白质含量 - 增肌核心指标
    serving_size VARCHAR(50),                -- 建议食用份量
    category VARCHAR(50) NOT NULL,           -- 商品分类 - 推荐算法约束
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. 用户表 (用户画像)
CREATE TABLE USER (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,  -- 用户ID，自增主键
    username VARCHAR(50) UNIQUE NOT NULL,       -- 用户名，唯一
    email VARCHAR(100) UNIQUE NOT NULL,         -- 邮箱，唯一
    password_hash VARCHAR(255),                 -- 密码哈希(预留)
    age INTEGER,                                -- 年龄 - BMR计算
    gender VARCHAR(10),                         -- 性别: male/female/other
    height_cm INTEGER,                          -- 身高(厘米) - BMR计算
    weight_kg REAL,                            -- 体重(公斤) - BMR计算
    activity_level VARCHAR(20),                 -- 活动水平: sedentary/light/moderate/active/very_active
    nutrition_goal VARCHAR(20),                 -- 营养目标: lose_weight/gain_muscle/maintain/general_health
    daily_calories_target REAL,                -- 每日热量目标
    daily_protein_target REAL,                 -- 每日蛋白质目标
    daily_carb_target REAL,                    -- 每日碳水目标
    daily_fat_target REAL,                     -- 每日脂肪目标
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. 过敏原字典表
CREATE TABLE ALLERGEN (
    allergen_id INTEGER PRIMARY KEY AUTOINCREMENT,  -- 过敏原ID
    name VARCHAR(100) UNIQUE NOT NULL,              -- 过敏原标准名称
    category VARCHAR(50),                           -- 分类: nuts/dairy/grains等
    is_common INTEGER DEFAULT 0,                    -- 是否常见过敏原(EU 14种)
    description TEXT                                -- 过敏原描述
);

-- 4. 用户过敏原关联表 (多对多关系)
CREATE TABLE USER_ALLERGEN (
    user_allergen_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,                       -- 外键 → USER.user_id
    allergen_id INTEGER NOT NULL,                   -- 外键 → ALLERGEN.allergen_id
    severity_level VARCHAR(10),                     -- 过敏严重程度: mild/moderate/severe
    confirmed INTEGER DEFAULT 1,                    -- 是否确认过敏: 0/1
    notes TEXT,                                     -- 用户备注
    FOREIGN KEY (user_id) REFERENCES USER(user_id),
    FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id)
);

-- 5. 商品过敏原关联表 (多对多关系)
CREATE TABLE PRODUCT_ALLERGEN (
    product_allergen_id INTEGER PRIMARY KEY AUTOINCREMENT,
    barcode VARCHAR(20) NOT NULL,                   -- 外键 → PRODUCT.barcode
    allergen_id INTEGER NOT NULL,                   -- 外键 → ALLERGEN.allergen_id
    presence_type VARCHAR(12),                      -- 包含类型: contains/may_contain/traces
    confidence_score REAL DEFAULT 1.0,             -- 解析置信度 (0.0-1.0)
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode),
    FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id)
);

-- 6. 扫描历史表 (用户行为数据)
CREATE TABLE SCAN_HISTORY (
    scan_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,                       -- 外键 → USER.user_id
    barcode VARCHAR(20) NOT NULL,                   -- 外键 → PRODUCT.barcode
    scan_time DATETIME DEFAULT CURRENT_TIMESTAMP,   -- 扫描时间
    location VARCHAR(100),                          -- 扫描地点
    allergen_detected INTEGER DEFAULT 0,            -- 是否检测到过敏原: 0/1
    scan_result TEXT,                               -- 扫描分析结果
    action_taken VARCHAR(20),                       -- 后续行为: unknown/purchased/avoided/no_action
    FOREIGN KEY (user_id) REFERENCES USER(user_id),
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode)
);

-- 7. 购买记录表 (小票扫描结果)
CREATE TABLE PURCHASE_RECORD (
    purchase_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,                       -- 外键 → USER.user_id
    receipt_date DATE,                              -- 小票日期
    store_name VARCHAR(100),                        -- 购买商店
    total_amount REAL,                              -- 总金额
    ocr_confidence REAL,                            -- OCR解析置信度
    raw_ocr_data TEXT,                             -- 原始OCR数据 (调试用)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(user_id)
);

-- 8. 购买商品明细表 (小票商品详情)
CREATE TABLE PURCHASE_ITEM (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_id INTEGER NOT NULL,                   -- 外键 → PURCHASE_RECORD.purchase_id
    barcode VARCHAR(20),                            -- 外键 → PRODUCT.barcode (可能为空，OCR识别失败)
    item_name_ocr VARCHAR(200),                     -- OCR识别的商品名
    match_confidence REAL,                          -- 商品名匹配置信度
    quantity INTEGER,                               -- 购买数量
    unit_price REAL,                               -- 单价
    total_price REAL,                              -- 总价
    estimated_servings REAL,                       -- 估算食用份数
    total_calories REAL,                           -- 总热量贡献
    total_proteins REAL,                           -- 总蛋白质贡献
    total_carbs REAL,                              -- 总碳水贡献
    total_fat REAL,                                -- 总脂肪贡献
    FOREIGN KEY (purchase_id) REFERENCES PURCHASE_RECORD(purchase_id),
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode)
);

-- 9. 用户动态偏好表 (推荐算法权重调整)
CREATE TABLE USER_PREFERENCE (
    preference_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,                       -- 外键 → USER.user_id
    prefer_low_sugar INTEGER DEFAULT 0,             -- 偏好低糖: 0/1
    prefer_low_fat INTEGER DEFAULT 0,               -- 偏好低脂: 0/1
    prefer_high_protein INTEGER DEFAULT 0,          -- 偏好高蛋白: 0/1
    prefer_low_sodium INTEGER DEFAULT 0,            -- 偏好低钠: 0/1
    prefer_organic INTEGER DEFAULT 0,               -- 偏好有机: 0/1
    prefer_low_calorie INTEGER DEFAULT 0,           -- 偏好低热量: 0/1
    preference_source VARCHAR(15) DEFAULT 'system_inferred', -- 偏好来源: user_manual/system_inferred/mixed
    inference_confidence REAL DEFAULT 0.5,          -- 推断置信度
    version INTEGER DEFAULT 1,                      -- 偏好版本 (支持变化追踪)
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(user_id)
);

-- 10. 商品偏好表 (用户对特定商品的偏好)
CREATE TABLE PRODUCT_PREFERENCE (
    pref_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,                       -- 外键 → USER.user_id
    barcode VARCHAR(20) NOT NULL,                   -- 外键 → PRODUCT.barcode
    preference_type VARCHAR(10),                    -- 偏好类型: like/dislike/blacklist
    reason TEXT,                                    -- 设置原因
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(user_id),
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode)
);

-- 11. 推荐日志表 (算法性能分析)
CREATE TABLE RECOMMENDATION_LOG (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,                                -- 外键 → USER.user_id
    request_barcode VARCHAR(20),                    -- 原商品条码
    request_type VARCHAR(20),                       -- 推荐类型: barcode_scan/receipt_analysis
    recommended_products TEXT,                      -- 推荐商品列表 (JSON格式)
    algorithm_version VARCHAR(20),                  -- 算法版本
    llm_prompt TEXT,                               -- LLM输入prompt
    llm_response TEXT,                             -- LLM原始响应
    llm_analysis TEXT,                             -- 解析后分析结果
    processing_time_ms INTEGER,                    -- 处理耗时(毫秒)
    total_candidates INTEGER,                      -- 候选商品总数
    filtered_candidates INTEGER,                   -- 过滤后候选数
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(user_id)
);

-- ============================================
-- 性能优化索引创建
-- ============================================

-- PRODUCT表索引 (推荐算法核心查询优化)
CREATE INDEX idx_product_category ON PRODUCT(category);
CREATE INDEX idx_product_nutrition ON PRODUCT(energy_kcal_100g, proteins_100g, fat_100g);
CREATE INDEX idx_product_brand ON PRODUCT(brand);

-- 用户相关索引
CREATE INDEX idx_user_nutrition_goal ON USER(nutrition_goal);
CREATE INDEX idx_user_allergen_user ON USER_ALLERGEN(user_id, confirmed);

-- 过敏原查询优化
CREATE INDEX idx_product_allergen_barcode ON PRODUCT_ALLERGEN(barcode);
CREATE INDEX idx_product_allergen_type ON PRODUCT_ALLERGEN(allergen_id, presence_type);

-- 购买历史查询优化 (协同过滤算法)
CREATE INDEX idx_purchase_user_date ON PURCHASE_RECORD(user_id, receipt_date DESC);
CREATE INDEX idx_purchase_item_barcode ON PURCHASE_ITEM(barcode, quantity);

-- 扫描历史优化
CREATE INDEX idx_scan_user_time ON SCAN_HISTORY(user_id, scan_time DESC);

-- 推荐日志查询优化
CREATE INDEX idx_recommendation_user_time ON RECOMMENDATION_LOG(user_id, created_at DESC);

-- 用户偏好查询优化
CREATE INDEX idx_user_preference_latest ON USER_PREFERENCE(user_id, version DESC);
CREATE INDEX idx_product_pref_type ON PRODUCT_PREFERENCE(user_id, preference_type);

-- ============================================
-- 数据完整性约束检查
-- ============================================

-- 营养数据合理性检查 (SQLite触发器实现)
CREATE TRIGGER check_nutrition_values 
BEFORE INSERT ON PRODUCT
BEGIN
    SELECT CASE 
        WHEN NEW.energy_kcal_100g < 0 OR NEW.energy_kcal_100g > 2000 THEN
            RAISE(ABORT, 'Invalid energy_kcal_100g value')
        WHEN NEW.proteins_100g < 0 OR NEW.proteins_100g > 200 THEN
            RAISE(ABORT, 'Invalid proteins_100g value')
        WHEN NEW.fat_100g < 0 OR NEW.fat_100g > 200 THEN
            RAISE(ABORT, 'Invalid fat_100g value')
    END;
END;

-- ============================================
-- 视图创建 (查询便利性)
-- ============================================

-- 用户完整画像视图
CREATE VIEW USER_PROFILE_VIEW AS
SELECT 
    u.user_id,
    u.username,
    u.age,
    u.gender,
    u.nutrition_goal,
    u.daily_calories_target,
    u.daily_protein_target,
    GROUP_CONCAT(a.name) as allergens_list,
    COUNT(ua.allergen_id) as allergen_count
FROM USER u
LEFT JOIN USER_ALLERGEN ua ON u.user_id = ua.user_id AND ua.confirmed = 1
LEFT JOIN ALLERGEN a ON ua.allergen_id = a.allergen_id
GROUP BY u.user_id, u.username, u.age, u.gender, u.nutrition_goal;

-- 商品详细信息视图 (包含过敏原)
CREATE VIEW PRODUCT_DETAIL_VIEW AS
SELECT 
    p.barcode,
    p.name,
    p.brand,
    p.category,
    p.energy_kcal_100g,
    p.proteins_100g,
    p.fat_100g,
    p.sugars_100g,
    GROUP_CONCAT(a.name) as detected_allergens,
    COUNT(pa.allergen_id) as allergen_count
FROM PRODUCT p
LEFT JOIN PRODUCT_ALLERGEN pa ON p.barcode = pa.barcode
LEFT JOIN ALLERGEN a ON pa.allergen_id = a.allergen_id
GROUP BY p.barcode, p.name, p.brand, p.category;

-- ============================================
-- 表创建完成提示
-- ============================================