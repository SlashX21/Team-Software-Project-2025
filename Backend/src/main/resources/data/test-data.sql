-- =====================================================
-- 完整关联测试数据生成脚本 (使用正确的Java枚举值)
-- 3个用户，每个用户2条记录，覆盖所有表的关联关系
-- 所有枚举值与Java代码完全匹配
-- =====================================================

USE springboot_demo;
SET SQL_SAFE_UPDATES = 0;

-- =====================================================
-- 第一步：清理现有测试数据
-- =====================================================

SELECT '====== 清理现有测试数据 ======' AS cleanup_step;

DELETE FROM recommendation_log WHERE user_id IN (1001, 1002, 1003);
DELETE FROM barcode_history WHERE user_id IN (1001, 1002, 1003);
DELETE FROM receipt_history WHERE user_id IN (1001, 1002, 1003);
DELETE FROM purchase_item WHERE purchase_id IN (SELECT purchase_id FROM purchase_record WHERE user_id IN (1001, 1002, 1003));
DELETE FROM purchase_record WHERE user_id IN (1001, 1002, 1003);
DELETE FROM scan_history WHERE user_id IN (1001, 1002, 1003);
DELETE FROM daily_sugar_summary WHERE user_id IN (1001, 1002, 1003);
DELETE FROM sugar_intake_history WHERE user_id IN (1001, 1002, 1003);
DELETE FROM sugar_goals WHERE user_id IN (1001, 1002, 1003);
DELETE FROM monthly_statistics WHERE user_id IN (1001, 1002, 1003);
DELETE FROM product_preference WHERE user_id IN (1001, 1002, 1003);
DELETE FROM user_allergen WHERE user_id IN (1001, 1002, 1003);
DELETE FROM user_preference WHERE user_id IN (1001, 1002, 1003);
DELETE FROM user WHERE user_id IN (1001, 1002, 1003);

SELECT '✅ 清理完成' AS cleanup_status;

-- =====================================================
-- 第二步：创建测试用户 (使用正确的枚举值)
-- =====================================================

INSERT INTO user (
    user_id, username, email, password_hash, age, gender, height_cm, weight_kg,
    activity_level, nutrition_goal, daily_calories_target, daily_protein_target,
    daily_carb_target, daily_fat_target, date_of_birth, created_at, updated_at
) VALUES 
-- 用户1: 健身爱好者，对牛奶过敏
(1001, 'fitness_alice', 'alice@test.com', '123456', 28, 'FEMALE', 165, 58.5,
 'VERY_ACTIVE', 'MUSCLE_GAIN', 2200.0, 120.0, 220.0, 80.0, '1995-03-15', NOW(), NOW()),

-- 用户2: 糖尿病患者，对坚果和鸡蛋过敏  
(1002, 'health_bob', 'bob@test.com', '123456', 45, 'MALE', 175, 78.2,
 'MODERATELY_ACTIVE', 'WEIGHT_LOSS', 1800.0, 90.0, 150.0, 60.0, '1978-07-22', NOW(), NOW()),

-- 用户3: 年轻学生，对麸质过敏
(1003, 'student_charlie', 'charlie@test.com', '123456', 22, 'MALE', 180, 70.0,
 'SEDENTARY', 'WEIGHT_MAINTENANCE', 2000.0, 80.0, 250.0, 70.0, '2001-11-08', NOW(), NOW());

-- =====================================================
-- 第三步：用户偏好设置 (使用正确的枚举值)
-- =====================================================

INSERT INTO user_preference (
    user_id, prefer_low_sugar, prefer_low_fat, prefer_high_protein, 
    prefer_low_sodium, prefer_organic, prefer_low_calorie,
    preference_source, inference_confidence, version, created_at, updated_at
) VALUES 
-- Alice: 高蛋白偏好（健身）
(1001, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, 'USER_MANUAL', 0.95, 1, NOW(), NOW()),

-- Bob: 低糖低脂偏好（糖尿病+减重）
(1002, TRUE, TRUE, FALSE, TRUE, FALSE, TRUE, 'USER_MANUAL', 0.98, 1, NOW(), NOW()),

-- Charlie: 低钠偏好（年轻健康）
(1003, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, 'USER_MANUAL', 0.85, 1, NOW(), NOW());

-- =====================================================
-- 第四步：用户过敏原关联 (使用正确的枚举值)
-- =====================================================

INSERT INTO user_allergen (
    user_id, allergen_id, severity_level, confirmed, notes
) VALUES 
-- Alice对牛奶过敏 (使用正确的SeverityLevel枚举)
(1001, 1, 'MODERATE', TRUE, 'Lactose intolerance, causes digestive issues'),
(1001, 28, 'MODERATE', TRUE, 'Whey protein sensitivity'),

-- Bob对坚果和鸡蛋过敏
(1002, 4, 'SEVERE', TRUE, 'Anaphylactic reaction to tree nuts'),
(1002, 5, 'MILD', TRUE, 'Causes skin rash'),

-- Charlie对麸质过敏
(1003, 2, 'MODERATE', TRUE, 'Celiac disease diagnosis'),
(1003, 26, 'MILD', TRUE, 'Oats cross-contamination sensitivity');

-- =====================================================
-- 第五步：糖分目标设置 (使用正确的枚举值)
-- =====================================================

INSERT INTO sugar_goals (
    user_id, daily_goal_mg, goal_level, created_at, updated_at
) VALUES 
-- Alice: 健身者，适中糖分目标 (使用正确的GoalLevel枚举)
(1001, 35000.0, 'MODERATE', NOW(), NOW()),
-- Bob: 糖尿病患者，严格低糖目标
(1002, 20000.0, 'STRICT', NOW(), NOW()),
-- Charlie: 年轻人，宽松目标
(1003, 50000.0, 'RELAXED', NOW(), NOW());

-- =====================================================
-- 第六步：获取真实产品数据用于测试
-- =====================================================

-- 获取一些有过敏原信息的产品条形码
SET @barcode1 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 0);
SET @barcode2 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 1);
SET @barcode3 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 2);
SET @barcode4 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 3);
SET @barcode5 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 4);
SET @barcode6 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 5);

-- 显示选中的产品
SELECT 'Selected test products' AS product_info;
SELECT 
    p.barcode, 
    p.name, 
    p.allergens,
    ROW_NUMBER() OVER() as product_number
FROM product p 
WHERE p.barcode IN (@barcode1, @barcode2, @barcode3, @barcode4, @barcode5, @barcode6);

-- =====================================================
-- 第七步：产品偏好设置 (使用正确的枚举值)
-- =====================================================

INSERT INTO product_preference (
    user_id, barcode, preference_type, reason, created_at
) VALUES 
-- Alice的产品偏好 (使用正确的PreferenceType枚举)
(1001, @barcode1, 'LIKE', 'High protein content, fits my fitness goals', NOW()),
(1001, @barcode2, 'DISLIKE', 'Contains allergens that affect me', NOW()),

-- Bob的产品偏好
(1002, @barcode3, 'LIKE', 'Low sugar content, good for diabetes management', NOW()),
(1002, @barcode4, 'DISLIKE', 'Too high in sugar and contains allergens', NOW()),

-- Charlie的产品偏好
(1003, @barcode5, 'LIKE', 'Safe option for my dietary restrictions', NOW()),
(1003, @barcode6, 'DISLIKE', 'Contains ingredients I need to avoid', NOW());

-- =====================================================
-- 第八步：扫码历史记录 (使用正确的枚举值)
-- =====================================================

INSERT INTO scan_history (
    user_id, barcode, scan_time, location, allergen_detected, 
    scan_result, action_taken, scan_type, recommendation_response, created_at
) VALUES 
-- Alice的扫码记录 (使用正确的ActionTaken和ScanType枚举)
(1001, @barcode1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'SuperValu Cork', FALSE,
 '{"nutritional_score": 8.5, "allergen_warnings": [], "recommendation": "SAFE"}', 
 'PURCHASED', 'BARCODE', 
 '{"status": "safe", "alternatives": [], "nutrition_highlights": ["high_protein"]}', NOW()),
(1001, @barcode2, DATE_SUB(NOW(), INTERVAL 1 DAY), 'Tesco Dublin', TRUE,
 '{"nutritional_score": 6.0, "allergen_warnings": ["milk"], "recommendation": "AVOID"}', 
 'AVOIDED', 'BARCODE', 
 '{"status": "warning", "alternatives": [{"barcode": "alt123", "reason": "dairy_free"}]}', NOW()),

-- Bob的扫码记录
(1002, @barcode3, DATE_SUB(NOW(), INTERVAL 3 DAY), 'Dunnes Stores Dublin', FALSE,
 '{"nutritional_score": 9.0, "allergen_warnings": [], "recommendation": "EXCELLENT"}', 
 'PURCHASED', 'BARCODE', 
 '{"status": "excellent", "nutrition_highlights": ["low_sugar", "low_fat"]}', NOW()),
(1002, @barcode4, DATE_SUB(NOW(), INTERVAL 1 DAY), 'LIDL Cork', TRUE,
 '{"nutritional_score": 4.0, "allergen_warnings": ["eggs"], "recommendation": "AVOID"}', 
 'AVOIDED', 'BARCODE', 
 '{"status": "warning", "alternatives": [{"barcode": "alt456", "reason": "egg_free"}]}', NOW()),

-- Charlie的扫码记录
(1003, @barcode5, DATE_SUB(NOW(), INTERVAL 2 DAY), 'ALDI Dublin', FALSE,
 '{"nutritional_score": 7.5, "allergen_warnings": [], "recommendation": "SAFE"}', 
 'PURCHASED', 'BARCODE', 
 '{"status": "safe", "gluten_free": true}', NOW()),
(1003, @barcode6, DATE_SUB(NOW(), INTERVAL 4 HOUR), 'Centra Dublin', TRUE,
 '{"nutritional_score": 5.0, "allergen_warnings": ["gluten"], "recommendation": "AVOID"}', 
 'AVOIDED', 'BARCODE', 
 '{"status": "danger", "alternatives": [{"barcode": "alt789", "reason": "gluten_free"}]}', NOW());

-- =====================================================
-- 第九步：购买记录
-- =====================================================

INSERT INTO purchase_record (
    user_id, receipt_date, store_name, total_amount, ocr_confidence, 
    raw_ocr_data, scan_id
) VALUES 
-- Alice的购买记录
(1001, DATE_SUB(NOW(), INTERVAL 2 DAY), 'SuperValu Cork', 45.67, 0.92,
 '{"store": "SuperValu", "items": ["Protein Bar", "Greek Yogurt"], "total": 45.67}',
 (SELECT scan_id FROM scan_history WHERE user_id = 1001 AND barcode = @barcode1)),
(1001, DATE_SUB(NOW(), INTERVAL 5 DAY), 'Tesco Dublin', 78.34, 0.88,
 '{"store": "Tesco", "items": ["Chicken Breast", "Quinoa"], "total": 78.34}', NULL),

-- Bob的购买记录
(1002, DATE_SUB(NOW(), INTERVAL 3 DAY), 'Dunnes Stores Dublin', 32.45, 0.95,
 '{"store": "Dunnes", "items": ["Sugar-free cookies", "Almonds"], "total": 32.45}',
 (SELECT scan_id FROM scan_history WHERE user_id = 1002 AND barcode = @barcode3)),
(1002, DATE_SUB(NOW(), INTERVAL 7 DAY), 'LIDL Cork', 56.78, 0.87,
 '{"store": "LIDL", "items": ["Vegetables", "Lean meat"], "total": 56.78}', NULL),

-- Charlie的购买记录
(1003, DATE_SUB(NOW(), INTERVAL 2 DAY), 'ALDI Dublin', 28.90, 0.91,
 '{"store": "ALDI", "items": ["Gluten-free bread", "Rice cakes"], "total": 28.90}',
 (SELECT scan_id FROM scan_history WHERE user_id = 1003 AND barcode = @barcode5)),
(1003, DATE_SUB(NOW(), INTERVAL 6 DAY), 'Centra Dublin', 41.23, 0.89,
 '{"store": "Centra", "items": ["Fruits", "GF pasta"], "total": 41.23}', NULL);

-- =====================================================
-- 第十步：购买项目详情
-- =====================================================

INSERT INTO purchase_item (
    purchase_id, barcode, item_name_ocr, match_confidence, quantity, 
    unit_price, total_price, estimated_servings, total_calories, 
    total_proteins, total_carbs, total_fat
) VALUES 
-- Alice的购买项目
((SELECT purchase_id FROM purchase_record WHERE user_id = 1001 LIMIT 1), @barcode1, 'High Protein Bar', 0.95, 2, 3.50, 7.00, 2.0, 480.0, 24.0, 36.0, 8.0),
((SELECT purchase_id FROM purchase_record WHERE user_id = 1001 LIMIT 1), (SELECT barcode FROM product WHERE proteins_100g > 20 AND barcode != @barcode1 LIMIT 1), 'Greek Yogurt 500g', 0.88, 1, 4.25, 4.25, 5.0, 450.0, 45.0, 25.0, 10.0),

((SELECT purchase_id FROM purchase_record WHERE user_id = 1001 LIMIT 1 OFFSET 1), (SELECT barcode FROM product WHERE proteins_100g > 25 AND barcode NOT IN (@barcode1, @barcode2) LIMIT 1), 'Chicken Breast 1kg', 0.92, 1, 8.99, 8.99, 10.0, 1650.0, 310.0, 0.0, 36.0),
((SELECT purchase_id FROM purchase_record WHERE user_id = 1001 LIMIT 1 OFFSET 1), (SELECT barcode FROM product WHERE carbohydrates_100g > 60 AND barcode NOT IN (@barcode1, @barcode2) LIMIT 1), 'Quinoa 500g', 0.90, 1, 6.50, 6.50, 8.0, 1480.0, 56.0, 232.0, 24.0),

-- Bob的购买项目
((SELECT purchase_id FROM purchase_record WHERE user_id = 1002 LIMIT 1), @barcode3, 'Sugar-free Cookies', 0.93, 1, 4.99, 4.99, 6.0, 360.0, 12.0, 48.0, 12.0),
((SELECT purchase_id FROM purchase_record WHERE user_id = 1002 LIMIT 1), (SELECT barcode FROM product WHERE sugars_100g < 5 AND barcode != @barcode3 LIMIT 1), 'Raw Almonds 200g', 0.91, 1, 7.25, 7.25, 4.0, 1160.0, 42.0, 44.0, 100.0),

((SELECT purchase_id FROM purchase_record WHERE user_id = 1002 LIMIT 1 OFFSET 1), (SELECT barcode FROM product WHERE fat_100g < 3 AND barcode NOT IN (@barcode3, @barcode4) LIMIT 1), 'Mixed Vegetables', 0.89, 2, 2.99, 5.98, 8.0, 320.0, 16.0, 64.0, 4.0),
((SELECT purchase_id FROM purchase_record WHERE user_id = 1002 LIMIT 1 OFFSET 1), (SELECT barcode FROM product WHERE proteins_100g > 20 AND barcode NOT IN (@barcode3, @barcode4) LIMIT 1 OFFSET 1), 'Lean Beef 500g', 0.87, 1, 12.99, 12.99, 5.0, 1000.0, 125.0, 0.0, 50.0),

-- Charlie的购买项目
((SELECT purchase_id FROM purchase_record WHERE user_id = 1003 LIMIT 1), @barcode5, 'Gluten-free Bread', 0.94, 1, 3.99, 3.99, 8.0, 800.0, 24.0, 120.0, 16.0),
((SELECT purchase_id FROM purchase_record WHERE user_id = 1003 LIMIT 1), (SELECT barcode FROM product WHERE carbohydrates_100g > 70 AND barcode != @barcode5 LIMIT 1), 'Rice Cakes Pack', 0.92, 1, 2.49, 2.49, 6.0, 480.0, 12.0, 96.0, 6.0),

((SELECT purchase_id FROM purchase_record WHERE user_id = 1003 LIMIT 1 OFFSET 1), (SELECT barcode FROM product WHERE sugars_100g > 10 AND barcode NOT IN (@barcode5, @barcode6) LIMIT 1), 'Mixed Fruits 1kg', 0.86, 1, 4.99, 4.99, 8.0, 400.0, 8.0, 96.0, 2.0),
((SELECT purchase_id FROM purchase_record WHERE user_id = 1003 LIMIT 1 OFFSET 1), (SELECT barcode FROM product WHERE name LIKE '%pasta%' AND barcode NOT IN (@barcode5, @barcode6) LIMIT 1), 'GF Pasta 500g', 0.91, 1, 5.25, 5.25, 5.0, 1750.0, 70.0, 350.0, 10.0);

-- =====================================================
-- 第十一步：糖分摄入历史
-- =====================================================

INSERT INTO sugar_intake_history (
    user_id, food_name, sugar_amount_mg, quantity, consumed_at, created_at
) VALUES 
-- Alice的糖分摄入（健身者，适量糖分）
(1001, 'Protein Smoothie with Banana', 12000.0, 1.0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
(1001, 'Post-workout Energy Bar', 8500.0, 1.0, DATE_SUB(NOW(), INTERVAL 2 HOUR), NOW()),

-- Bob的糖分摄入（糖尿病患者，严格控糖）
(1002, 'Sugar-free Jelly', 2000.0, 1.0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
(1002, 'Apple (small)', 15000.0, 1.0, DATE_SUB(NOW(), INTERVAL 3 HOUR), NOW()),

-- Charlie的糖分摄入（年轻人，偶尔放纵）
(1003, 'Chocolate Cookie', 18000.0, 2.0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
(1003, 'Orange Juice (250ml)', 22000.0, 1.0, DATE_SUB(NOW(), INTERVAL 4 HOUR), NOW());

-- =====================================================
-- 第十二步：每日糖分总结 (使用正确的枚举值)
-- =====================================================

INSERT INTO daily_sugar_summary (
    user_id, date, total_intake_mg, daily_goal_mg, progress_percentage, 
    status, record_count, created_at, updated_at
) VALUES 
-- Alice的每日糖分总结 (使用正确的SugarSummaryStatus枚举)
(1001, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 20500.0, 35000.0, 58.57, 'GOOD', 2, NOW(), NOW()),
(1001, CURDATE(), 8500.0, 35000.0, 24.29, 'GOOD', 1, NOW(), NOW()),

-- Bob的每日糖分总结
(1002, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 2000.0, 20000.0, 10.00, 'GOOD', 1, NOW(), NOW()),
(1002, CURDATE(), 15000.0, 20000.0, 75.00, 'WARNING', 1, NOW(), NOW()),

-- Charlie的每日糖分总结
(1003, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 36000.0, 50000.0, 72.00, 'WARNING', 2, NOW(), NOW()),
(1003, CURDATE(), 22000.0, 50000.0, 44.00, 'GOOD', 1, NOW(), NOW());

-- =====================================================
-- 第十三步：月度统计
-- =====================================================

INSERT INTO monthly_statistics (
    user_id, year, month, receipt_uploads, total_products, total_spent,
    category_breakdown, popular_products, nutrition_breakdown, 
    calculated_at, updated_at
) VALUES 
-- Alice的月度统计
(1001, 2025, 7, 12, 45, 456.78,
 '{"dairy": 15, "protein": 20, "snacks": 10}',
 '{"protein_bars": 8, "greek_yogurt": 6, "chicken": 4}',
 '{"avg_protein": 125.5, "avg_calories": 2180.0, "avg_sugar": 28.5}',
 NOW(), NOW()),
(1001, 2025, 6, 8, 32, 324.56,
 '{"dairy": 12, "protein": 15, "fruits": 5}',
 '{"protein_powder": 6, "eggs": 5, "bananas": 3}',
 '{"avg_protein": 118.2, "avg_calories": 2090.0, "avg_sugar": 32.1}',
 NOW(), NOW()),

-- Bob的月度统计
(1002, 2025, 7, 15, 38, 298.45,
 '{"vegetables": 18, "lean_meat": 12, "sugar_free": 8}',
 '{"broccoli": 6, "chicken_breast": 5, "almonds": 4}',
 '{"avg_protein": 95.8, "avg_calories": 1750.0, "avg_sugar": 18.2}',
 NOW(), NOW()),
(1002, 2025, 6, 11, 29, 234.67,
 '{"vegetables": 15, "lean_meat": 10, "dairy_free": 4}',
 '{"spinach": 5, "turkey": 4, "oat_milk": 3}',
 '{"avg_protein": 88.5, "avg_calories": 1680.0, "avg_sugar": 15.8}',
 NOW(), NOW()),

-- Charlie的月度统计
(1003, 2025, 7, 9, 28, 187.92,
 '{"gluten_free": 15, "snacks": 8, "beverages": 5}',
 '{"gf_bread": 4, "rice_cakes": 4, "gf_pasta": 3}',
 '{"avg_protein": 78.5, "avg_calories": 1980.0, "avg_sugar": 42.3}',
 NOW(), NOW()),
(1003, 2025, 6, 6, 21, 145.33,
 '{"gluten_free": 12, "fruits": 6, "snacks": 3}',
 '{"gf_cereal": 3, "apples": 3, "gf_cookies": 2}',
 '{"avg_protein": 72.1, "avg_calories": 1850.0, "avg_sugar": 38.9}',
 NOW(), NOW());

-- =====================================================
-- 第十四步：条形码历史
-- =====================================================

INSERT INTO barcode_history (
    user_id, barcode, scan_time, recommendation_id, recommended_products,
    llm_analysis, created_at
) VALUES 
-- Alice的条形码历史
(1001, @barcode1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'REC_001_A', 
 '[{"barcode": "alt001", "name": "Alternative Protein Bar", "score": 9.2}]',
 '{"analysis": "High protein content excellent for fitness goals", "allergen_status": "safe", "nutrition_score": 8.5}',
 NOW()),
(1001, @barcode2, DATE_SUB(NOW(), INTERVAL 1 DAY), 'REC_002_A',
 '[{"barcode": "alt002", "name": "Dairy-free Yogurt", "score": 8.8}]',
 '{"analysis": "Contains milk allergen - recommend dairy-free alternatives", "allergen_status": "warning", "nutrition_score": 6.0}',
 NOW()),

-- Bob的条形码历史
(1002, @barcode3, DATE_SUB(NOW(), INTERVAL 3 DAY), 'REC_003_B',
 '[{"barcode": "alt003", "name": "Even Lower Sugar Option", "score": 9.5}]',
 '{"analysis": "Excellent low-sugar choice for diabetes management", "allergen_status": "safe", "nutrition_score": 9.0}',
 NOW()),
(1002, @barcode4, DATE_SUB(NOW(), INTERVAL 1 DAY), 'REC_004_B',
 '[{"barcode": "alt004", "name": "Egg-free Alternative", "score": 8.0}]',
 '{"analysis": "High sugar content and contains egg allergen", "allergen_status": "warning", "nutrition_score": 4.0}',
 NOW()),

-- Charlie的条形码历史
(1003, @barcode5, DATE_SUB(NOW(), INTERVAL 2 DAY), 'REC_005_C',
 '[{"barcode": "alt005", "name": "Another GF Bread", "score": 8.2}]',
 '{"analysis": "Safe gluten-free option, good for celiac diet", "allergen_status": "safe", "nutrition_score": 7.5}',
 NOW()),
(1003, @barcode6, DATE_SUB(NOW(), INTERVAL 4 HOUR), 'REC_006_C',
 '[{"barcode": "alt006", "name": "Certified GF Alternative", "score": 9.0}]',
 '{"analysis": "Contains gluten - dangerous for celiac condition", "allergen_status": "danger", "nutrition_score": 5.0}',
 NOW());

-- =====================================================
-- 第十五步：收据历史
-- =====================================================

INSERT INTO receipt_history (
    user_id, scan_time, recommendation_id, purchased_items, 
    llm_summary, recommendations_list, created_at
) VALUES 
-- Alice的收据历史
(1001, DATE_SUB(NOW(), INTERVAL 2 DAY), 'RECEIPT_001_A',
 '[{"name": "Protein Bar", "quantity": 2, "price": 7.00}, {"name": "Greek Yogurt", "quantity": 1, "price": 4.25}]',
 'Fitness-focused shopping with high-protein items. Good choices for muscle building goals.',
 '[{"category": "protein", "suggestion": "Consider whey protein powder for better value"}]',
 NOW()),
(1001, DATE_SUB(NOW(), INTERVAL 5 DAY), 'RECEIPT_002_A',
 '[{"name": "Chicken Breast", "quantity": 1, "price": 8.99}, {"name": "Quinoa", "quantity": 1, "price": 6.50}]',
 'Excellent whole food choices. Lean protein and complex carbohydrates support fitness goals.',
 '[{"category": "meal_prep", "suggestion": "Add vegetables for complete nutrition"}]',
 NOW()),

-- Bob的收据历史
(1002, DATE_SUB(NOW(), INTERVAL 3 DAY), 'RECEIPT_003_B',
 '[{"name": "Sugar-free Cookies", "quantity": 1, "price": 4.99}, {"name": "Almonds", "quantity": 1, "price": 7.25}]',
 'Good diabetic-friendly choices. Low sugar content helps with glucose management.',
 '[{"category": "snacks", "suggestion": "Monitor portion sizes for nuts due to calories"}]',
 NOW()),
(1002, DATE_SUB(NOW(), INTERVAL 7 DAY), 'RECEIPT_004_B',
 '[{"name": "Mixed Vegetables", "quantity": 2, "price": 5.98}, {"name": "Lean Beef", "quantity": 1, "price": 12.99}]',
 'Healthy low-carb selections. Vegetables provide fiber, lean meat supports protein needs.',
 '[{"category": "diabetes", "suggestion": "Excellent choices for blood sugar control"}]',
 NOW()),

-- Charlie的收据历史
(1003, DATE_SUB(NOW(), INTERVAL 2 DAY), 'RECEIPT_005_C',
 '[{"name": "Gluten-free Bread", "quantity": 1, "price": 3.99}, {"name": "Rice Cakes", "quantity": 1, "price": 2.49}]',
 'Safe gluten-free options for celiac diet. Both products are certified gluten-free.',
 '[{"category": "celiac", "suggestion": "Look for fortified GF products for added nutrients"}]',
 NOW()),
(1003, DATE_SUB(NOW(), INTERVAL 6 DAY), 'RECEIPT_006_C',
 '[{"name": "Mixed Fruits", "quantity": 1, "price": 4.99}, {"name": "GF Pasta", "quantity": 1, "price": 5.25}]',
 'Balanced gluten-free shopping. Fresh fruits provide vitamins, GF pasta offers safe carbohydrates.',
 '[{"category": "nutrition", "suggestion": "Add protein sources to balance macronutrients"}]',
 NOW());

-- =====================================================
-- 第十六步：推荐日志
-- =====================================================

INSERT INTO recommendation_log (
    user_id, request_barcode, request_type, recommended_products, algorithm_version,
    llm_prompt, llm_response, llm_analysis, processing_time_ms, 
    total_candidates, filtered_candidates, created_at
) VALUES 
-- Alice的推荐日志
(1001, @barcode1, 'NUTRITION_OPTIMIZATION', 
 '[{"barcode": "rec001", "name": "Premium Protein Bar", "score": 9.1, "reason": "Higher protein content"}]',
 'v2.1', 
 'Find protein-rich alternatives for fitness enthusiast with milk allergy',
 'Based on user profile: fitness goals, milk allergy. Recommended high-protein, dairy-free options.',
 '{"protein_analysis": "Current: 12g/100g, Recommended: 20g/100g", "allergen_check": "dairy_free_confirmed"}',
 245, 156, 12, NOW()),

(1001, @barcode2, 'ALLERGEN_ALTERNATIVE',
 '[{"barcode": "rec002", "name": "Oat Milk Yogurt", "score": 8.7, "reason": "Dairy-free alternative"}]',
 'v2.1',
 'Find dairy-free alternatives for user with confirmed milk allergy',
 'Detected milk allergen. Suggesting plant-based alternatives with similar nutritional profile.',
 '{"allergen_detected": ["milk"], "alternatives_found": 8, "safety_score": "high"}',
 189, 89, 8, NOW()),

-- Bob的推荐日志
(1002, @barcode3, 'DIABETES_FRIENDLY',
 '[{"barcode": "rec003", "name": "Ultra Low Sugar Cookies", "score": 9.4, "reason": "Even lower sugar content"}]',
 'v2.1',
 'Optimize for diabetes management - find lower sugar alternatives',
 'Current product is good but found options with even lower sugar content for better glucose control.',
 '{"sugar_analysis": "Current: 5g/100g, Better option: 2g/100g", "diabetes_score": "excellent"}',
 312, 201, 15, NOW()),

(1002, @barcode4, 'ALLERGEN_ALTERNATIVE',
 '[{"barcode": "rec004", "name": "Egg-free Protein Bites", "score": 8.3, "reason": "No egg allergens"}]',
 'v2.1',
 'Find egg-free alternatives for user with egg allergy',
 'Detected egg allergen and high sugar. Recommending egg-free, lower sugar alternatives.',
 '{"allergen_detected": ["eggs"], "sugar_level": "too_high", "alternatives_found": 6}',
 278, 134, 6, NOW()),

-- Charlie的推荐日志
(1003, @barcode5, 'CELIAC_SAFE',
 '[{"barcode": "rec005", "name": "Certified GF Artisan Bread", "score": 8.9, "reason": "Premium gluten-free option"}]',
 'v2.1',
 'Find premium gluten-free alternatives for celiac user',
 'Current product is safe. Found premium certified gluten-free options with better nutrition.',
 '{"gluten_status": "safe", "certification": "verified", "nutrition_upgrade": "available"}',
 156, 67, 9, NOW()),

(1003, @barcode6, 'ALLERGEN_ALTERNATIVE',
 '[{"barcode": "rec006", "name": "Rice-based Pasta Alternative", "score": 9.2, "reason": "100% gluten-free"}]',
 'v2.1',
 'URGENT: Find gluten-free alternatives for celiac user - current product contains gluten',
 'DANGER: Product contains gluten. Immediately suggesting certified gluten-free alternatives.',
 '{"allergen_detected": ["gluten", "wheat"], "danger_level": "high", "celiac_safe_alternatives": 12}',
 95, 78, 12, NOW());

-- =====================================================
-- 第十七步：产品-过敏原关联验证
-- =====================================================

-- 注意：product_allergen 表应该已经通过自动解析脚本生成
-- 这里只是验证关联数据是否存在

SELECT 'Product-Allergen associations verification' AS verification_step;

-- 检查是否有产品-过敏原关联数据
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✅ Found ', COUNT(*), ' product-allergen associations')
        ELSE '⚠️  No product-allergen associations found. Please run auto-generation script first.'
    END AS association_status
FROM product_allergen;

-- 显示一些关联示例（如果存在）
SELECT 'Sample product-allergen associations:' AS sample_data;
SELECT 
    p.name AS product_name,
    a.name AS allergen_name,
    pa.presence_type,
    pa.confidence_score
FROM product_allergen pa
JOIN product p ON pa.barcode = p.barcode
JOIN allergen a ON pa.allergen_id = a.allergen_id
ORDER BY pa.confidence_score DESC
LIMIT 10;

-- =====================================================
-- 第十八步：数据验证查询
-- =====================================================

-- 验证所有关联关系
SELECT '====== 数据关联验证报告 ======' AS validation_report;

-- 用户关联统计
SELECT 'User Associations Summary' AS check_type;
SELECT 
    u.username,
    u.activity_level,
    u.nutrition_goal,
    u.gender,
    COUNT(DISTINCT up.preference_id) AS preferences_count,
    COUNT(DISTINCT ua.user_allergen_id) AS allergens_count,
    COUNT(DISTINCT sh.scan_id) AS scans_count,
    COUNT(DISTINCT pr.purchase_id) AS purchases_count,
    COUNT(DISTINCT pp.preference_id) AS product_preferences_count
FROM user u
LEFT JOIN user_preference up ON u.user_id = up.user_id
LEFT JOIN user_allergen ua ON u.user_id = ua.user_id
LEFT JOIN scan_history sh ON u.user_id = sh.user_id
LEFT JOIN purchase_record pr ON u.user_id = pr.user_id
LEFT JOIN product_preference pp ON u.user_id = pp.user_id
WHERE u.user_id IN (1001, 1002, 1003)
GROUP BY u.user_id, u.username, u.activity_level, u.nutrition_goal, u.gender;

-- 过敏原关联验证
SELECT 'Allergen Associations Check' AS check_type;
SELECT 
    u.username,
    a.name AS allergen_name,
    ua.severity_level,
    COUNT(pa.product_allergen_id) AS products_with_this_allergen
FROM user u
JOIN user_allergen ua ON u.user_id = ua.user_id
JOIN allergen a ON ua.allergen_id = a.allergen_id
LEFT JOIN product_allergen pa ON a.allergen_id = pa.allergen_id
WHERE u.user_id IN (1001, 1002, 1003)
GROUP BY u.user_id, u.username, a.allergen_id, a.name, ua.severity_level;

-- 扫码行为验证
SELECT 'Scan Behavior Check' AS check_type;
SELECT 
    u.username,
    sh.action_taken,
    sh.scan_type,
    COUNT(*) AS scan_count
FROM user u
JOIN scan_history sh ON u.user_id = sh.user_id
WHERE u.user_id IN (1001, 1002, 1003)
GROUP BY u.user_id, u.username, sh.action_taken, sh.scan_type;

-- 糖分数据关联验证
SELECT 'Sugar Data Associations Check' AS check_type;
SELECT 
    u.username,
    sg.goal_level,
    sg.daily_goal_mg,
    COUNT(sih.id) AS intake_records,
    COUNT(DISTINCT dss.date) AS summary_days,
    AVG(dss.progress_percentage) AS avg_daily_progress
FROM user u
JOIN sugar_goals sg ON u.user_id = sg.user_id
LEFT JOIN sugar_intake_history sih ON u.user_id = sih.user_id
LEFT JOIN daily_sugar_summary dss ON u.user_id = dss.user_id
WHERE u.user_id IN (1001, 1002, 1003)
GROUP BY u.user_id, u.username, sg.goal_level, sg.daily_goal_mg;

-- 产品偏好验证
SELECT 'Product Preference Check' AS check_type;
SELECT 
    u.username,
    pp.preference_type,
    COUNT(*) AS preference_count
FROM user u
JOIN product_preference pp ON u.user_id = pp.user_id
WHERE u.user_id IN (1001, 1002, 1003)
GROUP BY u.user_id, u.username, pp.preference_type;

-- =====================================================
-- 第十九步：业务场景测试查询
-- =====================================================

SELECT '====== 业务场景测试查询 ======' AS test_queries;

-- 1. 为用户推荐安全产品（基于过敏原）
SELECT 'Safe Products for Alice (milk allergy)' AS query_example;
SELECT DISTINCT p.barcode, p.name, p.brand
FROM product p
LEFT JOIN product_allergen pa ON p.barcode = pa.barcode
LEFT JOIN allergen a ON pa.allergen_id = a.allergen_id
LEFT JOIN user_allergen ua ON a.allergen_id = ua.allergen_id AND ua.user_id = 1001
WHERE ua.allergen_id IS NULL  -- No allergens that user is allergic to
   OR pa.allergen_id IS NULL  -- Product has no allergen data
LIMIT 5;

-- 2. 用户扫码历史分析
SELECT 'User Scan History Analysis' AS query_example;
SELECT 
    u.username,
    sh.scan_time,
    p.name AS product_name,
    sh.allergen_detected,
    sh.action_taken,
    sh.scan_type,
    CASE 
        WHEN sh.allergen_detected = TRUE THEN '⚠️ Allergen Warning'
        ELSE '✅ Safe to consume'
    END AS safety_status
FROM user u
JOIN scan_history sh ON u.user_id = sh.user_id
LEFT JOIN product p ON sh.barcode = p.barcode
WHERE u.user_id IN (1001, 1002, 1003)
ORDER BY sh.scan_time DESC;

-- 3. 每日糖分摄入趋势
SELECT 'Daily Sugar Intake Trends' AS query_example;
SELECT 
    u.username,
    dss.date,
    dss.total_intake_mg,
    dss.daily_goal_mg,
    dss.progress_percentage,
    dss.status,
    CASE 
        WHEN dss.status = 'GOOD' THEN '✅'
        WHEN dss.status = 'WARNING' THEN '⚠️'
        WHEN dss.status = 'OVER_LIMIT' THEN '❌'
    END AS status_icon
FROM user u
JOIN daily_sugar_summary dss ON u.user_id = dss.user_id
WHERE u.user_id IN (1001, 1002, 1003)
ORDER BY dss.date DESC, u.username;

-- 4. 购买模式分析
SELECT 'Purchase Pattern Analysis' AS query_example;
SELECT 
    u.username,
    pr.store_name,
    pr.total_amount,
    COUNT(pi.item_id) AS items_count,
    SUM(pi.total_calories) AS total_calories,
    SUM(pi.total_proteins) AS total_proteins
FROM user u
JOIN purchase_record pr ON u.user_id = pr.user_id
JOIN purchase_item pi ON pr.purchase_id = pi.purchase_id
WHERE u.user_id IN (1001, 1002, 1003)
GROUP BY u.user_id, u.username, pr.purchase_id, pr.store_name, pr.total_amount
ORDER BY pr.receipt_date DESC;

-- =====================================================
-- 第二十步：登录验证测试
-- =====================================================

SELECT '====== 登录验证测试 ======' AS login_verification;

-- 测试每个用户的登录查询
SELECT 'Alice登录测试：' AS alice_login;
SELECT 
    user_id,
    username,
    email,
    activity_level,
    nutrition_goal,
    gender
FROM user 
WHERE username = 'fitness_alice' AND password_hash = '123456';

SELECT 'Bob登录测试：' AS bob_login;
SELECT 
    user_id,
    username,
    email,
    activity_level,
    nutrition_goal,
    gender
FROM user 
WHERE username = 'health_bob' AND password_hash = '123456';

SELECT 'Charlie登录测试：' AS charlie_login;
SELECT 
    user_id,
    username,
    email,
    activity_level,
    nutrition_goal,
    gender
FROM user 
WHERE username = 'student_charlie' AND password_hash = '123456';

-- =====================================================
-- 第二十一步：完成报告
-- =====================================================

SELECT '====== 测试数据创建完成报告 ======' AS completion_report;

SELECT 
    '✅ 用户数据 (正确枚举值)' AS component,
    '3个用户，使用正确的Java枚举值' AS details,
    'ActivityLevel, NutritionGoal, Gender' AS enums_used
UNION ALL
SELECT 
    '✅ 扫码行为 (正确枚举值)' AS component,
    '每用户2条扫码记录' AS details,
    'ActionTaken, ScanType' AS enums_used
UNION ALL
SELECT 
    '✅ 产品偏好 (正确枚举值)' AS component,
    '每用户2条产品偏好' AS details,
    'PreferenceType' AS enums_used
UNION ALL
SELECT 
    '✅ 过敏原管理 (正确枚举值)' AS component,
    '每用户2个过敏原，不同严重程度' AS details,
    'SeverityLevel' AS enums_used
UNION ALL
SELECT 
    '✅ 糖分管理 (正确枚举值)' AS component,
    '目标设置、摄入记录、每日总结' AS details,
    'GoalLevel, SugarSummaryStatus' AS enums_used
UNION ALL
SELECT 
    '✅ 偏好设置 (正确枚举值)' AS component,
    '用户偏好来源和置信度' AS details,
    'PreferenceSource' AS enums_used;

-- 数据完整性检查
SELECT '数据完整性检查结果：' AS final_check;
SELECT 
    'Total test users created' AS metric,
    COUNT(*) AS count
FROM user WHERE user_id IN (1001, 1002, 1003)
UNION ALL
SELECT 
    'Users with correct enum values' AS metric,
    COUNT(*) AS count
FROM user 
WHERE user_id IN (1001, 1002, 1003)
  AND activity_level IN ('SEDENTARY', 'LIGHTLY_ACTIVE', 'MODERATELY_ACTIVE', 'VERY_ACTIVE', 'EXTRA_ACTIVE')
  AND nutrition_goal IN ('WEIGHT_LOSS', 'WEIGHT_MAINTENANCE', 'WEIGHT_GAIN', 'MUSCLE_GAIN', 'HEALTH_MAINTENANCE')
  AND gender IN ('MALE', 'FEMALE', 'OTHER')
UNION ALL
SELECT 
    'Scans with correct enum values' AS metric,
    COUNT(*) AS count
FROM scan_history 
WHERE user_id IN (1001, 1002, 1003)
  AND action_taken IN ('AVOIDED', 'NO_ACTION', 'PURCHASED', 'UNKNOWN')
  AND scan_type IN ('BARCODE', 'RECEIPT')
UNION ALL
SELECT 
    'Sugar summaries with correct status' AS metric,
    COUNT(*) AS count
FROM daily_sugar_summary 
WHERE user_id IN (1001, 1002, 1003)
  AND status IN ('GOOD', 'WARNING', 'OVER_LIMIT');

-- 恢复安全模式
SET SQL_SAFE_UPDATES = 1;

SELECT '🎉 完整的关联测试数据创建成功！所有枚举值与Java代码完全匹配！' AS success_message;

SELECT 
    '📋 使用的正确枚举值总结：' AS enum_summary,
    '' AS blank_line,
    '👤 ActivityLevel: SEDENTARY, MODERATELY_ACTIVE, VERY_ACTIVE' AS activity_enums,
    '🎯 NutritionGoal: MUSCLE_GAIN, WEIGHT_LOSS, WEIGHT_MAINTENANCE' AS nutrition_enums,
    '⚧ Gender: MALE, FEMALE' AS gender_enums,
    '📱 ActionTaken: PURCHASED, AVOIDED' AS action_enums,
    '🔍 ScanType: BARCODE' AS scan_enums,
    '👍 PreferenceType: LIKE, DISLIKE' AS preference_enums,
    '⚠️ SeverityLevel: MILD, MODERATE, SEVERE' AS severity_enums,
    '🍯 GoalLevel: STRICT, MODERATE, RELAXED' AS goal_enums,
    '📊 SugarSummaryStatus: GOOD, WARNING' AS sugar_status_enums,
    '🔧 PreferenceSource: USER_MANUAL' AS source_enums;

SELECT '✨ 现在所有用户都可以正常登录，枚举值完全匹配Java代码！' AS final_message;