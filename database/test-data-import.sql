-- =====================================================
-- Grocery Guardian Test Data Import
-- File: test-data-import.sql
-- Purpose: Generate test data for all tables
-- =====================================================

-- 清理数据（按外键依赖逆序删除）
SET FOREIGN_KEY_CHECKS = 0;

-- 清理依赖表
DELETE FROM recommendation_log;
DELETE FROM purchase_item;
DELETE FROM purchase_record;
DELETE FROM scan_history;
DELETE FROM monthly_statistics;
DELETE FROM sugar_intake_history;
DELETE FROM sugar_goals;
DELETE FROM user_allergen;
DELETE FROM user_preference;
DELETE FROM product_preference;

-- 清理基础表
DELETE FROM allergen;
DELETE FROM product;
DELETE FROM user;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- 1. 用户表 (user) - 基础表
-- =====================================================
INSERT INTO user (user_id, username, email, password_hash, age, gender, height_cm, weight_kg, activity_level, nutrition_goal, daily_calories_target, daily_protein_target, daily_carb_target, daily_fat_target, date_of_birth, created_at, updated_at) VALUES
(1, 'alice_chen', 'alice.chen@example.com', '123456', 28, 'FEMALE', 165, 58.5, 'MODERATELY_ACTIVE', 'WEIGHT_LOSS', 1800.0, 90.0, 180.0, 60.0, '1995-03-15', '2024-01-15 10:30:00', '2024-12-25 14:20:00'),
(2, 'bob_smith', 'bob.smith@example.com', '123456', 35, 'MALE', 178, 75.2, 'VERY_ACTIVE', 'MUSCLE_GAIN', 2500.0, 125.0, 250.0, 80.0, '1988-07-22', '2024-02-20 09:15:00', '2024-12-26 08:45:00'),
(3, 'carol_wang', 'carol.wang@example.com', '123456', 42, 'FEMALE', 160, 62.0, 'LIGHTLY_ACTIVE', 'HEALTH_MAINTENANCE', 2000.0, 80.0, 200.0, 65.0, '1981-11-08', '2024-03-10 16:45:00', '2024-12-24 11:30:00'),
(4, 'david_liu', 'david.liu@example.com', '123456', 26, 'MALE', 172, 68.8, 'MODERATELY_ACTIVE', 'WEIGHT_LOSS', 2200.0, 110.0, 200.0, 70.0, '1997-05-14', '2024-04-05 13:20:00', '2024-12-25 16:10:00'),
(5, 'emma_brown', 'emma.brown@example.com', '123456', 31, 'FEMALE', 168, 55.3, 'VERY_ACTIVE', 'MUSCLE_GAIN', 2300.0, 115.0, 230.0, 75.0, '1992-09-03', '2024-05-12 11:00:00', '2024-12-26 09:25:00');

-- =====================================================
-- 2. 过敏原表 (allergen) - 基础表
-- =====================================================
INSERT INTO allergen (allergen_id, name, category, is_common, description) VALUES
(1, 'Milk', 'Dairy', true, 'Contains lactose and milk proteins including casein and whey'),
(2, 'Eggs', 'Animal Products', true, 'Chicken eggs and egg-derived ingredients'),
(3, 'Fish', 'Seafood', true, 'All fish species including salmon, tuna, cod'),
(4, 'Crustacean Shellfish', 'Seafood', true, 'Shrimp, crab, lobster, crayfish'),
(5, 'Tree Nuts', 'Nuts', true, 'Almonds, walnuts, pecans, hazelnuts, cashews'),
(6, 'Peanuts', 'Legumes', true, 'Groundnuts and peanut-derived products'),
(7, 'Wheat', 'Grains', true, 'Contains gluten protein'),
(8, 'Soybeans', 'Legumes', true, 'Soy protein and soy-derived ingredients'),
(9, 'Sesame Seeds', 'Seeds', true, 'Sesame oil, tahini, and sesame-containing products'),
(10, 'Sulfites', 'Preservatives', false, 'Sulfur dioxide and sulfite preservatives'),
(11, 'Mustard', 'Condiments', false, 'Mustard seeds and mustard-based products'),
(12, 'Celery', 'Vegetables', false, 'Celery stalks, leaves, and celery salt');

-- =====================================================
-- 3. 产品表 (product) - 基础表
-- =====================================================
INSERT INTO product (barcode, name, brand, ingredients, allergens, energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g, carbohydrates_100g, sugars_100g, proteins_100g, serving_size, category) VALUES
('7622210951915', 'Oreo Original Cookies', 'Nabisco', 'Sugar, wheat flour, palm oil, cocoa powder, glucose-fructose syrup, raising agents', 'Contains: Wheat, May contain: Milk, Eggs, Soy', 2200.0, 480.0, 20.0, 9.0, 71.0, 36.0, 4.7, '100g', 'Biscuits & Cookies'),
('4000417025005', 'Coca-Cola Classic', 'Coca-Cola', 'Carbonated water, sugar, natural flavoring, phosphoric acid, caffeine', 'None', 180.0, 42.0, 0.0, 0.0, 10.6, 10.6, 0.0, '330ml', 'Soft Drinks'),
('5449000131805', 'Sprite Lemon-Lime', 'Coca-Cola', 'Carbonated water, sugar, citric acid, natural lemon-lime flavoring', 'None', 142.0, 34.0, 0.0, 0.0, 8.5, 8.5, 0.0, '330ml', 'Soft Drinks'),
('8901030875827', 'Maggi 2-Minute Noodles', 'Nestle', 'Wheat flour, palm oil, salt, flavor enhancers, spices', 'Contains: Wheat, May contain: Milk, Eggs, Soy', 1900.0, 450.0, 18.0, 9.0, 62.0, 3.2, 10.0, '70g', 'Instant Noodles'),
('3017620422003', 'Nutella Hazelnut Spread', 'Ferrero', 'Sugar, palm oil, hazelnuts, cocoa powder, milk powder, lecithin, vanillin', 'Contains: Milk, Tree Nuts (Hazelnuts), May contain: Other nuts', 2252.0, 539.0, 30.9, 10.6, 57.5, 56.3, 6.3, '400g', 'Spreads'),
('8410076472113', 'Doritos Nacho Cheese', 'Frito-Lay', 'Corn, vegetable oil, cheese seasoning, salt, natural flavors', 'Contains: Milk', 2100.0, 498.0, 25.0, 4.5, 62.0, 2.5, 7.0, '150g', 'Snacks'),
('5000169005590', 'Cadbury Dairy Milk Chocolate', 'Cadbury', 'Milk chocolate, sugar, cocoa butter, milk powder, cocoa mass, emulsifiers', 'Contains: Milk, May contain: Nuts', 2150.0, 514.0, 30.0, 18.0, 57.0, 56.0, 7.3, '200g', 'Chocolate'),
('4006381333610', 'Haribo Goldbears Gummy Bears', 'Haribo', 'Glucose syrup, sugar, gelatin, fruit juice concentrates, acidulants', 'None', 1420.0, 338.0, 0.1, 0.1, 77.0, 46.0, 6.9, '200g', 'Candy'),
('8712100854565', 'Red Bull Energy Drink', 'Red Bull', 'Water, sucrose, glucose, citric acid, taurine, caffeine, vitamins', 'None', 230.0, 45.0, 0.0, 0.0, 11.0, 11.0, 0.0, '250ml', 'Energy Drinks'),
('5449000000996', 'Fanta Orange', 'Coca-Cola', 'Carbonated water, sugar, orange juice concentrate, citric acid, natural flavors', 'None', 172.0, 41.0, 0.0, 0.0, 10.3, 10.3, 0.0, '330ml', 'Soft Drinks');

-- =====================================================
-- 4. 用户偏好表 (user_preference) - 一级依赖
-- =====================================================
INSERT INTO user_preference (preference_id, user_id, prefer_low_sugar, prefer_low_fat, prefer_high_protein, prefer_low_sodium, prefer_organic, prefer_low_calorie, preference_source, inference_confidence, version, created_at, updated_at) VALUES
(1, 1, true, true, false, true, false, true, 'USER_MANUAL', 1.0, 1, '2024-01-15 10:35:00', '2024-12-25 14:25:00'),
(2, 2, false, false, true, false, false, false, 'SYSTEM_INFERRED', 0.85, 2, '2024-02-20 09:20:00', '2024-12-26 08:50:00'),
(3, 3, true, false, false, true, true, false, 'MIXED', 0.75, 1, '2024-03-10 16:50:00', '2024-12-24 11:35:00'),
(4, 4, true, true, true, false, false, true, 'USER_MANUAL', 1.0, 1, '2024-04-05 13:25:00', '2024-12-25 16:15:00'),
(5, 5, false, false, true, false, true, false, 'SYSTEM_INFERRED', 0.92, 1, '2024-05-12 11:05:00', '2024-12-26 09:30:00');

-- =====================================================
-- 5. 用户过敏原关联表 (user_allergen) - 一级依赖
-- =====================================================
INSERT INTO user_allergen (user_allergen_id, user_id, allergen_id, severity_level, confirmed, notes) VALUES
(1, 1, 1, 'MODERATE', true, 'Lactose intolerant, can consume small amounts'),
(2, 1, 7, 'MILD', false, 'Suspected gluten sensitivity, monitoring symptoms'),
(3, 2, 5, 'SEVERE', true, 'Anaphylactic reaction to tree nuts'),
(4, 3, 2, 'MILD', true, 'Causes mild digestive issues'),
(5, 3, 8, 'MODERATE', true, 'Confirmed soy allergy'),
(6, 4, 6, 'SEVERE', true, 'Severe peanut allergy since childhood'),
(7, 5, 4, 'MODERATE', true, 'Allergic to shellfish, causes hives');

-- =====================================================
-- 6. 糖分目标表 (sugar_goals) - 一级依赖
-- =====================================================
INSERT INTO sugar_goals (id, user_id, daily_goal_mg, goal_level, created_at, updated_at) VALUES
(1, 1, 25000.0, 'STRICT', '2024-01-15 10:40:00', '2024-12-25 14:30:00'),
(2, 2, 50000.0, 'MODERATE', '2024-02-20 09:25:00', '2024-12-26 08:55:00'),
(3, 3, 30000.0, 'STRICT', '2024-03-10 16:55:00', '2024-12-24 11:40:00'),
(4, 4, 35000.0, 'MODERATE', '2024-04-05 13:30:00', '2024-12-25 16:20:00'),
(5, 5, 45000.0, 'RELAXED', '2024-05-12 11:10:00', '2024-12-26 09:35:00');

-- =====================================================
-- 7. 糖分摄入历史表 (sugar_intake_history) - 一级依赖
-- =====================================================
INSERT INTO sugar_intake_history (id, user_id, food_name, sugar_amount_mg, quantity, consumed_at, barcode, created_at) VALUES
(1, 1, 'Oreo Cookies', 18000.0, 0.5, '2024-12-25 09:30:00', '7622210951915', '2024-12-25 09:30:15'),
(2, 1, 'Apple', 10000.0, 1.0, '2024-12-25 14:15:00', null, '2024-12-25 14:15:30'),
(3, 1, 'Sprite', 8500.0, 1.0, '2024-12-25 16:45:00', '5449000131805', '2024-12-25 16:45:20'),
(4, 2, 'Nutella Spread', 28150.0, 0.5, '2024-12-25 08:20:00', '3017620422003', '2024-12-25 08:20:45'),
(5, 2, 'Coca-Cola', 10600.0, 1.0, '2024-12-25 12:30:00', '4000417025005', '2024-12-25 12:30:10'),
(6, 2, 'Banana', 12000.0, 1.0, '2024-12-25 15:10:00', null, '2024-12-25 15:10:25'),
(7, 3, 'Haribo Gummy Bears', 23000.0, 0.5, '2024-12-24 10:45:00', '4006381333610', '2024-12-24 10:45:30'),
(8, 3, 'Orange Juice', 21000.0, 1.0, '2024-12-24 13:20:00', null, '2024-12-24 13:20:15'),
(9, 4, 'Cadbury Chocolate', 28000.0, 0.5, '2024-12-25 11:15:00', '5000169005590', '2024-12-25 11:15:40'),
(10, 4, 'Grapes', 16000.0, 1.0, '2024-12-25 17:30:00', null, '2024-12-25 17:30:20'),
(11, 5, 'Red Bull', 11000.0, 1.0, '2024-12-26 07:45:00', '8712100854565', '2024-12-26 07:45:35'),
(12, 5, 'Yogurt', 15000.0, 1.0, '2024-12-26 10:20:00', null, '2024-12-26 10:20:10');

-- =====================================================
-- 8. 扫描历史表 (scan_history) - 一级依赖
-- =====================================================
INSERT INTO scan_history (scan_id, user_id, barcode, scan_time, location, allergen_detected, scan_result, action_taken, scan_type, recommendation_response, created_at) VALUES
(1, 1, '7622210951915', '2024-12-25 09:29:45', 'Home Kitchen', false, '{"product_found": true, "health_score": 45}', 'PURCHASED', 'BARCODE', '{"recommendations": ["Consider low-sugar alternatives"], "health_warnings": ["High sugar content"]}', '2024-12-25 09:29:45'),
(2, 1, '5449000131805', '2024-12-25 16:44:30', 'Office', false, '{"product_found": true, "health_score": 30}', 'PURCHASED', 'BARCODE', '{"recommendations": ["Try sugar-free alternatives"], "health_warnings": ["Very high sugar"]}', '2024-12-25 16:44:30'),
(3, 2, '3017620422003', '2024-12-25 08:19:15', 'Home Kitchen', false, '{"product_found": true, "health_score": 25}', 'PURCHASED', 'BARCODE', '{"recommendations": ["Limit portion size"], "health_warnings": ["Extremely high sugar"]}', '2024-12-25 08:19:15'),
(4, 2, '4000417025005', '2024-12-25 12:29:20', 'Restaurant', false, '{"product_found": true, "health_score": 35}', 'PURCHASED', 'BARCODE', '{"recommendations": ["Consider diet version"], "health_warnings": ["High sugar content"]}', '2024-12-25 12:29:20'),
(5, 3, '4006381333610', '2024-12-24 10:44:10', 'Supermarket', false, '{"product_found": true, "health_score": 20}', 'AVOIDED', 'BARCODE', '{"recommendations": ["Choose fresh fruit instead"], "health_warnings": ["Very high sugar", "Low nutritional value"]}', '2024-12-24 10:44:10'),
(6, 4, '5000169005590', '2024-12-25 11:14:25', 'Office', false, '{"product_found": true, "health_score": 30}', 'PURCHASED', 'BARCODE', '{"recommendations": ["Enjoy in moderation"], "health_warnings": ["High sugar and fat"]}', '2024-12-25 11:14:25'),
(7, 5, '8712100854565', '2024-12-26 07:44:40', 'Gym', false, '{"product_found": true, "health_score": 40}', 'PURCHASED', 'BARCODE', '{"recommendations": ["Consider natural energy sources"], "health_warnings": ["High caffeine", "High sugar"]}', '2024-12-26 07:44:40');

-- =====================================================
-- 9. 产品偏好表 (product_preference) - 一级依赖
-- =====================================================
INSERT INTO product_preference (preference_id, user_id, barcode, preference_type, reason, created_at) VALUES
(1, 1, '7622210951915', 'DISLIKE', 'Too sweet for my taste, prefer less sugary snacks', '2024-12-25 09:35:00'),
(2, 2, '3017620422003', 'LIKE', 'Great taste but trying to limit intake due to sugar content', '2024-12-25 08:25:00'),
(3, 3, '4006381333610', 'DISLIKE', 'Decided to avoid after seeing sugar content and health warnings', '2024-12-24 10:50:00'),
(4, 4, '5000169005590', 'LIKE', 'Occasional treat, good quality chocolate', '2024-12-25 11:20:00'),
(5, 5, '8712100854565', 'NEUTRAL', 'Useful for energy but concerned about sugar content', '2024-12-26 07:50:00'),
(6, 1, '5449000131805', 'DISLIKE', 'Prefer water or unsweetened beverages', '2024-12-25 16:50:00'),
(7, 2, '4000417025005', 'LIKE', 'Classic taste but trying to reduce frequency', '2024-12-25 12:35:00');

-- =====================================================
-- 10. 购买记录表 (purchase_record) - 二级依赖
-- =====================================================
INSERT INTO purchase_record (purchase_id, user_id, receipt_date, store_name, total_amount, ocr_confidence, raw_ocr_data, scan_id) VALUES
(1, 1, '2024-12-25', 'Tesco Express', 45.80, 0.92, '{"store": "Tesco Express", "items": [{"name": "Oreo Cookies", "price": 3.50}, {"name": "Sprite 330ml", "price": 1.25}, {"name": "Bread", "price": 2.80}], "total": 45.80}', 1),
(2, 2, '2024-12-25', 'ASDA Supermarket', 67.45, 0.88, '{"store": "ASDA", "items": [{"name": "Nutella 400g", "price": 4.99}, {"name": "Coca-Cola 330ml", "price": 1.50}, {"name": "Chicken Breast", "price": 8.99}], "total": 67.45}', 3),
(3, 3, '2024-12-24', 'Sainsburys Local', 23.60, 0.95, '{"store": "Sainsburys", "items": [{"name": "Organic Apples", "price": 3.20}, {"name": "Whole Grain Bread", "price": 2.50}, {"name": "Greek Yogurt", "price": 4.80}], "total": 23.60}', 5),
(4, 4, '2024-12-25', 'Morrison\"s', 38.90, 0.90, '{"store": "Morrisons", "items": [{"name": "Cadbury Dairy Milk", "price": 3.75}, {"name": "Bananas", "price": 1.20}, {"name": "Salmon Fillet", "price": 12.99}], "total": 38.90}', 6),
(5, 5, '2024-12-26', 'Co-op Food', 15.30, 0.85, '{"store": "Co-op", "items": [{"name": "Red Bull 250ml", "price": 2.80}, {"name": "Protein Bar", "price": 3.50}, {"name": "Almonds", "price": 4.99}], "total": 15.30}', 7);

-- =====================================================
-- 11. 购买商品表 (purchase_item) - 三级依赖
-- =====================================================
INSERT INTO purchase_item (item_id, purchase_id, barcode, item_name_ocr, match_confidence, quantity, unit_price, total_price, estimated_servings) VALUES
(1, 1, '7622210951915', 'Oreo Original Cookies', 0.95, 1, 3.50, 3.50, 5.0),
(2, 1, '5449000131805', 'Sprite 330ml', 0.90, 1, 1.25, 1.25, 1.0),
(3, 1, null, 'Hovis Bread Loaf', 0.80, 1, 2.80, 2.80, 8.0),
(4, 2, '3017620422003', 'Nutella Hazelnut Spread 400g', 0.93, 1, 4.99, 4.99, 16.0),
(5, 2, '4000417025005', 'Coca-Cola Classic 330ml', 0.88, 1, 1.50, 1.50, 1.0),
(6, 2, null, 'Fresh Chicken Breast', 0.75, 1, 8.99, 8.99, 4.0),
(7, 3, null, 'Organic Apples 1kg', 0.85, 1, 3.20, 3.20, 5.0),
(8, 3, null, 'Whole Grain Bread', 0.82, 1, 2.50, 2.50, 8.0),
(9, 3, null, 'Greek Yogurt 500g', 0.90, 1, 4.80, 4.80, 5.0),
(10, 4, '5000169005590', 'Cadbury Dairy Milk 200g', 0.92, 1, 3.75, 3.75, 8.0),
(11, 4, null, 'Fresh Bananas', 0.78, 1, 1.20, 1.20, 4.0),
(12, 4, null, 'Atlantic Salmon Fillet', 0.88, 1, 12.99, 12.99, 2.0),
(13, 5, '8712100854565', 'Red Bull Energy 250ml', 0.94, 1, 2.80, 2.80, 1.0),
(14, 5, null, 'Protein Energy Bar', 0.80, 1, 3.50, 3.50, 1.0),
(15, 5, null, 'Raw Almonds 200g', 0.85, 1, 4.99, 4.99, 4.0);

-- =====================================================
-- 12. 月度统计表 (monthly_statistics) - 一级依赖
-- =====================================================
INSERT INTO monthly_statistics (stat_id, user_id, year, month, receipt_uploads, total_products, total_spent, category_breakdown, popular_products, nutrition_breakdown, calculated_at, updated_at) VALUES
(1, 1, 2024, 12, 3, 8, 125.40, '{"Snacks": 35, "Beverages": 25, "Bakery": 20, "Fresh": 20}', '{"Oreo Cookies": 2, "Sprite": 2, "Bread": 1}', '{"avg_sugar_per_day": 24500, "total_calories": 1580, "total_sugar": 73500}', '2024-12-26 00:00:00', '2024-12-26 08:00:00'),
(2, 2, 2024, 12, 4, 12, 189.60, '{"Spreads": 30, "Beverages": 25, "Meat": 25, "Snacks": 20}', '{"Nutella": 2, "Coca-Cola": 3, "Chicken": 1}', '{"avg_sugar_per_day": 31200, "total_calories": 2140, "total_sugar": 93600}', '2024-12-26 00:00:00', '2024-12-26 08:00:00'),
(3, 3, 2024, 12, 2, 6, 78.30, '{"Fresh": 40, "Bakery": 30, "Dairy": 30}', '{"Apples": 2, "Yogurt": 1, "Bread": 1}', '{"avg_sugar_per_day": 22000, "total_calories": 1320, "total_sugar": 66000}', '2024-12-26 00:00:00', '2024-12-26 08:00:00'),
(4, 4, 2024, 12, 3, 9, 156.75, '{"Chocolate": 35, "Fresh": 30, "Meat": 25, "Beverages": 10}', '{"Cadbury Chocolate": 2, "Bananas": 2, "Salmon": 1}', '{"avg_sugar_per_day": 28500, "total_calories": 1890, "total_sugar": 85500}', '2024-12-26 00:00:00', '2024-12-26 08:00:00'),
(5, 5, 2024, 12, 2, 7, 92.80, '{"Energy Drinks": 40, "Protein": 30, "Nuts": 30}', '{"Red Bull": 2, "Protein Bars": 1, "Almonds": 1}', '{"avg_sugar_per_day": 18000, "total_calories": 1650, "total_sugar": 54000}', '2024-12-26 00:00:00', '2024-12-26 08:00:00');

-- =====================================================
-- 13. 推荐日志表 (recommendation_log) - 一级依赖
-- =====================================================
INSERT INTO recommendation_log (log_id, user_id, request_barcode, request_type, recommended_products, algorithm_version, llm_prompt, llm_response, llm_analysis, response_time_ms, created_at) VALUES
(1, 1, '7622210951915', 'HEALTHIER_ALTERNATIVE', '["4006381333618", "5449000000993"]', 'v2.1', 'User scanned high-sugar cookies, recommend healthier alternatives with lower sugar content', 'Based on the scanned Oreo cookies with 36g sugar per 100g, I recommend these healthier alternatives...', '{"sugar_reduction": "65%", "calorie_reduction": "40%", "nutritional_improvement": "high_fiber"}', 245, '2024-12-25 09:30:00'),
(2, 2, '3017620422003', 'PORTION_CONTROL', '["3017620422010"]', 'v2.1', 'User frequently purchases high-sugar spread, suggest portion control strategies', 'Nutella is high in sugar (56g per 100g). Consider smaller portions or sugar-free alternatives...', '{"portion_suggestion": "15g_serving", "frequency_limit": "3_times_per_week"}', 189, '2024-12-25 08:20:00'),
(3, 3, '4006381333610', 'COMPLETE_AVOIDANCE', '["fresh_fruits", "nuts_unsweetened"]', 'v2.1', 'User with sugar goals avoided high-sugar candy, suggest natural alternatives', 'Great choice avoiding high-sugar candy! Here are natural sweet alternatives...', '{"sugar_content": "natural_vs_added", "health_benefits": "vitamins_minerals_fiber"}', 156, '2024-12-24 10:45:00'),
(4, 4, '5000169005590', 'MODERATION', '["5000169005597"]', 'v2.1', 'User purchased chocolate, suggest dark chocolate alternative for better health profile', 'Consider dark chocolate with higher cocoa content for better health benefits...', '{"cocoa_percentage": "70%_minimum", "antioxidant_content": "higher"}', 167, '2024-12-25 11:15:00'),
(5, 5, '8712100854565', 'NATURAL_ENERGY', '["green_tea", "coffee_black"]', 'v2.1', 'User purchased energy drink pre-workout, suggest natural energy alternatives', 'For sustained energy, consider natural alternatives with less sugar...', '{"caffeine_comparison": "gradual_release", "sugar_reduction": "90%"}', 198, '2024-12-26 07:45:00');

-- =====================================================
-- 数据导入完成验证
-- =====================================================
SELECT 'Test data import completed successfully!' as status;

-- 显示各表的记录数量
SELECT 'Table Record Counts:' as info;
SELECT 'users' as table_name, COUNT(*) as record_count FROM user
UNION ALL
SELECT 'allergens', COUNT(*) FROM allergen  
UNION ALL
SELECT 'products', COUNT(*) FROM product
UNION ALL
SELECT 'user_preferences', COUNT(*) FROM user_preference
UNION ALL
SELECT 'user_allergens', COUNT(*) FROM user_allergen
UNION ALL
SELECT 'sugar_goals', COUNT(*) FROM sugar_goals
UNION ALL
SELECT 'sugar_intake_history', COUNT(*) FROM sugar_intake_history
UNION ALL
SELECT 'scan_history', COUNT(*) FROM scan_history
UNION ALL
SELECT 'product_preferences', COUNT(*) FROM product_preference
UNION ALL
SELECT 'purchase_records', COUNT(*) FROM purchase_record
UNION ALL
SELECT 'purchase_items', COUNT(*) FROM purchase_item
UNION ALL
SELECT 'monthly_statistics', COUNT(*) FROM monthly_statistics
UNION ALL
SELECT 'recommendation_logs', COUNT(*) FROM recommendation_log;

-- 显示用户糖分摄入统计
SELECT 'User Sugar Intake Summary:' as info;
SELECT 
    u.username,
    sg.daily_goal_mg as daily_goal,
    COALESCE(SUM(sih.sugar_amount_mg), 0) as total_consumed_mg,
    COUNT(sih.id) as total_records
FROM user u
LEFT JOIN sugar_goals sg ON u.user_id = sg.user_id
LEFT JOIN sugar_intake_history sih ON u.user_id = sih.user_id
GROUP BY u.user_id, u.username, sg.daily_goal_mg
ORDER BY u.user_id; 