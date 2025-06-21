-- =====================================================
-- Grocery Guardian Database Schema Creation
-- File: 1_database_schema_creation.sql
-- Purpose: Create all database tables, indexes, and constraints
-- =====================================================

-- 1. Create Database
CREATE DATABASE IF NOT EXISTS grocery_guardian 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE grocery_guardian;

-- =====================================================
-- 2. Core Data Tables
-- =====================================================

-- PRODUCT Table (Core Product Information)
DROP TABLE IF EXISTS PRODUCT;
CREATE TABLE PRODUCT (
    barcode VARCHAR(30) PRIMARY KEY COMMENT 'Product unique identifier - supports up to 30 digits',
    name VARCHAR(250) NOT NULL COMMENT 'Product name - supports longer names',
    brand VARCHAR(150) COMMENT 'Brand name',
    ingredients TEXT COMMENT 'Ingredients list',
    allergens TEXT COMMENT 'Allergen information',
    energy_100g FLOAT COMMENT 'Energy value (Joules)',
    energy_kcal_100g FLOAT COMMENT 'Calories (kcal)',
    fat_100g FLOAT COMMENT 'Fat content',
    saturated_fat_100g FLOAT COMMENT 'Saturated fat',
    carbohydrates_100g FLOAT COMMENT 'Carbohydrates',
    sugars_100g FLOAT COMMENT 'Sugar content',
    proteins_100g FLOAT COMMENT 'Protein content',
    serving_size VARCHAR(50) COMMENT 'Recommended serving size',
    category VARCHAR(50) NOT NULL COMMENT 'Product category',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexing strategy for optimization
    INDEX idx_name_search (name(50)),
    INDEX idx_brand (brand),
    INDEX idx_category (category),
    INDEX idx_nutrition_search (energy_kcal_100g, proteins_100g, fat_100g),
    INDEX idx_category_nutrition (category, energy_kcal_100g),
    FULLTEXT KEY idx_ingredients (ingredients),
    FULLTEXT KEY idx_allergens (allergens),
    
    -- Data quality constraints
    CONSTRAINT chk_nutrition_positive CHECK (
        (energy_kcal_100g IS NULL OR energy_kcal_100g >= 0) AND
        (proteins_100g IS NULL OR proteins_100g >= 0) AND 
        (fat_100g IS NULL OR fat_100g >= 0) AND
        (carbohydrates_100g IS NULL OR carbohydrates_100g >= 0) AND
        (sugars_100g IS NULL OR sugars_100g >= 0)
    )
) ENGINE=InnoDB COMMENT='Product basic information table';

-- =====================================================
-- 3. User Management Tables
-- =====================================================

-- USER Table
DROP TABLE IF EXISTS USER;
CREATE TABLE USER (
    user_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'User unique identifier',
    username VARCHAR(50) UNIQUE NOT NULL COMMENT 'Username',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT 'Email address',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Password hash',
    age INT COMMENT 'Age',
    gender ENUM('male', 'female', 'other') COMMENT 'Gender',
    height_cm INT COMMENT 'Height in cm',
    weight_kg FLOAT COMMENT 'Weight in kg',
    activity_level ENUM('sedentary', 'light', 'moderate', 'active', 'very_active') COMMENT 'Activity level',
    nutrition_goal ENUM('lose_weight', 'gain_muscle', 'maintain', 'general_health') COMMENT 'Nutrition goal',
    daily_calories_target FLOAT COMMENT 'Daily calorie target',
    daily_protein_target FLOAT COMMENT 'Daily protein target',
    daily_carb_target FLOAT COMMENT 'Daily carb target',
    daily_fat_target FLOAT COMMENT 'Daily fat target',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_nutrition_goal (nutrition_goal),
    
    CONSTRAINT chk_user_physical CHECK (
        age BETWEEN 13 AND 120 AND 
        height_cm BETWEEN 100 AND 250 AND 
        weight_kg BETWEEN 30 AND 300
    )
) ENGINE=InnoDB COMMENT='User basic information table';

-- =====================================================
-- 4. Allergen Management Tables
-- =====================================================

-- ALLERGEN Dictionary Table
DROP TABLE IF EXISTS ALLERGEN;
CREATE TABLE ALLERGEN (
    allergen_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Allergen unique identifier',
    name VARCHAR(100) UNIQUE NOT NULL COMMENT 'Allergen standard name',
    category VARCHAR(50) COMMENT 'Category (nuts/dairy/grains etc)',
    is_common BOOLEAN DEFAULT FALSE COMMENT 'Whether it is common allergen (EU 14)',
    description TEXT COMMENT 'Allergen description',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_is_common (is_common)
) ENGINE=InnoDB COMMENT='Allergen dictionary table';

-- USER_ALLERGEN Association Table
DROP TABLE IF EXISTS USER_ALLERGEN;
CREATE TABLE USER_ALLERGEN (
    user_allergen_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Association record ID',
    user_id INT NOT NULL COMMENT 'User ID',
    allergen_id INT NOT NULL COMMENT 'Allergen ID',
    severity_level ENUM('mild', 'moderate', 'severe') DEFAULT 'moderate' COMMENT 'Allergy severity level',
    confirmed BOOLEAN DEFAULT TRUE COMMENT 'Whether allergy is confirmed',
    notes TEXT COMMENT 'User notes',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_allergen (user_id, allergen_id),
    INDEX idx_user_confirmed (user_id, confirmed)
) ENGINE=InnoDB COMMENT='User allergen association table';

-- PRODUCT_ALLERGEN Association Table
DROP TABLE IF EXISTS PRODUCT_ALLERGEN;
CREATE TABLE PRODUCT_ALLERGEN (
    product_allergen_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Association record ID',
    barcode VARCHAR(30) NOT NULL COMMENT 'Product barcode - matches PRODUCT.barcode',
    allergen_id INT NOT NULL COMMENT 'Allergen ID',
    presence_type ENUM('contains', 'may_contain', 'traces') DEFAULT 'contains' COMMENT 'Presence type',
    confidence_score FLOAT DEFAULT 1.0 COMMENT 'Parsing confidence score',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode) ON DELETE CASCADE,
    FOREIGN KEY (allergen_id) REFERENCES ALLERGEN(allergen_id) ON DELETE CASCADE,
    UNIQUE KEY uk_product_allergen (barcode, allergen_id),
    INDEX idx_allergen_presence (allergen_id, presence_type),
    INDEX idx_barcode_allergen (barcode)
) ENGINE=InnoDB COMMENT='Product allergen association table';

-- =====================================================
-- 5. User Behavior Data Tables
-- =====================================================

-- USER_PREFERENCE Table (Dynamic Preferences)
DROP TABLE IF EXISTS USER_PREFERENCE;
CREATE TABLE USER_PREFERENCE (
    preference_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Preference record ID',
    user_id INT NOT NULL COMMENT 'User ID',
    prefer_low_sugar BOOLEAN DEFAULT FALSE COMMENT 'Prefer low sugar',
    prefer_low_fat BOOLEAN DEFAULT FALSE COMMENT 'Prefer low fat',
    prefer_high_protein BOOLEAN DEFAULT FALSE COMMENT 'Prefer high protein',
    prefer_low_sodium BOOLEAN DEFAULT FALSE COMMENT 'Prefer low sodium',
    prefer_organic BOOLEAN DEFAULT FALSE COMMENT 'Prefer organic',
    prefer_low_calorie BOOLEAN DEFAULT FALSE COMMENT 'Prefer low calorie',
    preference_source ENUM('user_manual', 'system_inferred', 'mixed') DEFAULT 'system_inferred' COMMENT 'Preference source',
    inference_confidence FLOAT DEFAULT 0.0 COMMENT 'Inference confidence based on purchase consistency',
    version INT DEFAULT 1 COMMENT 'Preference version for tracking changes',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_preference_version (user_id, version),
    INDEX idx_user_latest_preference (user_id, version DESC)
) ENGINE=InnoDB COMMENT='User dynamic preference table';

-- SCAN_HISTORY Table
DROP TABLE IF EXISTS SCAN_HISTORY;
CREATE TABLE SCAN_HISTORY (
    scan_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Scan record ID',
    user_id INT NOT NULL COMMENT 'User ID',
    barcode VARCHAR(30) NOT NULL COMMENT 'Product barcode - matches PRODUCT.barcode',
    scan_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Scan time',
    location VARCHAR(100) COMMENT 'Scan location',
    allergen_detected BOOLEAN DEFAULT FALSE COMMENT 'Whether allergens were detected',
    scan_result TEXT COMMENT 'Scan analysis result',
    action_taken ENUM('unknown', 'purchased', 'avoided', 'no_action') DEFAULT 'unknown' COMMENT 'Subsequent action',
    
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode) ON DELETE CASCADE,
    INDEX idx_user_scan_time (user_id, scan_time DESC),
    INDEX idx_barcode_scans (barcode)
) ENGINE=InnoDB COMMENT='Product scan history table';

-- PURCHASE_RECORD Table
DROP TABLE IF EXISTS PURCHASE_RECORD;
CREATE TABLE PURCHASE_RECORD (
    purchase_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Purchase record ID',
    user_id INT NOT NULL COMMENT 'User ID',
    receipt_date DATE NOT NULL COMMENT 'Receipt date',
    store_name VARCHAR(100) COMMENT 'Store name',
    total_amount FLOAT COMMENT 'Total amount',
    ocr_confidence FLOAT DEFAULT 0.0 COMMENT 'OCR parsing confidence',
    raw_ocr_data TEXT COMMENT 'Raw OCR data',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    INDEX idx_user_purchase_time (user_id, receipt_date DESC),
    
    CONSTRAINT chk_purchase_positive CHECK (total_amount >= 0)
) ENGINE=InnoDB COMMENT='Purchase record table';

-- PURCHASE_ITEM Table (Purchase Item Details)
DROP TABLE IF EXISTS PURCHASE_ITEM;
CREATE TABLE PURCHASE_ITEM (
    item_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Item record ID',
    purchase_id INT NOT NULL COMMENT 'Purchase record ID',
    barcode VARCHAR(30) NOT NULL COMMENT 'Product barcode - matches PRODUCT.barcode',
    item_name_ocr VARCHAR(250) COMMENT 'OCR recognized product name',
    match_confidence FLOAT DEFAULT 0.0 COMMENT 'Product name match confidence',
    quantity INT NOT NULL COMMENT 'Purchase quantity',
    unit_price FLOAT COMMENT 'Unit price',
    total_price FLOAT COMMENT 'Total price',
    estimated_servings FLOAT COMMENT 'Estimated servings consumed',
    total_calories FLOAT COMMENT 'Total calorie contribution',
    total_proteins FLOAT COMMENT 'Total protein contribution',
    total_carbs FLOAT COMMENT 'Total carb contribution',
    total_fat FLOAT COMMENT 'Total fat contribution',
    
    FOREIGN KEY (purchase_id) REFERENCES PURCHASE_RECORD(purchase_id) ON DELETE CASCADE,
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode) ON DELETE CASCADE,
    INDEX idx_purchase_item (purchase_id, barcode),
    INDEX idx_purchase_quantity_weight (purchase_id, barcode, quantity),
    
    CONSTRAINT chk_purchase_item_positive CHECK (
        quantity > 0 AND 
        unit_price >= 0 AND 
        total_price >= 0
    )
) ENGINE=InnoDB COMMENT='Purchase item details table';

-- PRODUCT_PREFERENCE Table
DROP TABLE IF EXISTS PRODUCT_PREFERENCE;
CREATE TABLE PRODUCT_PREFERENCE (
    pref_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Preference record ID',
    user_id INT NOT NULL COMMENT 'User ID',
    barcode VARCHAR(30) NOT NULL COMMENT 'Product barcode - matches PRODUCT.barcode',
    preference_type ENUM('like', 'dislike', 'blacklist') NOT NULL COMMENT 'Preference type',
    reason TEXT COMMENT 'Reason for setting preference',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    FOREIGN KEY (barcode) REFERENCES PRODUCT(barcode) ON DELETE CASCADE,
    UNIQUE KEY uk_user_product_preference (user_id, barcode),
    INDEX idx_product_pref_type (user_id, preference_type)
) ENGINE=InnoDB COMMENT='Product preference table';

-- =====================================================
-- 6. System Log Tables
-- =====================================================

-- RECOMMENDATION_LOG Table
DROP TABLE IF EXISTS RECOMMENDATION_LOG;
CREATE TABLE RECOMMENDATION_LOG (
    log_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Log record ID',
    user_id INT NOT NULL COMMENT 'User ID',
    request_barcode VARCHAR(30) COMMENT 'Original product barcode - matches PRODUCT.barcode',
    request_type ENUM('barcode_scan', 'receipt_scan', 'manual_request') COMMENT 'Recommendation type',
    recommended_products TEXT COMMENT 'Recommended products list JSON',
    algorithm_version VARCHAR(20) COMMENT 'Algorithm version',
    llm_prompt TEXT COMMENT 'LLM input prompt',
    llm_response TEXT COMMENT 'LLM raw response',
    llm_analysis TEXT COMMENT 'Parsed analysis result',
    processing_time_ms INT COMMENT 'Processing time in milliseconds',
    total_candidates INT COMMENT 'Total candidate products',
    filtered_candidates INT COMMENT 'Candidates after filtering',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    INDEX idx_user_recommendation_time (user_id, created_at DESC),
    INDEX idx_request_type (request_type)
) ENGINE=InnoDB COMMENT='Recommendation log table';

-- =====================================================
-- 7. Additional Performance Indexes
-- =====================================================

-- Core recommendation algorithm indexes
CREATE INDEX idx_user_nutrition_goal ON USER(user_id, nutrition_goal);
CREATE INDEX idx_product_category_nutrition ON PRODUCT(category, energy_kcal_100g, proteins_100g);
CREATE INDEX idx_user_allergen_confirmed ON USER_ALLERGEN(user_id, confirmed);
CREATE INDEX idx_product_allergen_presence ON PRODUCT_ALLERGEN(allergen_id, presence_type);

-- =====================================================
-- 8. Database Schema Creation Complete
-- =====================================================

-- Verify table creation
SELECT 
    TABLE_NAME,
    TABLE_COMMENT,
    CREATE_TIME
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'grocery_guardian'
ORDER BY TABLE_NAME;

-- Show table sizes (will be 0 for new tables)
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS 'SIZE_MB'
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'grocery_guardian'
ORDER BY TABLE_NAME;

-- =====================================================
-- Schema Creation Summary:
-- 
-- ✅ Core Tables: PRODUCT, USER
-- ✅ Allergen Management: ALLERGEN, USER_ALLERGEN, PRODUCT_ALLERGEN  
-- ✅ User Behavior: USER_PREFERENCE, SCAN_HISTORY, PURCHASE_RECORD, PURCHASE_ITEM, PRODUCT_PREFERENCE
-- ✅ System Logs: RECOMMENDATION_LOG
-- ✅ Performance Indexes: Category, nutrition, allergen queries optimized
-- ✅ Data Integrity: Foreign keys, constraints, and validation rules
-- 
-- Next Step: Run 2_product_data_import.sql to import CSV data
-- =====================================================
