-- ============================================
-- Grocery Guardian 统一数据库Schema
-- 基于grocery_guardian_schema_spec.md的权威规范
-- 所有字段名使用snake_case命名规范
-- ============================================

-- 核心权威表 (来源: grocery_guardian_schema_spec.md)

CREATE TABLE user (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_name TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    age INTEGER,
    gender TEXT,
    height_cm INTEGER,
    weight_kg REAL,
    activity_level TEXT,
    nutrition_goal TEXT,
    daily_calories_target REAL,
    daily_protein_target REAL,
    daily_carb_target REAL,
    daily_fat_target REAL,
    created_time TEXT
);

CREATE TABLE product (
    bar_code TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    brand TEXT,
    ingredients TEXT,
    allergens TEXT,
    energy_100g REAL,
    energy_kcal_100g REAL,
    fat_100g REAL,
    saturated_fat_100g REAL,
    carbohydrates_100g REAL,
    sugars_100g REAL,
    proteins_100g REAL,
    serving_size TEXT,
    category TEXT NOT NULL,
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE allergen (
    allergen_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT,
    is_common INTEGER,
    description TEXT,
    created_time TEXT
);

-- 扩展功能表 (来源: Setup.txt，适配为snake_case命名)

CREATE TABLE user_allergen (
    user_allergen_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    allergen_id INTEGER NOT NULL,
    severity_level TEXT,
    confirmed INTEGER DEFAULT 1,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (allergen_id) REFERENCES allergen(allergen_id)
);

CREATE TABLE product_allergen (
    product_allergen_id INTEGER PRIMARY KEY AUTOINCREMENT,
    bar_code TEXT NOT NULL,
    allergen_id INTEGER NOT NULL,
    presence_type TEXT,
    confidence_score REAL DEFAULT 1.0,
    FOREIGN KEY (bar_code) REFERENCES product(bar_code),
    FOREIGN KEY (allergen_id) REFERENCES allergen(allergen_id)
);

CREATE TABLE scan_history (
    scan_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    bar_code TEXT NOT NULL,
    scan_time TEXT DEFAULT CURRENT_TIMESTAMP,
    location TEXT,
    allergen_detected INTEGER DEFAULT 0,
    scan_result TEXT,
    action_taken TEXT,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (bar_code) REFERENCES product(bar_code)
);

CREATE TABLE purchase_record (
    purchase_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    receipt_date TEXT,
    store_name TEXT,
    total_amount REAL,
    ocr_confidence REAL,
    raw_ocr_data TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

CREATE TABLE purchase_item (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_id INTEGER NOT NULL,
    bar_code TEXT,
    item_name_ocr TEXT,
    match_confidence REAL,
    quantity INTEGER,
    unit_price REAL,
    total_price REAL,
    estimated_servings REAL,
    total_calories REAL,
    total_proteins REAL,
    total_carbs REAL,
    total_fat REAL,
    FOREIGN KEY (purchase_id) REFERENCES purchase_record(purchase_id),
    FOREIGN KEY (bar_code) REFERENCES product(bar_code)
);

CREATE TABLE user_preference (
    preference_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    prefer_low_sugar INTEGER DEFAULT 0,
    prefer_low_fat INTEGER DEFAULT 0,
    prefer_high_protein INTEGER DEFAULT 0,
    prefer_low_sodium INTEGER DEFAULT 0,
    prefer_organic INTEGER DEFAULT 0,
    prefer_low_calorie INTEGER DEFAULT 0,
    preference_source TEXT DEFAULT 'system_inferred',
    inference_confidence REAL DEFAULT 0.5,
    version INTEGER DEFAULT 1,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

CREATE TABLE product_preference (
    pref_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    bar_code TEXT NOT NULL,
    preference_type TEXT,
    reason TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (bar_code) REFERENCES product(bar_code)
);

CREATE TABLE recommendation_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    request_bar_code TEXT,
    request_type TEXT,
    recommended_products TEXT,
    algorithm_version TEXT,
    llm_prompt TEXT,
    llm_response TEXT,
    llm_analysis TEXT,
    processing_time_ms INTEGER,
    total_candidates INTEGER,
    filtered_candidates INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

-- ============================================
-- 性能优化索引
-- ============================================

CREATE INDEX idx_product_category ON product(category);
CREATE INDEX idx_product_nutrition ON product(energy_kcal_100g, proteins_100g, fat_100g);
CREATE INDEX idx_product_brand ON product(brand);

CREATE INDEX idx_user_nutrition_goal ON user(nutrition_goal);
CREATE INDEX idx_user_allergen_user ON user_allergen(user_id, confirmed);

CREATE INDEX idx_product_allergen_barcode ON product_allergen(bar_code);
CREATE INDEX idx_product_allergen_type ON product_allergen(allergen_id, presence_type);

CREATE INDEX idx_purchase_user_date ON purchase_record(user_id, receipt_date DESC);
CREATE INDEX idx_purchase_item_barcode ON purchase_item(bar_code, quantity);

CREATE INDEX idx_scan_user_time ON scan_history(user_id, scan_time DESC);

CREATE INDEX idx_recommendation_user_time ON recommendation_log(user_id, created_at DESC);

CREATE INDEX idx_user_preference_latest ON user_preference(user_id, version DESC);
CREATE INDEX idx_product_pref_type ON product_preference(user_id, preference_type);

-- ============================================
-- 视图创建
-- ============================================

CREATE VIEW user_profile_view AS
SELECT 
    u.user_id,
    u.user_name,
    u.age,
    u.gender,
    u.nutrition_goal,
    u.daily_calories_target,
    u.daily_protein_target,
    GROUP_CONCAT(a.name) as allergens_list,
    COUNT(ua.allergen_id) as allergen_count
FROM user u
LEFT JOIN user_allergen ua ON u.user_id = ua.user_id AND ua.confirmed = 1
LEFT JOIN allergen a ON ua.allergen_id = a.allergen_id
GROUP BY u.user_id, u.user_name, u.age, u.gender, u.nutrition_goal;

CREATE VIEW product_detail_view AS
SELECT 
    p.bar_code,
    p.product_name,
    p.brand,
    p.category,
    p.energy_kcal_100g,
    p.proteins_100g,
    p.fat_100g,
    p.sugars_100g,
    GROUP_CONCAT(a.name) as detected_allergens,
    COUNT(pa.allergen_id) as allergen_count
FROM product p
LEFT JOIN product_allergen pa ON p.bar_code = pa.bar_code
LEFT JOIN allergen a ON pa.allergen_id = a.allergen_id
GROUP BY p.bar_code, p.product_name, p.brand, p.category;