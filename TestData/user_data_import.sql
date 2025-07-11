-- =====================================================
-- Grocery Guardian 测试数据导入脚本 (适配当前数据库结构)
-- 目标数据库: springboot_demo
-- 适配字段: bar_code, product_name, is_common等
-- =====================================================

USE springboot_demo;

-- =====================================================
-- 1. 启用本地文件导入
-- =====================================================
SET GLOBAL local_infile = 1;

-- =====================================================
-- 2. 预导入检查
-- =====================================================

-- 检查当前数据状态
SELECT '=== 导入前数据统计 ===' AS status;

SELECT 
    'allergen表当前记录数' AS table_name,
    COUNT(*) AS record_count
FROM allergen
UNION ALL
SELECT 
    'product表当前记录数' AS table_name,
    COUNT(*) AS record_count
FROM product;

-- =====================================================
-- 3. 过敏原数据导入
-- =====================================================

-- 创建临时表导入过敏原CSV数据
DROP TABLE IF EXISTS temp_allergen_import;

CREATE TABLE temp_allergen_import (
    allergen_id_raw TEXT,
    name_raw TEXT,
    category_raw TEXT,
    is_common_raw TEXT,
    description_raw TEXT
) ENGINE=InnoDB;

-- 导入过敏原数据 - 需要将CSV文件路径替换为实际路径
-- 注意：请将文件路径替换为实际的allergen_dictionary.csv文件位置
/*
LOAD DATA LOCAL INFILE '/path/to/TestData/allergen_dictionary.csv'
INTO TABLE temp_allergen_import
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(allergen_id_raw, name_raw, category_raw, is_common_raw, description_raw);
*/

-- 如果LOAD DATA不可用，可以手动插入部分测试数据
INSERT INTO temp_allergen_import (allergen_id_raw, name_raw, category_raw, is_common_raw, description_raw) VALUES
('1', 'milk', 'dairy', 'true', 'Dairy products including cow\'s milk, cheese, butter, yogurt, and milk-derived ingredients'),
('2', 'cereals-containing-gluten', 'grains', 'true', 'Wheat, rye, barley, oats, and other gluten-containing grains and their derivatives'),
('3', 'soybeans', 'legumes', 'true', 'Soybeans and soy-derived products including soy protein, soy lecithin, and soy sauce'),
('4', 'tree-nuts', 'nuts', 'true', 'Tree nuts including almonds, cashews, walnuts, hazelnuts, pecans, and their derivatives'),
('5', 'eggs', 'animal-products', 'true', 'Chicken eggs and egg-derived ingredients including egg whites, yolks, and egg proteins'),
('6', 'fish', 'seafood', 'true', 'All fish species and fish-derived ingredients including fish proteins and fish oils'),
('7', 'peanuts', 'nuts', 'true', 'Peanuts and peanut-derived products including peanut oil and peanut protein'),
('8', 'sulphur-dioxide-and-sulphites', 'additives', 'true', 'Sulphur dioxide and sulphites used as preservatives in foods and beverages'),
('9', 'mustard', 'spices', 'true', 'Mustard seeds, mustard powder, and mustard-containing condiments'),
('10', 'celery', 'vegetables', 'true', 'Celery and celeriac in all forms including celery salt and celery extract');

-- 清理并插入到正式表
INSERT IGNORE INTO allergen (
    allergen_id, 
    name, 
    category, 
    is_common, 
    description, 
    created_time
)
SELECT 
    CAST(allergen_id_raw AS SIGNED) AS allergen_id,
    TRIM(name_raw) AS name,
    CASE 
        WHEN category_raw IS NULL OR category_raw = '' THEN NULL
        ELSE TRIM(category_raw)
    END AS category,
    CASE 
        WHEN LOWER(TRIM(is_common_raw)) IN ('true', '1', 'yes', 't') THEN 1
        ELSE 0
    END AS is_common,
    CASE 
        WHEN description_raw IS NULL OR description_raw = '' THEN NULL
        ELSE TRIM(description_raw)
    END AS description,
    CURRENT_TIMESTAMP AS created_time
FROM temp_allergen_import
WHERE allergen_id_raw IS NOT NULL 
  AND allergen_id_raw != '' 
  AND name_raw IS NOT NULL 
  AND name_raw != '';

-- =====================================================
-- 4. 产品数据导入
-- =====================================================

-- 创建临时表导入产品CSV数据
DROP TABLE IF EXISTS temp_product_import;

CREATE TABLE temp_product_import (
    barcode_raw TEXT,
    name_raw TEXT,
    brand_raw TEXT,
    ingredients_raw TEXT,
    allergens_raw TEXT,
    energy_100g_raw TEXT,
    energy_kcal_100g_raw TEXT,
    fat_100g_raw TEXT,
    saturated_fat_100g_raw TEXT,
    carbohydrates_100g_raw TEXT,
    sugars_100g_raw TEXT,
    proteins_100g_raw TEXT,
    serving_size_raw TEXT,
    category_raw TEXT
) ENGINE=InnoDB;

-- 导入产品数据 - 需要将CSV文件路径替换为实际路径
-- 注意：请将文件路径替换为实际的ireland_products_final.csv文件位置
/*
LOAD DATA LOCAL INFILE '/path/to/TestData/ireland_products_final.csv'
INTO TABLE temp_product_import
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(barcode_raw, name_raw, brand_raw, ingredients_raw, allergens_raw, 
 energy_100g_raw, energy_kcal_100g_raw, fat_100g_raw, saturated_fat_100g_raw, 
 carbohydrates_100g_raw, sugars_100g_raw, proteins_100g_raw, 
 serving_size_raw, category_raw);
*/

-- 如果LOAD DATA不可用，插入部分测试数据
INSERT INTO temp_product_import VALUES
('17', 'Collagen For Her', 'Bodylab', 'whey protein concentrate, milk protein concentrate, flavoring, thickener (xanthan gum), sweetener (sucralose)', 'milk, sucralose, xanthan-gum', '1611.0', '385.0', '5.0', '2.5', '5.5', '5.5', '75.0', '11g', 'Health & Supplements'),
('45', 'Vegetable gyoza', 'Morrisons', 'acrylate adhesive, polyester, silicone adhesive', '', '611.0', '146.0', '3.1', '0.5', '25.2', '', '3.3', '75g', 'Food'),
('202', 'VEGAN BRAIN + BODY BOOST', 'Rum dunkel, Vegan Brain Food', 'Creatine Monohydrate 5000mg, Taurine 1500mg, Beta alanine 1000mg', '', '1448.0', '346.0', '7.5', '2.4', '21.0', '15.0', '39.0', '100g', 'Health & Supplements'),
('229', 'Vanilla Grass-fed Whey Protein Isolate', 'Opportuniteas', 'Whey Protein Isolate, Organic Cane Sugar, Organic Vanilla Flavor, Sunflower Lecithin', 'lecithin, milk, sunflower-lecithin, vanilla', '1670.0', '400.0', '0.0', '0.0', '23.3', '23.3', '73.3', '30g', 'Health & Supplements'),
('232', 'Usda Organic Matcha Latte', 'Jade Leaf', 'Organic Unrefined Cane Sugar, Organic Japanese Matcha Green Tea', 'caffeine', '1670.0', '400.0', '0.0', '0.0', '90.0', '90.0', '9.0', '10g', 'Beverages'),
('253', 'Matcha Latte', 'Jade Leaf', 'Erythritol, Organic Japanese Matcha Green Tea, Monk Fruit Extract', 'caffeine', '1860.0', '444.0', '15.6', '3.33', '64.4', '0.0', '6.67', '45g', 'Beverages'),
('341', 'Hydration Mix', 'Biosteel', 'Vitamin B Blend, Biotin, Choline Bitartrate, Vitamin B12, Folic Acid, Inositol, Niacin, Pantothenic Acid, Riboflavin, Thiamine Hydrochloride, Amino Acid Blend, L-Leucine, L-Valine, L-Isoleucine, Glycine, L-Glutamine, Taurine, Mineral Blend, Calcium, Magnesium, Potassium, Zinc, Natural Flavour, Citric Acid, Sodium Chloride, Sucralose, Silicon Dioxide, Beet Root Powder, Stevia Leaf Extract, Spirulina Extract, Elderberry Extract, Fruit and Vegetable Juice, Malic Acid, Calcium Silicate, Calcium Lactate, Calcium Phosphate, Calcium Carbonate, Magnesium Oxide, Magnesium Phosphate, Magnesium Carbonate, Magnesium Hydroxide, Magnesium Sulfate, Magnesium Chloride, Potassium Citrate, Potassium Bicarbonate, Potassium Chloride, Potassium Phosphate, Potassium Sulfate, Zinc Citrate, Zinc Gluconate, Zinc Oxide, Zinc Sulfate, Zinc Hydroxide, Zinc Carbonate, Zinc Chloride, Zinc Acetate, Zinc Picolinate, Zinc L-Carnosine, Zinc Aspartate, Zinc Orotate, Zinc Glycinate, Zinc Methionine, Zinc Histidine, Zinc Carnosine, Zinc Monomethionine, Zinc Bisglycinate, Zinc Hydrolyzed Vegetable Protein Chelate', 'citric-acid, stevia, sucralose', '300.0', '71.4', '0.0', '', '14.3', '0.0', '0.0', '7g', 'Health & Supplements'),
('397', 'Whole Trilogy Seeds', 'Badia', 'Flaxseed, Chia Seeds, Hemp Seeds', 'chia-seeds, flaxseed, hemp-seeds', '2090.0', '500.0', '38.9', '2.78', '27.8', '7.41', '22.2', '18g', 'Other'),
('403', 'Mint Chocolate Chip Beachbar', 'Beachbody, Grappa, Tequila', 'DIRECTION DIRECTIONS FOR USE: To ensure accurate dosing, use the supplied measure tool to measure 400-900 mg shilajit resin. Dissolve in warm water and drink on an empty stomach 30 minutes before a meal. It can also be swallowed or dissolved under the tongue. STORAGE: Store in a coold and dry place. WARNINGS: KEEP OUT OF REACH OF CHILDREN. Dietary supplements should not be used as a substitute for a healthy and varied diet and a healthy lifestyle. Do not exceed the stated recommended daily intake. Statements regarding this dietary supplement have not been evaluated by the FDA and are not intended to diagnose, treat, cure, or prevent any disease or health condition. LLT', '', '628.0', '150.0', '4.5', '2.0', '15.0', '6.0', '10.0', '1g', 'Snacks'),
('437', 'Hydration Multiplier Electrolyte Drink Mix', 'Liquid I.V.', 'allulose, l-glutamine, l-alanine, citric acid, potassium citrate, salt, sodium citrate, natural flavors, silicon dioxide, stevia leaf extract, vitamin c, vitamin b3, vitamin b5, vitamin b6, vitamin b12', 'ascorbic-acid-vitamin-c, citric-acid, stevia', '0.0', '0.0', '0.0', '0.0', '0.22', '0.0', '0.0', '16oz', 'Health & Supplements');

-- 清理并插入到正式表 (适配字段名mapping)
INSERT IGNORE INTO product (
    bar_code,           -- CSV: barcode → DB: bar_code
    product_name,       -- CSV: name → DB: product_name
    brand, 
    ingredients, 
    allergens,
    energy_100g, 
    energy_kcal_100g, 
    fat_100g, 
    saturated_fat_100g,
    carbohydrates_100g, 
    sugars_100g, 
    proteins_100g,
    serving_size, 
    category,
    created_at,
    updated_at
)
SELECT 
    TRIM(barcode_raw) AS bar_code,
    TRIM(name_raw) AS product_name,
    CASE 
        WHEN brand_raw IS NULL OR brand_raw = '' THEN NULL
        ELSE TRIM(brand_raw)
    END AS brand,
    CASE 
        WHEN ingredients_raw IS NULL OR ingredients_raw = '' THEN NULL
        ELSE TRIM(ingredients_raw)
    END AS ingredients,
    CASE 
        WHEN allergens_raw IS NULL OR allergens_raw = '' THEN NULL
        ELSE TRIM(allergens_raw)
    END AS allergens,
    CASE 
        WHEN energy_100g_raw IS NULL OR energy_100g_raw = '' THEN NULL
        WHEN CAST(energy_100g_raw AS DECIMAL(10,2)) < 0 THEN NULL
        ELSE CAST(energy_100g_raw AS DECIMAL(10,2))
    END AS energy_100g,
    CASE 
        WHEN energy_kcal_100g_raw IS NULL OR energy_kcal_100g_raw = '' THEN NULL
        WHEN CAST(energy_kcal_100g_raw AS DECIMAL(8,2)) < 0 THEN NULL
        ELSE CAST(energy_kcal_100g_raw AS DECIMAL(8,2))
    END AS energy_kcal_100g,
    CASE 
        WHEN fat_100g_raw IS NULL OR fat_100g_raw = '' THEN NULL
        WHEN CAST(fat_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(fat_100g_raw AS DECIMAL(6,2))
    END AS fat_100g,
    CASE 
        WHEN saturated_fat_100g_raw IS NULL OR saturated_fat_100g_raw = '' THEN NULL
        WHEN CAST(saturated_fat_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(saturated_fat_100g_raw AS DECIMAL(6,2))
    END AS saturated_fat_100g,
    CASE 
        WHEN carbohydrates_100g_raw IS NULL OR carbohydrates_100g_raw = '' THEN NULL
        WHEN CAST(carbohydrates_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(carbohydrates_100g_raw AS DECIMAL(6,2))
    END AS carbohydrates_100g,
    CASE 
        WHEN sugars_100g_raw IS NULL OR sugars_100g_raw = '' THEN NULL
        WHEN CAST(sugars_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(sugars_100g_raw AS DECIMAL(6,2))
    END AS sugars_100g,
    CASE 
        WHEN proteins_100g_raw IS NULL OR proteins_100g_raw = '' THEN NULL
        WHEN CAST(proteins_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(proteins_100g_raw AS DECIMAL(6,2))
    END AS proteins_100g,
    CASE 
        WHEN serving_size_raw IS NULL OR serving_size_raw = '' THEN NULL
        ELSE TRIM(serving_size_raw)
    END AS serving_size,
    CASE 
        WHEN category_raw IS NULL OR category_raw = '' THEN 'Other'
        ELSE TRIM(category_raw)
    END AS category,
    CURRENT_TIMESTAMP AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM temp_product_import
WHERE barcode_raw IS NOT NULL 
  AND barcode_raw != '' 
  AND name_raw IS NOT NULL 
  AND name_raw != '';

-- =====================================================
-- 5. 创建测试用户数据
-- =====================================================

-- 插入测试用户
INSERT IGNORE INTO user (
    user_id, username, email, password_hash, age, gender, height_cm, weight_kg,
    activity_level, nutrition_goal, daily_calories_target, daily_protein_target,
    daily_carb_target, daily_fat_target
) VALUES 
(1, 'test_user_1', 'test1@example.com', 'hashed_password_123', 28, 'female', 165, 58.5,
 'moderately_active', 'lose_weight', 1800.0, 120.0, 200.0, 60.0),
(2, 'test_user_2', 'test2@example.com', 'hashed_password_456', 35, 'male', 178, 75.2,
 'very_active', 'gain_muscle', 2500.0, 180.0, 300.0, 85.0),
(3, 'test_user_3', 'test3@example.com', 'hashed_password_789', 42, 'female', 160, 65.0,
 'sedentary', 'maintain', 2000.0, 130.0, 250.0, 70.0);

-- =====================================================
-- 6. 导入后验证和统计
-- =====================================================

SELECT '=== 导入后数据统计 ===' AS status;

SELECT 
    'allergen表导入后记录数' AS table_name,
    COUNT(*) AS record_count
FROM allergen
UNION ALL
SELECT 
    'product表导入后记录数' AS table_name,
    COUNT(*) AS record_count
FROM product
UNION ALL
SELECT 
    'user表导入后记录数' AS table_name,
    COUNT(*) AS record_count
FROM user;

-- 检查过敏原分类分布
SELECT '=== 过敏原分类分布 ===' AS info;
SELECT 
    COALESCE(category, 'Uncategorized') AS category,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM allergen), 2) AS percentage
FROM allergen 
GROUP BY category
ORDER BY count DESC;

-- 检查产品类别分布
SELECT '=== 产品类别分布 ===' AS info;
SELECT 
    category,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 2) AS percentage
FROM product 
GROUP BY category
ORDER BY count DESC;

-- 检查营养数据完整性
SELECT '=== 营养数据完整性检查 ===' AS info;
SELECT 
    '有营养信息的产品' AS data_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 2) AS percentage
FROM product 
WHERE energy_kcal_100g IS NOT NULL 
  AND proteins_100g IS NOT NULL 
  AND fat_100g IS NOT NULL 
  AND carbohydrates_100g IS NOT NULL
UNION ALL
SELECT 
    '有过敏原信息的产品' AS data_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 2) AS percentage
FROM product 
WHERE allergens IS NOT NULL AND allergens != '';

-- 测试查询示例
SELECT '=== 测试查询示例 ===' AS info;

-- 高蛋白产品
SELECT '高蛋白产品(>20g/100g):' AS test_type;
SELECT bar_code, product_name, brand, proteins_100g, category 
FROM product 
WHERE proteins_100g > 20 
ORDER BY proteins_100g DESC 
LIMIT 5;

-- 低糖产品
SELECT '低糖产品(<5g/100g):' AS test_type;
SELECT bar_code, product_name, brand, sugars_100g, category 
FROM product 
WHERE sugars_100g IS NOT NULL AND sugars_100g < 5
ORDER BY sugars_100g ASC 
LIMIT 5;

-- 常见过敏原
SELECT '常见过敏原:' AS test_type;
SELECT allergen_id, name, category 
FROM allergen 
WHERE is_common = 1 
ORDER BY name
LIMIT 5;

-- =====================================================
-- 7. 清理临时表
-- =====================================================

DROP TABLE IF EXISTS temp_allergen_import;
DROP TABLE IF EXISTS temp_product_import;

SELECT '✅ 测试数据导入完成！' AS final_status;

-- =====================================================
-- 导入完成摘要
-- =====================================================

SELECT '=== 导入摘要 ===' AS summary_section;

SELECT 
    '数据库名称' AS item,
    'springboot_demo' AS value,
    '当前项目使用的数据库' AS description
UNION ALL
SELECT 
    '字段适配',
    'barcode→bar_code, name→product_name',
    '已完成CSV到数据库字段映射'
UNION ALL
SELECT 
    '数据验证',
    '营养数据类型转换，过敏原布尔值处理',
    '确保数据质量和一致性'
UNION ALL
SELECT 
    '测试用户',
    '3个用户，不同营养目标',
    '用于推荐系统功能测试';

-- =====================================================
-- 说明：
-- 1. 请将CSV文件路径替换为实际路径后取消注释LOAD DATA语句
-- 2. 如果LOAD DATA不可用，脚本已包含少量测试数据
-- 3. 字段映射已适配当前数据库结构
-- 4. 包含数据验证和完整性检查
-- =====================================================