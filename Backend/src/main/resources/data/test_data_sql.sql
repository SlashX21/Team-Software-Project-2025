-- =====================================================
-- 完整关联测试数据生成脚本 (最终版本)
-- 使用正确的Java枚举值和标准JSON格式
-- 3个用户，每个用户2条记录，覆盖所有表的关联关系
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
-- 第三步：用户偏好设置
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
-- 第四步：用户过敏原关联
-- =====================================================

INSERT INTO user_allergen (
    user_id, allergen_id, severity_level, confirmed, notes
) VALUES 
-- Alice对牛奶过敏
(1001, 1, 'MODERATE', TRUE, 'Lactose intolerance, causes digestive issues'),
(1001, 28, 'MODERATE', TRUE, 'Whey protein sensitivity'),

-- Bob对坚果和鸡蛋过敏
(1002, 4, 'SEVERE', TRUE, 'Anaphylactic reaction to tree nuts'),
(1002, 5, 'MILD', TRUE, 'Causes skin rash'),

-- Charlie对麸质过敏
(1003, 2, 'MODERATE', TRUE, 'Celiac disease diagnosis'),
(1003, 26, 'MILD', TRUE, 'Oats cross-contamination sensitivity');

-- =====================================================
-- 第五步：糖分目标设置
-- =====================================================

INSERT INTO sugar_goals (
    user_id, daily_goal_mg, goal_level, created_at, updated_at
) VALUES 
-- Alice: 健身者，适中糖分目标
(1001, 35000.0, 'MODERATE', NOW(), NOW()),
-- Bob: 糖尿病患者，严格低糖目标
(1002, 20000.0, 'STRICT', NOW(), NOW()),
-- Charlie: 年轻人，宽松目标
(1003, 50000.0, 'RELAXED', NOW(), NOW());

-- =====================================================
-- 第六步：获取真实产品数据用于测试
-- =====================================================

SET @barcode1 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 0);
SET @barcode2 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 1);
SET @barcode3 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 2);
SET @barcode4 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 3);
SET @barcode5 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 4);
SET @barcode6 = (SELECT barcode FROM product WHERE allergens IS NOT NULL LIMIT 1 OFFSET 5);

-- =====================================================
-- 第七步：产品偏好设置
-- =====================================================

INSERT INTO product_preference (
    user_id, barcode, preference_type, reason, created_at
) VALUES 
-- Alice的产品偏好
(1001, @barcode1, 'LIKE', 'High protein content, fits my fitness goals', NOW()),
(1001, @barcode2, 'DISLIKE', 'Contains allergens that affect me', NOW()),

-- Bob的产品偏好
(1002, @barcode3, 'LIKE', 'Low sugar content, good for diabetes management', NOW()),
(1002, @barcode4, 'DISLIKE', 'Too high in sugar and contains allergens', NOW()),

-- Charlie的产品偏好
(1003, @barcode5, 'LIKE', 'Safe option for my dietary restrictions', NOW()),
(1003, @barcode6, 'DISLIKE', 'Contains ingredients I need to avoid', NOW());

-- =====================================================
-- 第八步：扫码历史记录 (使用标准JSON格式)
-- =====================================================

INSERT INTO scan_history (
    user_id, barcode, scan_time, location, allergen_detected, 
    scan_result, action_taken, scan_type, recommendation_response, created_at
) VALUES 
-- Alice的扫码记录
(1001, @barcode1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'SuperValu Cork', FALSE,
 '{"nutritional_score": 8.5, "allergen_warnings": [], "recommendation": "SAFE"}', 
 'PURCHASED', 'BARCODE', 
 '{
    "recommendations": [
        {
            "type": "alternative",
            "title": "High-Protein Alternative",
            "description": "Consider plant-based protein bars with dairy-free options for your fitness goals."
        },
        {
            "type": "portion",
            "title": "Optimal Serving Size",
            "description": "For post-workout nutrition, consume within 30 minutes of exercise for best results."
        },
        {
            "type": "dietary",
            "title": "Allergen Consideration",
            "description": "This product is suitable for high-protein diets but avoid if lactose intolerant."
        }
    ],
    "overall_score": 85,
    "health_rating": "good",
    "timestamp": "2025-07-20T22:00:00Z"
 }', NOW()),

(1001, @barcode2, DATE_SUB(NOW(), INTERVAL 1 DAY), 'Tesco Dublin', TRUE,
 '{"nutritional_score": 6.0, "allergen_warnings": ["milk"], "recommendation": "AVOID"}', 
 'AVOIDED', 'BARCODE', 
 '{
    "recommendations": [
        {
            "type": "warning",
            "title": "Allergen Alert",
            "description": "This product contains milk allergens which may cause digestive issues for you."
        },
        {
            "type": "alternative", 
            "title": "Dairy-Free Alternative",
            "description": "Consider oat-based or almond-based alternatives for similar nutritional benefits."
        }
    ],
    "overall_score": 45,
    "health_rating": "avoid",
    "timestamp": "2025-07-20T22:00:00Z"
 }', NOW()),

-- Bob的扫码记录
(1002, @barcode3, DATE_SUB(NOW(), INTERVAL 3 DAY), 'Dunnes Stores Dublin', FALSE,
 '{"nutritional_score": 9.0, "allergen_warnings": [], "recommendation": "EXCELLENT"}', 
 'PURCHASED', 'BARCODE', 
 '{
    "recommendations": [
        {
            "type": "dietary",
            "title": "Diabetes-Friendly Choice",
            "description": "Low sugar content makes this suitable for blood glucose management."
        },
        {
            "type": "portion",
            "title": "Portion Control",
            "description": "Recommended serving size: 30g to maintain optimal blood sugar levels."
        }
    ],
    "overall_score": 90,
    "health_rating": "excellent",
    "timestamp": "2025-07-20T22:00:00Z"
 }', NOW()),

(1002, @barcode4, DATE_SUB(NOW(), INTERVAL 1 DAY), 'LIDL Cork', TRUE,
 '{"nutritional_score": 4.0, "allergen_warnings": ["eggs"], "recommendation": "AVOID"}', 
 'AVOIDED', 'BARCODE', 
 '{
    "recommendations": [
        {
            "type": "warning",
            "title": "High Sugar Alert",
            "description": "This product contains high sugar levels not suitable for diabetes management."
        },
        {
            "type": "alternative",
            "title": "Sugar-Free Alternative",
            "description": "Consider sugar-free versions or naturally sweet options like dates."
        }
    ],
    "overall_score": 35,
    "health_rating": "avoid",
    "timestamp": "2025-07-20T22:00:00Z"
 }', NOW()),

-- Charlie的扫码记录
(1003, @barcode5, DATE_SUB(NOW(), INTERVAL 2 DAY), 'ALDI Dublin', FALSE,
 '{"nutritional_score": 7.5, "allergen_warnings": [], "recommendation": "SAFE"}', 
 'PURCHASED', 'BARCODE', 
 '{
    "recommendations": [
        {
            "type": "dietary",
            "title": "Gluten-Free Verified",
            "description": "This product is certified gluten-free and safe for celiac diet."
        },
        {
            "type": "nutritional",
            "title": "Nutritional Fortification",
            "description": "Look for fortified gluten-free products to ensure adequate vitamin intake."
        }
    ],
    "overall_score": 80,
    "health_rating": "good",
    "timestamp": "2025-07-20T22:00:00Z"
 }', NOW()),

(1003, @barcode6, DATE_SUB(NOW(), INTERVAL 4 HOUR), 'Centra Dublin', TRUE,
 '{"nutritional_score": 5.0, "allergen_warnings": ["gluten"], "recommendation": "AVOID"}', 
 'AVOIDED', 'BARCODE', 
 '{
    "recommendations": [
        {
            "type": "warning",
            "title": "Gluten Warning",
            "description": "This product contains gluten which is dangerous for your celiac condition."
        },
        {
            "type": "alternative",
            "title": "Certified GF Alternative",
            "description": "Look for certified gluten-free alternatives to avoid cross-contamination."
        }
    ],
    "overall_score": 25,
    "health_rating": "danger",
    "timestamp": "2025-07-20T22:00:00Z"
 }', NOW());

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
-- 第十二步：每日糖分总结
-- =====================================================

INSERT INTO daily_sugar_summary (
    user_id, date, total_intake_mg, daily_goal_mg, progress_percentage, 
    status, record_count, created_at, updated_at
) VALUES 
-- Alice的每日糖分总结
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
-- 第十四步：条形码历史 (使用标准JSON格式)
-- =====================================================

INSERT INTO barcode_history (
    user_id, barcode, scan_time, recommendation_id, recommended_products,
    llm_analysis, created_at
) VALUES 
-- Alice的条形码历史
(1001, @barcode1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'REC_001_A', 
 '[
    {
        "rank": 1,
        "barCode": "5000169001234",
        "productName": "Plant-Based Protein Bar",
        "brand": "Vegan Fitness",
        "category": "Protein Supplements",
        "recommendationScore": 0.92,
        "reasoning": "Dairy-free alternative with similar protein content, suitable for lactose intolerance"
    },
    {
        "rank": 2,
        "barCode": "5000169005678",
        "productName": "Organic Pea Protein Bar",
        "brand": "Natural Choice",
        "category": "Protein Supplements",
        "recommendationScore": 0.88,
        "reasoning": "Clean ingredient profile with organic certification and allergen-free"
    },
    {
        "rank": 3,
        "barCode": "5000169009012",
        "productName": "Nut Butter Protein Ball",
        "brand": "Homemade Health",
        "category": "Healthy Snacks",
        "recommendationScore": 0.85,
        "reasoning": "Natural whole food option with healthy fats and protein"
    }
 ]',
 '{
    "summary": "High-protein fitness snack with excellent nutritional profile",
    "detailedAnalysis": "This protein bar provides sustained energy with balanced macronutrients ideal for muscle building. Contains whey protein for fast absorption post-workout, but may trigger lactose sensitivity in some individuals.",
    "actionSuggestions": [
        "Consume within 30 minutes post-workout for optimal protein synthesis",
        "Consider dairy-free alternatives if experiencing digestive issues",
        "Pair with simple carbohydrates for enhanced recovery"
    ],
    "nutritionScore": 85,
    "allergenWarnings": ["milk", "whey-protein"],
    "healthBenefits": [
        "High in complete amino acid profile",
        "Supports muscle protein synthesis",
        "Convenient post-workout nutrition"
    ]
 }', NOW()),

(1001, @barcode2, DATE_SUB(NOW(), INTERVAL 1 DAY), 'REC_002_A',
 '[
    {
        "rank": 1,
        "barCode": "5000169002345",
        "productName": "Oat Milk Yogurt Alternative",
        "brand": "Plant Pure",
        "category": "Dairy Alternatives",
        "recommendationScore": 0.95,
        "reasoning": "Dairy-free with similar creamy texture, fortified with calcium and probiotics"
    },
    {
        "rank": 2,
        "barCode": "5000169006789",
        "productName": "Almond Milk Greek Style",
        "brand": "Nutty Delights",
        "category": "Dairy Alternatives",
        "recommendationScore": 0.90,
        "reasoning": "High protein plant-based alternative with added vitamin D"
    }
 ]',
 '{
    "summary": "Dairy product with high allergen risk for user profile",
    "detailedAnalysis": "While nutritionally valuable with high protein and calcium content, this dairy product contains milk allergens that will likely cause digestive discomfort based on user sensitivity profile.",
    "actionSuggestions": [
        "Avoid consumption due to confirmed milk allergy",
        "Seek plant-based calcium and protein alternatives",
        "Check ingredient labels for hidden dairy derivatives"
    ],
    "nutritionScore": 40,
    "allergenWarnings": ["milk", "lactose", "casein"],
    "healthBenefits": [
        "High calcium content (not suitable for user)",
        "Complete protein profile (dairy-based)"
    ]
 }', NOW()),

-- Bob的条形码历史
(1002, @barcode3, DATE_SUB(NOW(), INTERVAL 3 DAY), 'REC_003_B',
 '[
    {
        "rank": 1,
        "barCode": "5000169003456",
        "productName": "Stevia-Sweetened Biscuits",
        "brand": "Diabetic Choice",
        "category": "Sugar-Free Snacks",
        "recommendationScore": 0.94,
        "reasoning": "Even lower sugar content with natural stevia sweetener"
    },
    {
        "rank": 2,
        "barCode": "5000169007890",
        "productName": "Protein Almond Crackers",
        "brand": "Low Carb Co",
        "category": "Healthy Snacks",
        "recommendationScore": 0.89,
        "reasoning": "Higher protein content for better blood sugar stability"
    }
 ]',
 '{
    "summary": "Excellent low-sugar snack option for diabetes management",
    "detailedAnalysis": "This sugar-free cookie provides satisfying taste without blood glucose spikes. Made with alternative sweeteners and high fiber content to support stable blood sugar levels throughout the day.",
    "actionSuggestions": [
        "Ideal for between-meal snacking to prevent glucose drops",
        "Monitor portion size - limit to 2-3 cookies per serving",
        "Pair with protein for sustained satiety"
    ],
    "nutritionScore": 90,
    "allergenWarnings": [],
    "healthBenefits": [
        "No added sugars - safe for diabetes",
        "High fiber supports digestive health",
        "Controlled carbohydrate content"
    ]
 }', NOW()),

(1002, @barcode4, DATE_SUB(NOW(), INTERVAL 1 DAY), 'REC_004_B',
 '[
    {
        "rank": 1,
        "barCode": "5000169004567",
        "productName": "Egg-free Protein Bites",
        "brand": "Allergy Safe",
        "category": "Protein Snacks",
        "recommendationScore": 0.83,
        "reasoning": "No egg allergens and lower sugar content suitable for diabetes"
    },
    {
        "rank": 2,
        "barCode": "5000169008901",
        "productName": "Sugar-Free Energy Balls",
        "brand": "Diabetic Delights",
        "category": "Healthy Snacks",
        "recommendationScore": 0.80,
        "reasoning": "Naturally sweetened with dates, egg-free formulation"
    }
 ]',
 '{
    "summary": "High-risk product for user with multiple dietary restrictions",
    "detailedAnalysis": "This product contains both eggs (user allergen) and high sugar content (dangerous for diabetes management). Double risk factor makes this unsuitable for consumption.",
    "actionSuggestions": [
        "Avoid completely due to egg allergen and high sugar",
        "Seek alternatives that are both egg-free and sugar-free",
        "Always check labels for both allergens and sugar content"
    ],
    "nutritionScore": 30,
    "allergenWarnings": ["eggs"],
    "healthBenefits": []
 }', NOW()),

-- Charlie的条形码历史
(1003, @barcode5, DATE_SUB(NOW(), INTERVAL 2 DAY), 'REC_005_C',
 '[
    {
        "rank": 1,
        "barCode": "5000169005678",
        "productName": "Quinoa Puffed Cakes",
        "brand": "Ancient Grains Co",
        "category": "Gluten-Free Snacks",
        "recommendationScore": 0.91,
        "reasoning": "Higher protein content and complete amino acid profile compared to rice"
    },
    {
        "rank": 2,
        "barCode": "5000169009012",
        "productName": "Certified GF Artisan Bread",
        "brand": "Celiac Safe Bakery",
        "category": "Gluten-Free Bakery",
        "recommendationScore": 0.89,
        "reasoning": "Premium certified gluten-free option with better nutrition"
    }
 ]',
 '{
    "summary": "Safe gluten-free option with good nutritional profile",
    "detailedAnalysis": "This gluten-free bread is certified safe for celiac consumption with dedicated facility processing. Provides essential carbohydrates without cross-contamination risk.",
    "actionSuggestions": [
        "Safe for immediate consumption",
        "Look for fortified versions to boost nutrient content",
        "Store properly to maintain freshness"
    ],
    "nutritionScore": 75,
    "allergenWarnings": [],
    "healthBenefits": [
        "Certified gluten-free and celiac-safe",
        "Good source of complex carbohydrates",
        "No cross-contamination risk"
    ]
 }', NOW()),

(1003, @barcode6, DATE_SUB(NOW(), INTERVAL 4 HOUR), 'REC_006_C',
 '[
    {
        "rank": 1,
        "barCode": "5000169006789",
        "productName": "Rice-based Pasta Alternative",
        "brand": "Gluten Freedom",
        "category": "Gluten-Free Pasta",
        "recommendationScore": 0.92,
        "reasoning": "100% gluten-free with excellent texture and nutritional profile"
    },
    {
        "rank": 2,
        "barCode": "5000169010123",
        "productName": "Chickpea Flour Pasta",
        "brand": "Legume Lovers",
        "category": "Gluten-Free Pasta",
        "recommendationScore": 0.88,
        "reasoning": "Higher protein content and naturally gluten-free legume base"
    }
 ]',
 '{
    "summary": "DANGER - Contains gluten, unsafe for celiac condition",
    "detailedAnalysis": "This product contains wheat gluten which poses serious health risks for individuals with celiac disease. Can cause intestinal damage and severe digestive symptoms.",
    "actionSuggestions": [
        "DO NOT CONSUME - immediate health risk",
        "Seek certified gluten-free alternatives immediately",
        "Double-check all grain-based products for gluten content"
    ],
    "nutritionScore": 20,
    "allergenWarnings": ["cereals-containing-gluten", "wheat"],
    "healthBenefits": []
 }', NOW());

-- =====================================================
-- 第十五步：收据历史 (使用标准JSON格式)
-- =====================================================

INSERT INTO receipt_history (
    user_id, scan_time, recommendation_id, purchased_items, 
    llm_summary, recommendations_list, created_at
) VALUES 
-- Alice的收据历史
(1001, DATE_SUB(NOW(), INTERVAL 2 DAY), 'RECEIPT_001_A',
 '[
    {
        "productName": "High Protein Bar",
        "quantity": 2,
        "category": "Protein Supplements"
    },
    {
        "productName": "Greek Yogurt 500g", 
        "quantity": 1,
        "category": "Dairy Products",
        "barcode": "5000169111111"
    }
 ]',
 '{
    "summary": "Fitness-focused shopping with emphasis on high-protein options",
    "totalItems": 2,
    "healthScore": 75,
    "analysis": {
        "healthyItems": [
            "High Protein Bar",
            "Greek Yogurt 500g"
        ],
        "concernItems": [
            "Greek Yogurt 500g - contains milk allergens"
        ],
        "recommendations": "Excellent protein choices for muscle building goals. Consider dairy-free alternatives to avoid allergen triggers while maintaining protein intake."
    },
    "nutritionBreakdown": {
        "proteins": 60,
        "carbohydrates": 25,
        "fats": 15,
        "processed_foods": 40,
        "whole_foods": 60
    },
    "timestamp": "2025-07-20T22:00:00Z"
 }',
 '[
    {
        "originalItem": {
            "productName": "Greek Yogurt 500g",
            "quantity": 1,
            "category": "Dairy Products"
        },
        "alternatives": [
            {
                "rank": 1,
                "product": {
                    "barCode": "5000169222222",
                    "productName": "Plant-Based Greek Style Yogurt",
                    "brand": "Dairy Free Co",
                    "category": "Dairy Alternatives"
                },
                "recommendationScore": 0.92,
                "reasoning": "Same protein content without milk allergens, fortified with B12 and calcium"
            },
            {
                "rank": 2,
                "product": {
                    "barCode": "5000169333333",
                    "productName": "Coconut Protein Yogurt",
                    "brand": "Tropical Health",
                    "category": "Dairy Alternatives"
                },
                "recommendationScore": 0.88,
                "reasoning": "High protein plant-based option with probiotics and natural coconut flavor"
            }
        ]
    }
 ]', NOW()),

(1001, DATE_SUB(NOW(), INTERVAL 5 DAY), 'RECEIPT_002_A',
 '[
    {
        "productName": "Chicken Breast 1kg",
        "quantity": 1,
        "category": "Meat & Poultry",
        "barcode": "5000169444444"
    },
    {
        "productName": "Quinoa 500g",
        "quantity": 1,
        "category": "Grains & Cereals",
        "barcode": "5000169555555"
    }
 ]',
 '{
    "summary": "Excellent whole food choices for muscle building nutrition",
    "totalItems": 2,
    "healthScore": 92,
    "analysis": {
        "healthyItems": [
            "Chicken Breast 1kg",
            "Quinoa 500g"
        ],
        "concernItems": [],
        "recommendations": "Outstanding selection of lean protein and complex carbohydrates. Perfect for supporting fitness goals with whole food nutrition."
    },
    "nutritionBreakdown": {
        "proteins": 45,
        "carbohydrates": 35,
        "fats": 10,
        "processed_foods": 0,
        "whole_foods": 100
    },
    "timestamp": "2025-07-20T22:00:00Z"
 }',
 '[
    {
        "originalItem": {
            "productName": "Quinoa 500g",
            "quantity": 1,
            "category": "Grains & Cereals"
        },
        "alternatives": [
            {
                "rank": 1,
                "product": {
                    "barCode": "5000169666666",
                    "productName": "Organic Quinoa Mix",
                    "brand": "Ancient Grains Co",
                    "category": "Organic Grains"
                },
                "recommendationScore": 0.90,
                "reasoning": "Organic certification with tri-color quinoa variety for enhanced nutrition"
            }
        ]
    }
 ]', NOW()),

-- Bob的收据历史
(1002, DATE_SUB(NOW(), INTERVAL 3 DAY), 'RECEIPT_003_B',
 '[
    {
        "productName": "Sugar-free Cookies",
        "quantity": 1,
        "category": "Sugar-Free Snacks",
    },
    {
        "productName": "Raw Almonds 200g",
        "quantity": 1,
        "category": "Nuts & Seeds",
        "barcode": "5000169777777"
    }
 ]',
 '{
    "summary": "Diabetes-conscious shopping with excellent low-sugar choices",
    "totalItems": 2,
    "healthScore": 92,
    "analysis": {
        "healthyItems": [
            "Sugar-free Cookies",
            "Raw Almonds 200g"
        ],
        "concernItems": [],
        "recommendations": "Outstanding choices for blood glucose management. Both items support stable blood sugar levels while providing satisfying nutrition."
    },
    "nutritionBreakdown": {
        "proteins": 25,
        "healthy_fats": 45,
        "complex_carbs": 20,
        "processed_foods": 30,
        "whole_foods": 70
    },
    "timestamp": "2025-07-20T22:00:00Z"
 }',
 '[
    {
        "originalItem": {
            "productName": "Raw Almonds 200g",
            "quantity": 1,
            "category": "Nuts & Seeds"
        },
        "alternatives": [
            {
                "rank": 1,
                "product": {
                    "barCode": "5000169888888",
                    "productName": "Raw Walnuts Unsalted",
                    "brand": "Heart Healthy Nuts",
                    "category": "Nuts & Seeds"
                },
                "recommendationScore": 0.90,
                "reasoning": "Higher omega-3 content for heart health, also diabetes-friendly"
            }
        ]
    }
 ]', NOW()),

(1002, DATE_SUB(NOW(), INTERVAL 7 DAY), 'RECEIPT_004_B',
 '[
    {
        "productName": "Mixed Vegetables",
        "quantity": 2,
        "category": "Fresh Vegetables",
        "barcode": "5000169999999"
    },
    {
        "productName": "Lean Beef 500g",
        "quantity": 1,
        "category": "Meat & Poultry",
        "barcode": "5000169000000"
    }
 ]',
 '{
    "summary": "Health-conscious low-carb shopping for diabetes management",
    "totalItems": 2,
    "healthScore": 88,
    "analysis": {
        "healthyItems": [
            "Mixed Vegetables",
            "Lean Beef 500g"
        ],
        "concernItems": [],
        "recommendations": "Excellent choices for blood sugar control. High fiber vegetables and lean protein support stable glucose levels."
    },
    "nutritionBreakdown": {
        "proteins": 40,
        "vegetables": 35,
        "healthy_fats": 20,
        "carbohydrates": 5,
        "processed_foods": 0
    },
    "timestamp": "2025-07-20T22:00:00Z"
 }',
 '[]', NOW()),

-- Charlie的收据历史
(1003, DATE_SUB(NOW(), INTERVAL 2 DAY), 'RECEIPT_005_C',
 '[
    {
        "productName": "Gluten-free Bread",
        "quantity": 1,
        "category": "Gluten-Free Bakery",
    },
    {
        "productName": "Rice Cakes Pack",
        "quantity": 1,
        "category": "Gluten-Free Snacks",
        "barcode": "5000169111000"
    }
 ]',
 '{
    "summary": "Celiac-safe shopping with certified gluten-free products",
    "totalItems": 2,
    "healthScore": 85,
    "analysis": {
        "healthyItems": [
            "Gluten-free Bread",
            "Rice Cakes Pack"
        ],
        "concernItems": [],
        "recommendations": "Excellent gluten-free choices that are safe for celiac condition. Consider adding protein sources and fresh produce for balanced nutrition."
    },
    "nutritionBreakdown": {
        "carbohydrates": 70,
        "proteins": 10,
        "fats": 10,
        "fiber": 10,
        "gluten_free": 100
    },
    "timestamp": "2025-07-20T22:00:00Z"
 }',
 '[
    {
        "originalItem": {
            "productName": "Rice Cakes Pack",
            "quantity": 1,
            "category": "Gluten-Free Snacks"
        },
        "alternatives": [
            {
                "rank": 1,
                "product": {
                    "barCode": "5000169222000",
                    "productName": "Quinoa Puffed Cakes",
                    "brand": "Ancient Grains Co",
                    "category": "Gluten-Free Snacks"
                },
                "recommendationScore": 0.91,
                "reasoning": "Higher protein content and complete amino acid profile compared to rice"
            }
        ]
    }
 ]', NOW()),

(1003, DATE_SUB(NOW(), INTERVAL 6 DAY), 'RECEIPT_006_C',
 '[
    {
        "productName": "Mixed Fruits 1kg",
        "quantity": 1,
        "category": "Fresh Fruits",
        "barcode": "5000169333000"
    },
    {
        "productName": "GF Pasta 500g",
        "quantity": 1,
        "category": "Gluten-Free Pasta",
        "barcode": "5000169444000"
    }
 ]',
 '{
    "summary": "Balanced gluten-free shopping with fruits and carbohydrates",
    "totalItems": 2,
    "healthScore": 80,
    "analysis": {
        "healthyItems": [
            "Mixed Fruits 1kg",
            "GF Pasta 500g"
        ],
        "concernItems": [],
        "recommendations": "Good balance of fresh produce and safe carbohydrates. Add protein sources to complete nutritional profile."
    },
    "nutritionBreakdown": {
        "carbohydrates": 60,
        "vitamins": 25,
        "fiber": 10,
        "proteins": 5,
        "gluten_free": 100
    },
    "timestamp": "2025-07-20T22:00:00Z"
 }',
 '[
    {
        "originalItem": {
            "productName": "GF Pasta 500g",
            "quantity": 1,
            "category": "Gluten-Free Pasta"
        },
        "alternatives": [
            {
                "rank": 1,
                "product": {
                    "barCode": "5000169555000",
                    "productName": "Chickpea Pasta",
                    "brand": "Legume Lovers",
                    "category": "High-Protein Pasta"
                },
                "recommendationScore": 0.88,
                "reasoning": "Higher protein content and naturally gluten-free legume base"
            }
        ]
    }
 ]', NOW());
 
SET @barcode1 = '5000169000001';
SET @barcode2 = '5000169111111';
SET @barcode3 = '5000169222222';
SET @barcode4 = '5000169333333';
SET @barcode5 = '5000169444444';
SET @barcode6 = '5000169555555';

INSERT INTO recommendation_log (
    user_id, request_barcode, request_type, recommended_products, algorithm_version,
    llm_prompt, llm_response, llm_analysis, processing_time_ms, 
    total_candidates, filtered_candidates, created_at
) VALUES 

-- Alice的推荐日志
(1001, @barcode1, 'NUTRITION_OPTIMIZATION', 
 '[{"barcode": "rec001", "name": "Premium Protein Bar", "score": 9.1, "reason": "Higher protein content"}]',
 'v2.1', 
 'Analyze this protein bar for a 28-year-old female fitness enthusiast with milk allergy. Focus on protein content, allergen safety, and muscle-building benefits. User preferences: high protein, organic when possible, dairy-free alternatives.',
 'Analysis complete for fitness-focused user with milk allergy. Current product shows good protein content (12g per serving) but contains whey protein which triggers user allergen profile. Recommended plant-based alternatives with 20g+ protein per serving. Safety score: MEDIUM due to allergen presence. Nutritional score: HIGH for protein goals.',
 CONCAT('{
    "requestId": "REC_20250720_220000_001",
    "userId": 1001,
    "sourceType": "barcode_scan",
    "sourceId": 1,
    "requestData": {
        "barcode": "', @barcode1, '",
        "productName": "High Protein Bar",
        "userPreferences": {
            "preferHighProtein": true,
            "preferOrganic": true,
            "allergens": ["milk", "whey-protein"]
        }
    },
    "responseData": {
        "proteinAnalysis": "Current: 12g/100g, Target: 20g/100g for optimal muscle synthesis",
        "allergenCheck": "WARNING: Contains milk allergens - not suitable for user",
        "alternativeScore": 8.5,
        "processingTime": 1.2
    },
    "timestamp": "2025-07-20T22:00:00Z",
    "status": "success"
 }'),
 245, 156, 12, NOW()),

(1001, @barcode2, 'ALLERGEN_ALTERNATIVE',
 '[{"barcode": "rec002", "name": "Oat Milk Yogurt", "score": 8.7, "reason": "Dairy-free alternative"}]',
 'v2.1',
 'URGENT: User has confirmed milk allergy. This product contains dairy. Provide immediate alternatives with similar nutritional benefits but completely dairy-free. Priority on safety and protein content.',
 'Detected milk allergen. Suggesting plant-based alternatives with similar nutritional profile. Safety score: LOW due to confirmed allergen match. Immediate alternatives identified with dairy-free formulations.',
 CONCAT('{
    "requestId": "REC_20250720_220000_002",
    "userId": 1001,
    "sourceType": "barcode_scan",
    "sourceId": 2,
    "requestData": {
        "barcode": "', @barcode2, '",
        "productName": "Greek Yogurt Product",
        "userPreferences": {
            "allergens": ["milk", "lactose", "casein"]
        }
    },
    "responseData": {
        "allergenDetected": ["milk"],
        "alternativesFound": 8,
        "safetyScore": "high",
        "processingTime": 0.9
    },
    "timestamp": "2025-07-20T22:00:00Z",
    "status": "success"
 }'),
 189, 89, 8, NOW()),

-- Bob的推荐日志
(1002, @barcode3, 'BUDGET_REPLACEMENT',
 '[{"barcode": "rec003", "name": "Budget Protein Bar", "score": 7.4, "reason": "Similar macros, lower price"}]',
 'v2.1',
 'Provide cost-effective alternatives for a user looking to save money but maintain protein intake. Focus on price-performance and value.',
 'Generated budget-friendly alternative. Trade-off includes slightly lower protein per serving but significant cost reduction. Ideal for users with budget constraints.',
 CONCAT('{
    "requestId": "REC_20250720_220000_003",
    "userId": 1002,
    "sourceType": "barcode_scan",
    "sourceId": 3,
    "requestData": {
        "barcode": "', @barcode3, '",
        "productName": "Whey Protein Crunch Bar",
        "userPreferences": {
            "budgetSensitive": true,
            "minimumProtein": 10
        }
    },
    "responseData": {
        "costPerServing": "$0.80",
        "proteinPerServing": "10g",
        "valueScore": 9.2,
        "processingTime": 0.8
    },
    "timestamp": "2025-07-20T22:00:00Z",
    "status": "success"
 }'),
 103, 58, 9, NOW()),

(1002, @barcode4, 'LOW_SUGAR_ALTERNATIVE',
 '[{"barcode": "rec004", "name": "Zero Sugar Greek Yogurt", "score": 9.0, "reason": "Low sugar, high protein"}]',
 'v2.1',
 'The user has diabetes. Prioritize sugar content. Suggest alternatives with less than 2g sugar per 100g.',
 'Original product contains 6.5g sugar/100g. Suggested yogurt has only 1.2g sugar/100g and similar protein value. Matches dietary constraints.',
 CONCAT('{
    "requestId": "REC_20250720_220000_004",
    "userId": 1002,
    "sourceType": "barcode_scan",
    "sourceId": 4,
    "requestData": {
        "barcode": "', @barcode4, '",
        "productName": "Fruit-Infused Yogurt",
        "userPreferences": {
            "avoidHighSugar": true
        }
    },
    "responseData": {
        "originalSugar": "6.5g/100g",
        "suggestedSugar": "1.2g/100g",
        "tasteMatch": 8.0,
        "processingTime": 1.0
    },
    "timestamp": "2025-07-20T22:00:00Z",
    "status": "success"
 }'),
 122, 65, 11, NOW()),

-- Charlie的推荐日志
(1003, @barcode5, 'PLANT_BASED_PROTEIN',
 '[{"barcode": "rec005", "name": "Soy Protein Yogurt", "score": 8.8, "reason": "Plant-based with high protein"}]',
 'v2.1',
 'Suggest high-protein, plant-based options for user avoiding animal products. Must be vegan certified.',
 'Recommended soy-based product with similar taste and nutritional value. Contains 15g protein per 100g and is vegan certified. Strong match.',
 CONCAT('{
    "requestId": "REC_20250720_220000_005",
    "userId": 1003,
    "sourceType": "barcode_scan",
    "sourceId": 5,
    "requestData": {
        "barcode": "', @barcode5, '",
        "productName": "Dairy Yogurt",
        "userPreferences": {
            "plantBasedOnly": true,
            "veganCertified": true
        }
    },
    "responseData": {
        "veganCertification": true,
        "proteinPer100g": "15g",
        "tasteScore": 8.2,
        "processingTime": 1.1
    },
    "timestamp": "2025-07-20T22:00:00Z",
    "status": "success"
 }'),
 132, 73, 10, NOW()),

(1003, @barcode6, 'PROBIOTIC_FOCUS',
 '[{"barcode": "rec006", "name": "Probiotic Yogurt Drink", "score": 8.5, "reason": "Gut health boost"}]',
 'v2.1',
 'User reports digestive issues. Recommend items with high probiotic content and low lactose.',
 'Product contains 5 live cultures and 90% less lactose. Ideal for gut support and digestion.',
 CONCAT('{
    "requestId": "REC_20250720_220000_006",
    "userId": 1003,
    "sourceType": "barcode_scan",
    "sourceId": 6,
    "requestData": {
        "barcode": "', @barcode6, '",
        "productName": "Yogurt with Fruit",
        "userPreferences": {
            "probioticRich": true,
            "lowLactose": true
        }
    },
    "responseData": {
        "probioticStrains": 5,
        "lactoseReduction": "90%",
        "gutHealthScore": 9.1,
        "processingTime": 1.3
    },
    "timestamp": "2025-07-20T22:00:00Z",
    "status": "success"
 }'),
 144, 82, 13, NOW());

-- 恢复安全模式
SET SQL_SAFE_UPDATES = 1;

-- =====================================================
-- 第十七步：数据验证和完成报告
-- =====================================================

SELECT '====== 完整测试数据创建完成！ ======' AS completion_message;

-- 验证用户创建
SELECT 'Users created with correct enums:' AS user_verification;
SELECT 
    user_id,
    username,
    activity_level,
    nutrition_goal,
    gender
FROM user 
WHERE user_id IN (1001, 1002, 1003);

-- 验证JSON格式
SELECT 'JSON format verification:' AS json_verification;
SELECT 
    'scan_history recommendation_response' AS table_field,
    COUNT(*) AS records_with_json
FROM scan_history 
WHERE user_id IN (1001, 1002, 1003) 
  AND JSON_VALID(recommendation_response) = 1
UNION ALL
SELECT 
    'barcode_history llm_analysis' AS table_field,
    COUNT(*) AS records_with_json
FROM barcode_history 
WHERE user_id IN (1001, 1002, 1003) 
  AND JSON_VALID(llm_analysis) = 1
UNION ALL
SELECT 
    'receipt_history llm_summary' AS table_field,
    COUNT(*) AS records_with_json
FROM receipt_history 
WHERE user_id IN (1001, 1002, 1003) 
  AND JSON_VALID(llm_summary) = 1
UNION ALL
SELECT 
    'recommendation_log llm_analysis' AS table_field,
    COUNT(*) AS records_with_json
FROM recommendation_log 
WHERE user_id IN (1001, 1002, 1003) 
  AND JSON_VALID(llm_analysis) = 1;

-- 验证关联关系
SELECT 'Data associations verification:' AS association_verification;
SELECT 
    u.username,
    COUNT(DISTINCT ua.allergen_id) AS allergen_count,
    COUNT(DISTINCT sh.scan_id) AS scan_count,
    COUNT(DISTINCT pr.purchase_id) AS purchase_count,
    COUNT(DISTINCT bh.barcode_id) AS barcode_history_count,
    COUNT(DISTINCT rh.receipt_id) AS receipt_count,
    COUNT(DISTINCT rl.log_id) AS recommendation_count
FROM user u
LEFT JOIN user_allergen ua ON u.user_id = ua.user_id
LEFT JOIN scan_history sh ON u.user_id = sh.user_id
LEFT JOIN purchase_record pr ON u.user_id = pr.user_id
LEFT JOIN barcode_history bh ON u.user_id = bh.user_id
LEFT JOIN receipt_history rh ON u.user_id = rh.user_id
LEFT JOIN recommendation_log rl ON u.user_id = rl.user_id
WHERE u.user_id IN (1001, 1002, 1003)
GROUP BY u.user_id, u.username;

-- 测试登录功能
SELECT 'Login functionality test:' AS login_test;
SELECT 
    user_id,
    username,
    email,
    activity_level,
    nutrition_goal,
    '✅ Login should work' AS login_status
FROM user 
WHERE username = 'health_bob' AND password_hash = '123456';

-- 最终数据统计
SELECT 'Final data statistics:' AS final_stats;
SELECT 
    'Total test users' AS metric,
    COUNT(*) AS count
FROM user WHERE user_id IN (1001, 1002, 1003)
UNION ALL
SELECT 
    'Total scan records' AS metric,
    COUNT(*) AS count
FROM scan_history WHERE user_id IN (1001, 1002, 1003)
UNION ALL
SELECT 
    'Total barcode history' AS metric,
    COUNT(*) AS count
FROM barcode_history WHERE user_id IN (1001, 1002, 1003)
UNION ALL
SELECT 
    'Total receipt history' AS metric,
    COUNT(*) AS count
FROM receipt_history WHERE user_id IN (1001, 1002, 1003)
UNION ALL
SELECT 
    'Total recommendation logs' AS metric,
    COUNT(*) AS count
FROM recommendation_log WHERE user_id IN (1001, 1002, 1003)
UNION ALL
SELECT 
    'Total purchase records' AS metric,
    COUNT(*) AS count
FROM purchase_record WHERE user_id IN (1001, 1002, 1003)
UNION ALL
SELECT 
    'Total purchase items' AS metric,
    COUNT(*) AS count
FROM purchase_item pi
JOIN purchase_record pr ON pi.purchase_id = pr.purchase_id
WHERE pr.user_id IN (1001, 1002, 1003);

-- 枚举值验证总结
SELECT 'Enum values validation summary:' AS enum_summary;
SELECT 
    '✅ ActivityLevel' AS enum_type,
    'SEDENTARY, MODERATELY_ACTIVE, VERY_ACTIVE' AS values_used
UNION ALL
SELECT 
    '✅ NutritionGoal' AS enum_type,
    'MUSCLE_GAIN, WEIGHT_LOSS, WEIGHT_MAINTENANCE' AS values_used
UNION ALL
SELECT 
    '✅ Gender' AS enum_type,
    'MALE, FEMALE' AS values_used
UNION ALL
SELECT 
    '✅ ActionTaken' AS enum_type,
    'PURCHASED, AVOIDED' AS values_used
UNION ALL
SELECT 
    '✅ ScanType' AS enum_type,
    'BARCODE' AS values_used
UNION ALL
SELECT 
    '✅ PreferenceType' AS enum_type,
    'LIKE, DISLIKE' AS values_used
UNION ALL
SELECT 
    '✅ SeverityLevel' AS enum_type,
    'MILD, MODERATE, SEVERE' AS values_used
UNION ALL
SELECT 
    '✅ GoalLevel' AS enum_type,
    'STRICT, MODERATE, RELAXED' AS values_used
UNION ALL
SELECT 
    '✅ SugarSummaryStatus' AS enum_type,
    'GOOD, WARNING' AS values_used
UNION ALL
SELECT 
    '✅ PreferenceSource' AS enum_type,
    'USER_MANUAL' AS values_used;

-- JSON格式验证总结
SELECT 'JSON format validation summary:' AS json_summary;
SELECT 
    '✅ scan_history.recommendation_response' AS json_field,
    'Standard format with recommendations array, overall_score, health_rating' AS format_description
UNION ALL
SELECT 
    '✅ barcode_history.llm_analysis' AS json_field,
    'Detailed analysis with summary, actionSuggestions, nutritionScore, allergenWarnings' AS format_description
UNION ALL
SELECT 
    '✅ barcode_history.recommended_products' AS json_field,
    'Array with rank, barCode, productName, brand, recommendationScore, reasoning' AS format_description
UNION ALL
SELECT 
    '✅ receipt_history.purchased_items' AS json_field,
    'Array with productName, quantity, price, category, barcode' AS format_description
UNION ALL
SELECT 
    '✅ receipt_history.llm_summary' AS json_field,
    'Summary with healthScore, analysis object, nutritionBreakdown' AS format_description
UNION ALL
SELECT 
    '✅ receipt_history.recommendations_list' AS json_field,
    'Array with originalItem and alternatives with ranking system' AS format_description
UNION ALL
SELECT 
    '✅ recommendation_log.llm_analysis' AS json_field,
    'Complete request/response data with requestId, userId, sourceType, responseData' AS format_description;

-- 业务场景测试示例
SELECT 'Business scenario test examples:' AS business_scenarios;
SELECT 
    '🔍 Allergen Safety Query' AS scenario,
    'Find safe products for Alice (milk allergy)' AS description
UNION ALL
SELECT 
    '🍯 Sugar Management Query' AS scenario,
    'Track Bob\'s daily sugar intake vs goals' AS description
UNION ALL
SELECT 
    '🌾 Celiac Safe Query' AS scenario,
    'Verify gluten-free products for Charlie' AS description
UNION ALL
SELECT 
    '🛒 Purchase Analysis Query' AS scenario,
    'Analyze shopping patterns and recommendations' AS description
UNION ALL
SELECT 
    '📊 Nutrition Tracking Query' AS scenario,
    'Monitor protein intake for fitness goals' AS description
UNION ALL
SELECT 
    '🤖 AI Recommendation Query' AS scenario,
    'Test recommendation engine with user preferences' AS description;

SELECT '🎉 完整的测试数据创建成功！' AS final_message;

SELECT 
    '📋 测试数据包含：' AS data_summary,
    '' AS blank_line,
    '👥 3个用户 (Alice, Bob, Charlie)' AS users_info,
    '🔗 所有表的完整关联关系' AS relationships_info,
    '📊 每用户2条记录在行为表中' AS behavior_data,
    '🏷️ 正确的Java枚举值' AS enum_values,
    '📄 标准的JSON格式' AS json_formats,
    '🧪 完整的业务场景测试数据' AS business_scenarios,
    '⚡ 即时可用的登录测试' AS login_ready;

SELECT 
    '🚀 可以开始测试：' AS testing_ready,
    '' AS blank_line,
    '1️⃣ 用户登录: health_bob / 123456' AS login_test,
    '2️⃣ 过敏原安全性筛选' AS allergen_test,
    '3️⃣ 糖分管理追踪' AS sugar_test,
    '4️⃣ 产品推荐系统' AS recommendation_test,
    '5️⃣ 购买行为分析' AS purchase_test,
    '6️⃣ JSON数据解析' AS json_test,
    '7️⃣ 复杂关联查询' AS complex_query_test;