-- ============================================
-- Grocery Guardian 测试数据填充脚本
-- 为所有表创建完整的模拟数据用于接口测试
-- ============================================

-- 禁用外键检查以便按任意顺序插入数据
SET FOREIGN_KEY_CHECKS = 0;

-- 清空所有表
TRUNCATE TABLE user;
TRUNCATE TABLE allergen;
TRUNCATE TABLE product;
TRUNCATE TABLE product_allergen;
TRUNCATE TABLE user_allergen;
TRUNCATE TABLE scan_history;
TRUNCATE TABLE purchase_record;
TRUNCATE TABLE purchase_item;
TRUNCATE TABLE sugar_goals;
TRUNCATE TABLE sugar_records;
TRUNCATE TABLE monthly_statistics;


-- ============================================
-- 1. 用户表数据 (user)
-- ============================================
INSERT INTO user (user_id, username, email, password_hash, age, gender, height_cm, weight_kg, 
                 activity_level, nutrition_goal, daily_calories_target, daily_protein_target, 
                 daily_carb_target, daily_fat_target, date_of_birth, created_at, updated_at) 
VALUES 
(1, 'alice_chen', 'alice@example.com', '$2a$10$hash123456789', 28, 'FEMALE', 165, 58.5, 
 'MODERATELY_ACTIVE', 'WEIGHT_LOSS', 1800.0, 120.0, 200.0, 60.0, '1996-03-15', '2024-01-01 10:00:00', '2024-01-01 10:00:00'),
(2, 'bob_wang', 'bob@example.com', '$2a$10$hash987654321', 35, 'MALE', 178, 75.2, 
 'VERY_ACTIVE', 'MUSCLE_GAIN', 2500.0, 180.0, 300.0, 85.0, '1989-07-22', '2024-01-02 11:00:00', '2024-01-02 11:00:00'),
(3, 'carol_liu', 'carol@example.com', '$2a$10$hash456789123', 42, 'FEMALE', 160, 65.0, 
 'SEDENTARY', 'WEIGHT_MAINTENANCE', 2000.0, 130.0, 250.0, 70.0, '1982-11-08', '2024-01-03 12:00:00', '2024-01-03 12:00:00'),
(4, 'david_zhang', 'david@example.com', '$2a$10$hash789123456', 25, 'MALE', 185, 80.0, 
 'LIGHTLY_ACTIVE', 'WEIGHT_LOSS', 2200.0, 150.0, 220.0, 75.0, '1999-05-12', '2024-01-04 13:00:00', '2024-01-04 13:00:00');

-- ============================================
-- 2. 过敏原基础数据 (allergen)
-- ============================================
INSERT INTO allergen (allergen_id, name, category, is_common, description) 
VALUES 
(1, 'Milk', 'Dairy', true, 'Lactose and milk proteins that can cause digestive issues'),
(2, 'Eggs', 'Protein', true, 'Egg proteins found in many baked goods and processed foods'),
(3, 'Peanuts', 'Nuts', true, 'Tree nuts that can cause severe allergic reactions'),
(4, 'Tree Nuts', 'Nuts', true, 'Various tree nuts including almonds, walnuts, cashews'),
(5, 'Soy', 'Legumes', true, 'Soybean proteins commonly found in processed foods'),
(6, 'Wheat', 'Grains', true, 'Gluten-containing grain used in bread and pasta'),
(7, 'Fish', 'Seafood', true, 'Various fish species and fish-derived ingredients'),
(8, 'Shellfish', 'Seafood', true, 'Crustaceans and mollusks including shrimp, crab, lobster'),
(9, 'Sesame', 'Seeds', false, 'Sesame seeds and tahini commonly found in Middle Eastern foods'),
(10, 'Sulfites', 'Additives', false, 'Preservatives used in wine, dried fruits, and processed foods');

-- ============================================
-- 3. 产品数据 (product)
-- ============================================
INSERT INTO product (barcode, name, brand, ingredients, allergens, energy_100g, energy_kcal_100g, 
                    fat_100g, saturated_fat_100g, carbohydrates_100g, sugars_100g, proteins_100g, 
                    serving_size, category) 
VALUES 
('1234567890123', 'Organic Whole Milk', 'Farm Fresh', 'Organic whole milk', 'Milk', 276.0, 66.0, 3.8, 2.4, 4.8, 4.8, 3.2, '250ml', 'Dairy'),
('2345678901234', 'Almond Butter', 'Nutty Delights', 'Roasted almonds, sea salt', 'Tree nuts', 2515.0, 601.0, 55.8, 4.2, 18.8, 4.4, 21.0, '32g', 'Spreads'),
('3456789012345', 'Gluten-Free Bread', 'Healthy Bake', 'Rice flour, potato starch, eggs, xanthan gum', 'Eggs', 1047.0, 250.0, 4.5, 1.2, 48.0, 3.2, 4.8, '2 slices', 'Bakery'),
('4567890123456', 'Wild Salmon Fillet', 'Ocean Best', 'Wild Atlantic salmon', 'Fish', 795.0, 190.0, 12.4, 3.1, 0.0, 0.0, 19.8, '150g', 'Seafood'),
('5678901234567', 'Quinoa Pasta', 'Ancient Grains', 'Quinoa flour, brown rice flour', 'None', 1464.0, 350.0, 2.8, 0.5, 72.0, 3.2, 12.0, '85g dry', 'Pasta'),
('6789012345678', 'Greek Yogurt', 'Mediterranean', 'Organic milk, live cultures', 'Milk', 511.0, 122.0, 10.0, 6.4, 4.0, 4.0, 10.0, '170g', 'Dairy'),
('7890123456789', 'Dark Chocolate', 'Cacao Dreams', 'Cacao beans, cane sugar, soy lecithin', 'Soy', 2260.0, 540.0, 35.0, 21.0, 45.0, 38.0, 8.0, '40g', 'Confectionery'),
('8901234567890', 'Coconut Water', 'Tropical Pure', 'Pure coconut water', 'None', 79.0, 19.0, 0.2, 0.2, 3.7, 2.6, 0.7, '330ml', 'Beverages'),
('9012345678901', 'Sourdough Bread', 'Artisan Bakery', 'Wheat flour, water, sourdough culture, salt', 'Wheat', 1046.0, 250.0, 1.2, 0.3, 51.0, 2.8, 8.5, '2 slices', 'Bakery'),
('0123456789012', 'Peanut Butter', 'Smooth & Creamy', 'Roasted peanuts, palm oil, salt, sugar', 'Peanuts', 2385.0, 570.0, 50.0, 10.0, 16.0, 9.0, 25.0, '32g', 'Spreads'),
('1357924680135', 'Rice Crackers', 'Crispy Bites', 'Brown rice, sesame seeds, sea salt', 'Sesame', 1673.0, 400.0, 8.0, 1.5, 80.0, 2.0, 8.0, '30g', 'Snacks'),
('2468135792468', 'Soy Sauce', 'Orient Express', 'Water, soybeans, wheat, salt', 'Soy, Wheat', 251.0, 60.0, 0.1, 0.0, 5.6, 0.8, 10.5, '15ml', 'Condiments');

-- ============================================
-- 4. 产品过敏原关联数据 (product_allergen)
-- ============================================
INSERT INTO product_allergen (barcode, allergen_id, presence_type, confidence_score) 
VALUES 
('1234567890123', 1, 'PRESENT', 1.0),
('2345678901234', 4, 'PRESENT', 0.95),
('3456789012345', 2, 'PRESENT', 0.98),
('4567890123456', 7, 'PRESENT', 1.0),
('6789012345678', 1, 'PRESENT', 1.0),
('7890123456789', 5, 'PRESENT', 0.8),
('9012345678901', 6, 'PRESENT', 1.0),
('0123456789012', 3, 'PRESENT', 1.0),
('1357924680135', 9, 'PRESENT', 0.92),
('2468135792468', 5, 'PRESENT', 0.98),
('2468135792468', 6, 'PRESENT', 0.95);

-- ============================================
-- 5. 用户过敏原关联数据 (user_allergen)
-- ============================================
INSERT INTO user_allergen (user_id, allergen_id, severity_level, confirmed, notes) 
VALUES 
(1, 1, 'MEDIUM', true, 'Lactose intolerant, can have small amounts'),
(1, 3, 'HIGH', true, 'Anaphylaxis risk - strict avoidance required'),
(2, 6, 'LOW', true, 'Gluten sensitivity, causes bloating'),
(2, 8, 'MEDIUM', false, 'Suspected shellfish allergy, needs testing'),
(3, 4, 'HIGH', true, 'Tree nut allergy confirmed by doctor'),
(3, 9, 'LOW', true, 'Sesame causes mild skin reaction'),
(4, 5, 'MEDIUM', true, 'Soy intolerance, digestive issues'),
(4, 7, 'LOW', false, 'May have fish sensitivity, monitoring');

-- ============================================
-- 6. 扫描历史数据 (scan_history) - 接口测试的核心数据
-- ============================================
INSERT INTO scan_history (user_id, barcode, scan_time, location, allergen_detected, scan_result, 
                          action_taken, scan_type, recommendation_response) 
VALUES 
-- Alice的扫描记录
(1, '1234567890123', DATE_SUB(NOW(), INTERVAL 2 DAY), 'Whole Foods Market', true, 
 '{"ocr_confidence": 0.95, "barcode_detected": true, "processing_time": 1.2}', 'NONE', 'BARCODE',
 '{"healthScore": 4.2, "recommendations": [{"product": "Oat Milk", "reason": "Lactose-free alternative"}, {"product": "Almond Milk", "reason": "Lower calories"}], "nutritionSummary": {"calories": 66, "protein": 3.2, "carbs": 4.8, "fat": 3.8}, "allergenWarnings": ["Contains milk - you are lactose intolerant"]}'),

(1, '5678901234567', DATE_SUB(NOW(), INTERVAL 2 DAY), 'Whole Foods Market', false, 
 '{"ocr_confidence": 0.88, "barcode_detected": true, "processing_time": 0.9}', 'NONE', 'BARCODE',
 '{"healthScore": 8.5, "recommendations": [{"product": "Brown Rice Pasta", "reason": "Higher fiber content"}], "nutritionSummary": {"calories": 350, "protein": 12.0, "carbs": 72.0, "fat": 2.8}, "allergenWarnings": []}'),

(1, '0123456789012', DATE_SUB(NOW(), INTERVAL 1 DAY), 'Local Grocery Store', true, 
 '{"ocr_confidence": 0.92, "barcode_detected": true, "processing_time": 1.5}', 'REMOVE', 'BARCODE',
 '{"healthScore": 2.1, "recommendations": [{"product": "Sunflower Seed Butter", "reason": "Peanut-free alternative"}, {"product": "Almond Butter", "reason": "Tree nut option"}], "nutritionSummary": {"calories": 570, "protein": 25.0, "carbs": 16.0, "fat": 50.0}, "allergenWarnings": ["DANGER: Contains peanuts - you have severe peanut allergy!"]}'),

-- Bob的扫描记录  
(2, '9012345678901', DATE_SUB(NOW(), INTERVAL 1 DAY), 'Fresh Market', true, 
 '{"ocr_confidence": 0.97, "barcode_detected": true, "processing_time": 1.1}', 'NONE', 'BARCODE',
 '{"healthScore": 6.8, "recommendations": [{"product": "Gluten-Free Bread", "reason": "Suitable for gluten sensitivity"}], "nutritionSummary": {"calories": 250, "protein": 8.5, "carbs": 51.0, "fat": 1.2}, "allergenWarnings": ["Contains wheat - you have gluten sensitivity"]}'),

(2, '4567890123456', DATE_SUB(NOW(), INTERVAL 6 HOUR), 'Fish Market', false, 
 '{"ocr_confidence": 0.99, "barcode_detected": true, "processing_time": 0.8}', 'NONE', 'BARCODE',
 '{"healthScore": 9.2, "recommendations": [{"product": "Grilled Preparation", "reason": "Healthiest cooking method"}], "nutritionSummary": {"calories": 190, "protein": 19.8, "carbs": 0.0, "fat": 12.4}, "allergenWarnings": []}'),

-- Receipt扫描记录
(2, '2345678901234', DATE_SUB(NOW(), INTERVAL 3 DAY), 'Costco', false, 
 '{"receipt_items": 5, "total_amount": 124.50, "ocr_confidence": 0.85}', 'NONE', 'RECEIPT',
 '{"healthScore": 7.8, "recommendations": [{"product": "Cashew Butter", "reason": "Different nut variety"}], "nutritionSummary": {"totalCalories": 1847, "avgProtein": 15.2, "avgCarbs": 35.4, "avgFat": 22.1}, "allergenWarnings": []}'),

-- 添加一个RECEIPT记录包含Milk产品（用于测试）
(1, '1234567890123', NOW(), 'Target Store', true, 
 '{"receipt_items": 3, "total_amount": 45.67, "ocr_confidence": 0.92}', 'NONE', 'RECEIPT',
 '{"healthScore": 4.2, "recommendations": [{"product": "Oat Milk", "reason": "Lactose-free alternative"}], "nutritionSummary": {"totalCalories": 200, "avgProtein": 5.2, "avgCarbs": 15.4, "avgFat": 8.1}, "allergenWarnings": ["Contains milk"]}'),

-- Carol的扫描记录
(3, '1357924680135', DATE_SUB(NOW(), INTERVAL 4 DAY), 'Asian Market', true, 
 '{"ocr_confidence": 0.91, "barcode_detected": true, "processing_time": 1.3}', 'NONE', 'BARCODE',
 '{"healthScore": 5.5, "recommendations": [{"product": "Plain Rice Crackers", "reason": "Sesame-free option"}], "nutritionSummary": {"calories": 400, "protein": 8.0, "carbs": 80.0, "fat": 8.0}, "allergenWarnings": ["Contains sesame - you have mild sesame allergy"]}'),

(3, '8901234567890', DATE_SUB(NOW(), INTERVAL 4 DAY), 'Health Store', false, 
 '{"ocr_confidence": 0.94, "barcode_detected": true, "processing_time": 0.7}', 'NONE', 'BARCODE',
 '{"healthScore": 8.9, "recommendations": [{"product": "Natural Hydration", "reason": "Pure and healthy"}], "nutritionSummary": {"calories": 19, "protein": 0.7, "carbs": 3.7, "fat": 0.2}, "allergenWarnings": []}'),

-- David的扫描记录
(4, '2468135792468', DATE_SUB(NOW(), INTERVAL 5 DAY), 'Restaurant Supply', true, 
 '{"ocr_confidence": 0.96, "barcode_detected": true, "processing_time": 1.0}', 'NONE', 'BARCODE',
 '{"healthScore": 4.5, "recommendations": [{"product": "Coconut Aminos", "reason": "Soy-free alternative"}, {"product": "Tamari", "reason": "Gluten-free soy sauce"}], "nutritionSummary": {"calories": 60, "protein": 10.5, "carbs": 5.6, "fat": 0.1}, "allergenWarnings": ["Contains soy - you have soy intolerance"]}'),

(4, '6789012345678', DATE_SUB(NOW(), INTERVAL 5 DAY), 'Organic Market', false, 
 '{"ocr_confidence": 0.93, "barcode_detected": true, "processing_time": 1.1}', 'NONE', 'BARCODE',
 '{"healthScore": 7.6, "recommendations": [{"product": "Coconut Yogurt", "reason": "Dairy-free option"}], "nutritionSummary": {"calories": 122, "protein": 10.0, "carbs": 4.0, "fat": 10.0}, "allergenWarnings": []}');

-- ============================================
-- 7. 购买记录数据 (purchase_record)
-- ============================================
INSERT INTO purchase_record (user_id, receipt_date, store_name, total_amount, ocr_confidence, 
                             raw_ocr_data, scan_id) 
VALUES 
(1, '2024-01-15', 'Whole Foods Market', 45.67, 0.92, 
 '{"store_info": {"name": "Whole Foods Market", "address": "123 Main St"}, "items": ["Organic Milk", "Quinoa Pasta"], "subtotal": 42.18, "tax": 3.49, "total": 45.67}', 2),
(2, '2024-01-18', 'Costco', 124.50, 0.85, 
 '{"store_info": {"name": "Costco Wholesale", "address": "456 Warehouse Blvd"}, "items": ["Almond Butter", "Salmon Fillet", "Greek Yogurt"], "subtotal": 115.28, "tax": 9.22, "total": 124.50}', 6),
(3, '2024-01-19', 'Health Store', 23.45, 0.89, 
 '{"store_info": {"name": "Natural Health Store", "address": "789 Wellness Ave"}, "items": ["Coconut Water"], "subtotal": 21.73, "tax": 1.72, "total": 23.45}', 8),
(4, '2024-01-20', 'Organic Market', 67.89, 0.91, 
 '{"store_info": {"name": "Organic Market", "address": "321 Green St"}, "items": ["Soy Sauce", "Greek Yogurt"], "subtotal": 62.87, "tax": 5.02, "total": 67.89}', 10);

-- ============================================
-- 8. 购买商品明细数据 (purchase_item)
-- ============================================
INSERT INTO purchase_item (purchase_id, barcode, item_name_ocr, match_confidence, quantity, 
                          unit_price, total_price, estimated_servings, total_calories, 
                          total_proteins, total_carbs, total_fat) 
VALUES 
-- Purchase 1 items
(1, '1234567890123', 'Organic Whole Milk', 0.95, 2, 4.99, 9.98, 8.0, 528.0, 25.6, 38.4, 30.4),
(1, '5678901234567', 'Quinoa Pasta', 0.93, 3, 12.73, 38.19, 12.0, 4200.0, 144.0, 864.0, 33.6),

-- Purchase 2 items  
(2, '2345678901234', 'Almond Butter', 0.97, 1, 15.99, 15.99, 15.0, 9015.0, 315.0, 282.0, 837.0),
(2, '4567890123456', 'Wild Salmon Fillet', 0.99, 4, 18.99, 75.96, 4.0, 760.0, 79.2, 0.0, 49.6),
(2, '6789012345678', 'Greek Yogurt', 0.94, 2, 5.49, 10.98, 2.0, 244.0, 20.0, 8.0, 20.0),

-- Purchase 3 items
(3, '8901234567890', 'Coconut Water', 0.96, 6, 3.99, 23.94, 6.0, 114.0, 4.2, 22.2, 1.2),

-- Purchase 4 items
(4, '2468135792468', 'Soy Sauce', 0.98, 2, 4.99, 9.98, 133.0, 7980.0, 1396.5, 745.6, 13.3),
(4, '6789012345678', 'Greek Yogurt', 0.94, 4, 5.49, 21.96, 4.0, 488.0, 40.0, 16.0, 40.0);

-- ============================================
-- 9. 糖分目标数据 (sugar_goals)
-- ============================================
INSERT INTO sugar_goals (user_id, daily_goal_mg, goal_level, created_at, updated_at, is_active) 
VALUES 
(1, 25000.0, 'STRICT', '2024-01-01 10:00:00', '2024-01-15 14:30:00', true),
(2, 35000.0, 'MODERATE', '2024-01-02 11:00:00', '2024-01-16 09:20:00', true),
(3, 30000.0, 'MODERATE', '2024-01-03 12:00:00', '2024-01-17 16:45:00', true),
(4, 40000.0, 'RELAXED', '2024-01-04 13:00:00', '2024-01-18 11:15:00', true);

-- ============================================
-- 10. 糖分摄入记录数据 (sugar_records)
-- ============================================
INSERT INTO sugar_records (user_id, food_name, sugar_amount_mg, quantity, consumed_at, 
                          product_barcode, source, notes, created_at) 
VALUES 
(1, 'Organic Whole Milk', 4800.0, 1.0, '2024-01-15 10:30:00', '1234567890123', 'SCAN', 'Breakfast cereal', '2024-01-15 10:30:00'),
(1, 'Quinoa Pasta', 3200.0, 1.0, '2024-01-15 18:45:00', '5678901234567', 'SCAN', 'Dinner portion', '2024-01-15 18:45:00'),
(2, 'Sourdough Bread', 2800.0, 2.0, '2024-01-16 08:15:00', '9012345678901', 'SCAN', 'Toast for breakfast', '2024-01-16 08:15:00'),
(2, 'Wild Salmon Fillet', 0.0, 1.0, '2024-01-17 19:30:00', '4567890123456', 'SCAN', 'Grilled salmon dinner', '2024-01-17 19:30:00'),
(3, 'Rice Crackers', 2000.0, 1.0, '2024-01-19 15:20:00', '1357924680135', 'SCAN', 'Afternoon snack', '2024-01-19 15:20:00'),
(3, 'Coconut Water', 2600.0, 1.0, '2024-01-19 16:00:00', '8901234567890', 'SCAN', 'Post-workout hydration', '2024-01-19 16:00:00'),
(4, 'Soy Sauce', 800.0, 0.1, '2024-01-20 12:45:00', '2468135792468', 'SCAN', 'Cooking seasoning', '2024-01-20 12:45:00'),
(4, 'Greek Yogurt', 4000.0, 1.0, '2024-01-20 20:15:00', '6789012345678', 'SCAN', 'Evening snack', '2024-01-20 20:15:00');

-- ============================================
-- 11. 月度统计数据 (monthly_statistics)
-- ============================================
INSERT INTO monthly_statistics (user_id, year, month, receipt_uploads, total_products, total_spent, 
                               category_breakdown, popular_products, nutrition_breakdown, 
                               calculated_at, updated_at) 
VALUES 
(1, 2024, 1, 2, 8, 45.67, 
 '{"Dairy": 2, "Pasta": 1, "Spreads": 1, "Beverages": 1}', 
 '{"Organic Whole Milk": 2, "Quinoa Pasta": 1}',
 '{"avg_calories": 245.5, "total_protein": 156.8, "total_carbs": 338.4, "total_fat": 98.2}',
 '2024-01-31 23:59:59', '2024-01-31 23:59:59'),
(2, 2024, 1, 3, 12, 124.50,
 '{"Bakery": 1, "Seafood": 1, "Spreads": 1, "Dairy": 1}',
 '{"Wild Salmon Fillet": 4, "Greek Yogurt": 2}',
 '{"avg_calories": 334.2, "total_protein": 287.8, "total_carbs": 198.6, "total_fat": 156.4}',
 '2024-01-31 23:59:59', '2024-01-31 23:59:59'),
(3, 2024, 1, 1, 4, 23.45,
 '{"Snacks": 1, "Beverages": 1}',
 '{"Coconut Water": 6, "Rice Crackers": 1}',
 '{"avg_calories": 209.5, "total_protein": 12.2, "total_carbs": 51.9, "total_fat": 4.1}',
 '2024-01-31 23:59:59', '2024-01-31 23:59:59'),
(4, 2024, 1, 2, 6, 67.89,
 '{"Condiments": 1, "Dairy": 1}',
 '{"Greek Yogurt": 4, "Soy Sauce": 2}',
 '{"avg_calories": 91.0, "total_protein": 718.3, "total_carbs": 380.8, "total_fat": 26.7}',
 '2024-01-31 23:59:59', '2024-01-31 23:59:59');

-- 恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- 验证数据插入成功
-- ============================================
SELECT 'Data insertion completed successfully!' as Status;

-- 显示各表的记录数量
SELECT 
  'user' as table_name, COUNT(*) as record_count FROM user
UNION ALL SELECT 
  'allergen', COUNT(*) FROM allergen  
UNION ALL SELECT 
  'product', COUNT(*) FROM product
UNION ALL SELECT 
  'product_allergen', COUNT(*) FROM product_allergen
UNION ALL SELECT 
  'user_allergen', COUNT(*) FROM user_allergen
UNION ALL SELECT 
  'scan_history', COUNT(*) FROM scan_history
UNION ALL SELECT 
  'purchase_record', COUNT(*) FROM purchase_record
UNION ALL SELECT 
  'purchase_item', COUNT(*) FROM purchase_item
UNION ALL SELECT 
  'sugar_goals', COUNT(*) FROM sugar_goals
UNION ALL SELECT 
  'sugar_records', COUNT(*) FROM sugar_records
UNION ALL SELECT 
  'monthly_statistics', COUNT(*) FROM monthly_statistics
ORDER BY table_name;

-- ============================================
-- 示例查询：验证用户历史记录接口数据
-- ============================================
-- 查看用户1的扫描历史（模拟接口调用）
SELECT 
    sh.scan_id,
    sh.user_id,
    sh.barcode,
    p.name as product_name,
    p.brand as product_brand,
    sh.scan_time,
    sh.location,
    sh.allergen_detected,
    sh.action_taken,
    sh.scan_type,
    sh.recommendation_response
FROM scan_history sh
LEFT JOIN product p ON sh.barcode = p.barcode
WHERE sh.user_id = 1
ORDER BY sh.scan_time DESC; 