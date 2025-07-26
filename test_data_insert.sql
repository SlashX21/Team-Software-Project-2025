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
TRUNCATE TABLE user_preference;
TRUNCATE TABLE sugar_intake_history;
TRUNCATE TABLE product_preference;
TRUNCATE TABLE recommendation_log;

-- ============================================
-- 1. 用户表数据 (user)
-- ============================================
INSERT INTO user (user_id, username, email, password_hash, age, gender, height_cm, weight_kg, 
                 activity_level, nutrition_goal, daily_calories_target, daily_protein_target, 
                 daily_carb_target, daily_fat_target, date_of_birth, created_at, updated_at) 
VALUES 
(1, 'alice_chen', 'alice@example.com', '123456', 28, 'FEMALE', 165, 58.5, 
 'MODERATELY_ACTIVE', 'WEIGHT_LOSS', 1800.0, 120.0, 200.0, 60.0, '1996-03-15', '2024-01-01 10:00:00', '2024-01-01 10:00:00'),
(2, 'bob_wang', 'bob@example.com', '123456', 35, 'MALE', 178, 75.2, 
 'VERY_ACTIVE', 'MUSCLE_GAIN', 2500.0, 180.0, 300.0, 85.0, '1989-07-22', '2024-01-02 11:00:00', '2024-01-02 11:00:00'),
(3, 'carol_liu', 'carol@example.com', '123456', 42, 'FEMALE', 160, 65.0, 
 'SEDENTARY', 'WEIGHT_MAINTENANCE', 2000.0, 130.0, 250.0, 70.0, '1982-11-08', '2024-01-03 12:00:00', '2024-01-03 12:00:00'),
(4, 'david_zhang', 'david@example.com', '123456', 25, 'MALE', 185, 80.0, 
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
('2468135792468', 'Soy Sauce', 'Orient Express', 'Water, soybeans, wheat, salt', 'Soy, Wheat', 251.0, 60.0, 0.1, 0.0, 5.6, 0.8, 10.5, '15ml', 'Condiments'),

-- ============================================
-- 推荐系统测试数据 - 更多产品选项
-- ============================================
-- 乳制品替代品类
('1111111111111', 'Oat Milk', 'Plant Pure', 'Oat base, water, sunflower oil, sea salt', 'None', 188.0, 45.0, 1.5, 0.2, 6.6, 4.1, 1.0, '250ml', 'Dairy'),
('2222222222222', 'Almond Milk', 'Nut Heaven', 'Almonds, water, calcium carbonate, sea salt', 'Tree nuts', 71.0, 17.0, 1.1, 0.1, 0.6, 0.0, 0.6, '250ml', 'Dairy'),
('3333333333333', 'Soy Milk', 'Bean Fresh', 'Soybeans, water, cane sugar, calcium phosphate', 'Soy', 230.0, 55.0, 1.8, 0.3, 6.3, 4.2, 3.3, '250ml', 'Dairy'),
('4444444444444', 'Coconut Milk', 'Tropical Creamy', 'Coconut cream, water, guar gum', 'None', 736.0, 176.0, 17.1, 15.1, 2.8, 2.2, 1.6, '250ml', 'Dairy'),
('5555555555555', 'Lactose-Free Milk', 'Digest Easy', 'Milk, lactase enzyme', 'None', 276.0, 66.0, 3.8, 2.4, 4.8, 4.8, 3.2, '250ml', 'Dairy'),

-- 坚果酱和涂抹酱类
('6666666666666', 'Sunflower Seed Butter', 'Seed Spread', 'Sunflower seeds, sea salt', 'None', 2406.0, 575.0, 51.0, 4.4, 20.0, 2.6, 19.3, '32g', 'Spreads'),
('7777777777777', 'Cashew Butter', 'Creamy Nuts', 'Cashews, sea salt', 'Tree nuts', 2406.0, 575.0, 46.4, 8.2, 27.6, 5.9, 15.3, '32g', 'Spreads'),
('8888888888888', 'Tahini', 'Sesame King', 'Sesame seeds', 'Sesame', 2516.0, 601.0, 53.8, 7.6, 21.2, 0.5, 17.0, '32g', 'Spreads'),
('9999999999999', 'Hazelnut Spread', 'Choco Nut', 'Hazelnuts, cocoa, sugar, palm oil', 'Tree nuts', 2252.0, 539.0, 31.0, 10.2, 57.5, 54.4, 6.0, '32g', 'Spreads'),

-- 面包和烘焙类
('1010101010101', 'Ezekiel Bread', 'Sprouted Life', 'Sprouted wheat, barley, beans, lentils', 'Wheat', 1046.0, 250.0, 1.5, 0.3, 47.0, 0.0, 8.0, '2 slices', 'Bakery'),
('1212121212121', 'Rye Bread', 'Nordic Grain', 'Rye flour, water, sourdough culture, salt', 'Wheat', 1046.0, 250.0, 1.1, 0.2, 48.3, 3.8, 8.5, '2 slices', 'Bakery'),
('1313131313131', 'Whole Wheat Bread', 'Grain Master', 'Whole wheat flour, water, yeast, salt', 'Wheat', 1046.0, 250.0, 3.4, 0.6, 41.0, 4.2, 13.2, '2 slices', 'Bakery'),
('1414141414141', 'Rice Bread', 'Grain Free', 'Brown rice flour, potato starch, tapioca', 'None', 1047.0, 250.0, 4.0, 1.0, 50.0, 2.0, 4.0, '2 slices', 'Bakery'),

-- 海鲜和蛋白质类
('1515151515151', 'Tuna Fillet', 'Ocean Prime', 'Fresh yellowfin tuna', 'Fish', 460.0, 110.0, 0.5, 0.2, 0.0, 0.0, 25.0, '150g', 'Seafood'),
('1616161616161', 'Cod Fillet', 'North Sea', 'Fresh Atlantic cod', 'Fish', 343.0, 82.0, 0.7, 0.1, 0.0, 0.0, 17.8, '150g', 'Seafood'),
('1717171717171', 'Shrimp', 'Coastal Fresh', 'Fresh tiger shrimp', 'Shellfish', 418.0, 100.0, 1.7, 0.3, 0.9, 0.0, 20.1, '150g', 'Seafood'),
('1818181818181', 'Chicken Breast', 'Farm Fresh', 'Organic chicken breast', 'None', 690.0, 165.0, 3.6, 1.0, 0.0, 0.0, 31.0, '150g', 'Poultry'),
('1919191919191', 'Tofu', 'Soy Pure', 'Organic soybeans, water, nigari', 'Soy', 293.0, 70.0, 4.2, 0.6, 1.9, 0.6, 8.1, '150g', 'Plant Protein'),

-- 意面和谷物类
('2020202020202', 'Brown Rice Pasta', 'Whole Grain', 'Brown rice flour', 'None', 1464.0, 350.0, 2.8, 0.6, 77.0, 1.2, 7.2, '85g dry', 'Pasta'),
('2121212121212', 'Lentil Pasta', 'Legume Power', 'Red lentil flour', 'None', 1464.0, 350.0, 2.5, 0.4, 58.0, 2.8, 25.0, '85g dry', 'Pasta'),
('2222222222223', 'Chickpea Pasta', 'Bean Noodle', 'Chickpea flour', 'None', 1506.0, 360.0, 6.0, 1.0, 54.0, 5.0, 20.0, '85g dry', 'Pasta'),
('2323232323232', 'Whole Wheat Pasta', 'Grain Gold', 'Whole wheat durum flour', 'Wheat', 1464.0, 350.0, 2.5, 0.5, 71.0, 2.8, 14.0, '85g dry', 'Pasta'),

-- 零食类
('2424242424242', 'Kale Chips', 'Green Crunch', 'Kale, olive oil, sea salt', 'None', 1673.0, 400.0, 28.0, 4.0, 40.0, 8.0, 16.0, '30g', 'Snacks'),
('2525252525252', 'Seaweed Snacks', 'Ocean Crisp', 'Roasted seaweed, sesame oil, salt', 'Sesame', 1673.0, 400.0, 28.0, 4.0, 40.0, 8.0, 16.0, '30g', 'Snacks'),
('2626262626262', 'Quinoa Chips', 'Ancient Crunch', 'Quinoa, olive oil, sea salt', 'None', 1756.0, 420.0, 20.0, 2.0, 60.0, 4.0, 8.0, '30g', 'Snacks'),
('2727272727272', 'Sweet Potato Chips', 'Root Veggie', 'Sweet potato, sunflower oil, salt', 'None', 2218.0, 530.0, 33.0, 3.0, 54.0, 22.0, 7.0, '30g', 'Snacks'),

-- 调味品类
('2828282828282', 'Coconut Aminos', 'Tropical Taste', 'Coconut sap, sea salt', 'None', 251.0, 60.0, 0.0, 0.0, 14.0, 6.0, 1.0, '15ml', 'Condiments'),
('2929292929292', 'Tamari', 'Wheat Free', 'Soybeans, water, salt', 'Soy', 251.0, 60.0, 0.1, 0.0, 5.6, 0.8, 10.5, '15ml', 'Condiments'),
('3030303030303', 'Liquid Aminos', 'Protein Plus', 'Soybeans, water', 'Soy', 251.0, 60.0, 0.0, 0.0, 5.0, 0.0, 8.0, '15ml', 'Condiments'),
('3131313131313', 'Fish Sauce', 'Asian Essence', 'Anchovy, sea salt', 'Fish', 251.0, 60.0, 0.0, 0.0, 0.0, 0.0, 10.0, '15ml', 'Condiments'),

-- 饮料类
('3232323232323', 'Green Tea', 'Zen Leaf', 'Organic green tea leaves', 'None', 4.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.2, '250ml', 'Beverages'),
('3333333333334', 'Kombucha', 'Probiotic Power', 'Tea, sugar, SCOBY culture', 'None', 71.0, 17.0, 0.0, 0.0, 4.0, 2.0, 0.0, '250ml', 'Beverages'),
('3434343434343', 'Almond Milk Latte', 'Coffee Plus', 'Coffee, almond milk, natural flavors', 'Tree nuts', 188.0, 45.0, 2.0, 0.2, 6.0, 4.0, 1.5, '250ml', 'Beverages'),
('3535353535353', 'Herbal Tea', 'Calm Blend', 'Chamomile, lavender, lemon balm', 'None', 4.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, '250ml', 'Beverages'),

-- 酸奶和发酵食品类
('3636363636363', 'Coconut Yogurt', 'Dairy Free', 'Coconut milk, live cultures', 'None', 511.0, 122.0, 11.0, 9.0, 6.0, 6.0, 1.0, '170g', 'Dairy'),
('3737373737373', 'Almond Yogurt', 'Nut Based', 'Almond milk, live cultures', 'Tree nuts', 293.0, 70.0, 4.0, 0.4, 8.0, 6.0, 1.5, '170g', 'Dairy'),
('3838383838383', 'Soy Yogurt', 'Plant Power', 'Soy milk, live cultures', 'Soy', 293.0, 70.0, 1.9, 0.4, 12.0, 9.0, 3.0, '170g', 'Dairy'),
('3939393939393', 'Kefir', 'Probiotic Rich', 'Milk, kefir grains', 'Milk', 251.0, 60.0, 1.0, 0.7, 7.0, 7.0, 3.0, '170g', 'Dairy'),

-- 巧克力和甜品类
('4040404040404', 'Raw Cacao', 'Pure Chocolate', 'Raw cacao beans', 'None', 1138.0, 272.0, 14.0, 8.0, 58.0, 2.0, 14.0, '40g', 'Confectionery'),
('4141414141414', 'Coconut Chocolate', 'Tropical Sweet', 'Coconut, cacao, coconut sugar', 'None', 2260.0, 540.0, 35.0, 28.0, 45.0, 35.0, 6.0, '40g', 'Confectionery'),
('4242424242424', 'Stevia Chocolate', 'Sugar Free', 'Cacao, stevia, coconut oil', 'None', 1883.0, 450.0, 40.0, 30.0, 20.0, 0.0, 8.0, '40g', 'Confectionery'),
('4343434343434', 'Protein Bar', 'Muscle Fuel', 'Whey protein, almonds, dates', 'Milk, Tree nuts', 1464.0, 350.0, 15.0, 6.0, 30.0, 18.0, 25.0, '60g', 'Snacks');

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
('2468135792468', 6, 'PRESENT', 0.95),

-- 新产品的过敏原关联数据
('2222222222222', 4, 'PRESENT', 0.95), -- Almond Milk contains tree nuts
('3333333333333', 5, 'PRESENT', 0.98), -- Soy Milk contains soy
('7777777777777', 4, 'PRESENT', 0.95), -- Cashew Butter contains tree nuts
('8888888888888', 9, 'PRESENT', 0.92), -- Tahini contains sesame
('9999999999999', 4, 'PRESENT', 0.95), -- Hazelnut Spread contains tree nuts
('1010101010101', 6, 'PRESENT', 1.0),  -- Ezekiel Bread contains wheat
('1212121212121', 6, 'PRESENT', 1.0),  -- Rye Bread contains wheat
('1313131313131', 6, 'PRESENT', 1.0),  -- Whole Wheat Bread contains wheat
('1515151515151', 7, 'PRESENT', 1.0),  -- Tuna Fillet contains fish
('1616161616161', 7, 'PRESENT', 1.0),  -- Cod Fillet contains fish
('1717171717171', 8, 'PRESENT', 1.0),  -- Shrimp contains shellfish
('1919191919191', 5, 'PRESENT', 0.98), -- Tofu contains soy
('2323232323232', 6, 'PRESENT', 1.0),  -- Whole Wheat Pasta contains wheat
('2525252525252', 9, 'PRESENT', 0.92), -- Seaweed Snacks contains sesame
('2929292929292', 5, 'PRESENT', 0.98), -- Tamari contains soy
('3030303030303', 5, 'PRESENT', 0.98), -- Liquid Aminos contains soy
('3131313131313', 7, 'PRESENT', 1.0),  -- Fish Sauce contains fish
('3434343434343', 4, 'PRESENT', 0.95), -- Almond Milk Latte contains tree nuts
('3737373737373', 4, 'PRESENT', 0.95), -- Almond Yogurt contains tree nuts
('3838383838383', 5, 'PRESENT', 0.98), -- Soy Yogurt contains soy
('3939393939393', 1, 'PRESENT', 1.0),  -- Kefir contains milk
('4343434343434', 1, 'PRESENT', 1.0),  -- Protein Bar contains milk
('4343434343434', 4, 'PRESENT', 0.95); -- Protein Bar contains tree nuts

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
 '{"healthScore": 7.6, "recommendations": [{"product": "Coconut Yogurt", "reason": "Dairy-free option"}], "nutritionSummary": {"calories": 122, "protein": 10.0, "carbs": 4.0, "fat": 10.0}, "allergenWarnings": []}'),

-- ============================================
-- 更多推荐系统测试用扫描历史数据
-- ============================================
-- 测试乳制品推荐 - Alice扫描牛奶，应该推荐植物奶
(1, '1234567890123', DATE_SUB(NOW(), INTERVAL 12 HOUR), 'Fresh Market', true, 
 '{"ocr_confidence": 0.96, "barcode_detected": true, "processing_time": 1.1}', 'NONE', 'BARCODE',
 '{"healthScore": 4.2, "recommendations": [{"product": "Oat Milk", "reason": "Lactose-free alternative"}, {"product": "Almond Milk", "reason": "Lower calories"}], "nutritionSummary": {"calories": 66, "protein": 3.2, "carbs": 4.8, "fat": 3.8}, "allergenWarnings": ["Contains milk - you are lactose intolerant"]}'),

-- 测试坚果酱推荐 - Alice扫描花生酱，应该推荐无花生替代品
(1, '0123456789012', DATE_SUB(NOW(), INTERVAL 8 HOUR), 'Supermarket', true, 
 '{"ocr_confidence": 0.94, "barcode_detected": true, "processing_time": 1.3}', 'REMOVE', 'BARCODE',
 '{"healthScore": 2.1, "recommendations": [{"product": "Sunflower Seed Butter", "reason": "Peanut-free alternative"}, {"product": "Almond Butter", "reason": "Tree nut option"}], "nutritionSummary": {"calories": 570, "protein": 25.0, "carbs": 16.0, "fat": 50.0}, "allergenWarnings": ["DANGER: Contains peanuts - you have severe peanut allergy!"]}'),

-- 测试面包推荐 - Bob扫描含麸质面包，应该推荐无麸质替代品
(2, '9012345678901', DATE_SUB(NOW(), INTERVAL 4 HOUR), 'Bakery Shop', true, 
 '{"ocr_confidence": 0.98, "barcode_detected": true, "processing_time": 0.9}', 'NONE', 'BARCODE',
 '{"healthScore": 6.8, "recommendations": [{"product": "Gluten-Free Bread", "reason": "Suitable for gluten sensitivity"}, {"product": "Rice Bread", "reason": "Grain-free option"}], "nutritionSummary": {"calories": 250, "protein": 8.5, "carbs": 51.0, "fat": 1.2}, "allergenWarnings": ["Contains wheat - you have gluten sensitivity"]}'),

-- 测试蛋白质推荐 - Bob扫描鸡肉，应该推荐其他蛋白质
(2, '1818181818181', DATE_SUB(NOW(), INTERVAL 3 HOUR), 'Meat Market', false, 
 '{"ocr_confidence": 0.97, "barcode_detected": true, "processing_time": 1.0}', 'NONE', 'BARCODE',
 '{"healthScore": 8.5, "recommendations": [{"product": "Wild Salmon", "reason": "Rich in omega-3"}, {"product": "Tofu", "reason": "Plant-based protein"}], "nutritionSummary": {"calories": 165, "protein": 31.0, "carbs": 0.0, "fat": 3.6}, "allergenWarnings": []}'),

-- 测试零食推荐 - Carol扫描含芝麻零食，应该推荐无芝麻替代品
(3, '1357924680135', DATE_SUB(NOW(), INTERVAL 2 HOUR), 'Health Store', true, 
 '{"ocr_confidence": 0.91, "barcode_detected": true, "processing_time": 1.2}', 'NONE', 'BARCODE',
 '{"healthScore": 5.5, "recommendations": [{"product": "Quinoa Chips", "reason": "Sesame-free option"}, {"product": "Kale Chips", "reason": "Healthier alternative"}], "nutritionSummary": {"calories": 400, "protein": 8.0, "carbs": 80.0, "fat": 8.0}, "allergenWarnings": ["Contains sesame - you have mild sesame allergy"]}'),

-- 测试酸奶推荐 - Carol扫描坚果酸奶，应该推荐无坚果替代品
(3, '3737373737373', DATE_SUB(NOW(), INTERVAL 1 HOUR), 'Organic Store', true, 
 '{"ocr_confidence": 0.93, "barcode_detected": true, "processing_time": 1.1}', 'REMOVE', 'BARCODE',
 '{"healthScore": 6.2, "recommendations": [{"product": "Coconut Yogurt", "reason": "Tree nut-free option"}, {"product": "Soy Yogurt", "reason": "Plant-based alternative"}], "nutritionSummary": {"calories": 70, "protein": 1.5, "carbs": 8.0, "fat": 4.0}, "allergenWarnings": ["Contains tree nuts - you have severe tree nut allergy"]}'),

-- 测试调味品推荐 - David扫描豆豉，应该推荐无大豆替代品
(4, '3030303030303', DATE_SUB(NOW(), INTERVAL 30 MINUTE), 'Asian Market', true, 
 '{"ocr_confidence": 0.95, "barcode_detected": true, "processing_time": 1.0}', 'NONE', 'BARCODE',
 '{"healthScore": 4.5, "recommendations": [{"product": "Coconut Aminos", "reason": "Soy-free alternative"}, {"product": "Fish Sauce", "reason": "Umami flavor"}], "nutritionSummary": {"calories": 60, "protein": 8.0, "carbs": 5.0, "fat": 0.0}, "allergenWarnings": ["Contains soy - you have soy intolerance"]}'),

-- 测试饮料推荐 - 用户扫描含坚果饮料
(1, '3434343434343', DATE_SUB(NOW(), INTERVAL 15 MINUTE), 'Coffee Shop', true, 
 '{"ocr_confidence": 0.89, "barcode_detected": true, "processing_time": 1.1}', 'REMOVE', 'BARCODE',
 '{"healthScore": 5.8, "recommendations": [{"product": "Oat Milk Latte", "reason": "Nut-free alternative"}, {"product": "Coconut Water", "reason": "Natural hydration"}], "nutritionSummary": {"calories": 45, "protein": 1.5, "carbs": 6.0, "fat": 2.0}, "allergenWarnings": ["Contains tree nuts - not suitable for your peanut allergy"]}'),

-- 测试巧克力推荐 - 用户扫描高糖巧克力
(1, '7890123456789', DATE_SUB(NOW(), INTERVAL 10 MINUTE), 'Convenience Store', false, 
 '{"ocr_confidence": 0.92, "barcode_detected": true, "processing_time": 1.2}', 'NONE', 'BARCODE',
 '{"healthScore": 3.1, "recommendations": [{"product": "Raw Cacao", "reason": "Lower sugar content"}, {"product": "Stevia Chocolate", "reason": "Sugar-free option"}], "nutritionSummary": {"calories": 540, "protein": 8.0, "carbs": 45.0, "fat": 35.0}, "allergenWarnings": []}'),

-- 测试海鲜推荐 - Bob扫描虾，应该推荐其他海鲜
(2, '1717171717171', DATE_SUB(NOW(), INTERVAL 5 MINUTE), 'Seafood Market', true, 
 '{"ocr_confidence": 0.96, "barcode_detected": true, "processing_time": 0.9}', 'NONE', 'BARCODE',
 '{"healthScore": 7.8, "recommendations": [{"product": "Wild Salmon", "reason": "High omega-3"}, {"product": "Cod Fillet", "reason": "Lean protein"}], "nutritionSummary": {"calories": 100, "protein": 20.1, "carbs": 0.9, "fat": 1.7}, "allergenWarnings": ["Contains shellfish - you may have shellfish sensitivity"]}');

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
(3, 'Rice Crackers', 2000.0, 1.0, '2025-06-29 15:20:00', '1357924680135', 'SCAN', 'Afternoon snack', '2025-06-29 15:20:00'),
(3, 'Coconut Water', 2600.0, 1.0, '2025-06-30 16:00:00', '8901234567890', 'SCAN', 'Post-workout hydration', '2025-06-30 16:00:00'),
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

-- ============================================
-- 12. 用户偏好数据 (user_preference)
-- 来源：系统分析生成 + 人工模拟
-- ============================================

INSERT INTO user_preference (
    user_id,
    prefer_low_sugar,
    prefer_low_fat,
    prefer_high_protein,
    prefer_low_sodium,
    prefer_organic,
    prefer_low_calorie,
    preference_source,
    inference_confidence,
    version,
    created_at,
    updated_at
) VALUES 
-- 用户 1：Alice，偏好低糖、低脂、有机
(1, TRUE, TRUE, FALSE, FALSE, TRUE, FALSE, 'MIXED', 0.85, 1, NOW(), NOW()),

-- 用户 2：Bob，目标增肌，偏好高蛋白、低钠、低热量（系统推测）
(2, FALSE, FALSE, TRUE, TRUE, FALSE, TRUE, 'SYSTEM_INFERRED', 0.90, 1, NOW(), NOW()),

-- 用户 3：Carol，偏好有机、低糖、低热量（用户手动设置）
(3, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, 'USER_MANUAL', 1.00, 1, NOW(), NOW()),

-- 用户 4：David，刚开始使用系统，尚未形成明显偏好（默认全FALSE）
(4, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, 'SYSTEM_INFERRED', 0.10, 1, NOW(), NOW());

INSERT INTO sugar_intake_history 
(user_id, food_name, sugar_amount_mg, intake_time, source_type, barcode, serving_size) 
VALUES
-- 用户 1 Alice：早餐喝牛奶（扫码记录）
(1, 'Organic Whole Milk', 4800.0, '2024-01-15 08:30:00', 'SCAN', '1234567890123', '250ml'),

-- 用户 1 Alice：晚餐吃藜麦意面（发票识别）
(1, 'Quinoa Pasta', 3200.0, '2024-01-15 19:00:00', 'RECEIPT', '5678901234567', '85g'),

-- 用户 1 Alice：手动记录下午茶吃了一块巧克力（无条码）
(1, 'Dark Chocolate Bar', 3800.0, '2024-01-16 15:45:00', 'MANUAL', NULL, '40g'),

-- 用户 2 Bob：早餐吃了酸面包（扫码）
(2, 'Sourdough Bread', 2800.0, '2024-01-16 09:10:00', 'SCAN', '9012345678901', '2 slices'),

-- 用户 2 Bob：午餐吃了三文鱼（发票记录，无糖）
(2, 'Wild Salmon Fillet', 0.0, '2024-01-17 12:30:00', 'RECEIPT', '4567890123456', '150g'),

-- 用户 2 Bob：晚餐后喝了酸奶（扫码）
(2, 'Greek Yogurt', 4000.0, '2024-01-17 20:00:00', 'SCAN', '6789012345678', '170g'),

-- 用户 3 Carol：下午手动录入吃了米饼
(3, 'Rice Crackers', 2000.0, '2025-06-29 15:20:00', 'MANUAL', '1357924680135', '30g'),

-- 用户 3 Carol：锻炼后喝椰子水（扫码）
(3, 'Coconut Water', 2600.0, '2025-06-30 16:00:00', 'SCAN', '8901234567890', '330ml'),

-- 用户 4 David：中午炒菜用酱油（扫码）
(4, 'Soy Sauce', 800.0, '2024-01-20 12:45:00', 'SCAN', '2468135792468', '15ml'),

-- 用户 4 David：晚上吃了酸奶（扫码）
(4, 'Greek Yogurt', 4000.0, '2024-01-20 20:15:00', 'SCAN', '6789012345678', '170g');


-- ============================================
-- 13. 商品偏好数据 (product_preference)
-- 来源：用户在使用过程中手动设置
-- ============================================

INSERT INTO product_preference (
    user_id,
    bar_code,
    preference_type,
    reason,
    created_at
) VALUES
-- 用户 1 Alice：不喜欢 Peanut Butter（严重过敏）、喜欢 Quinoa Pasta（健康高纤）、拉黑 Dark Chocolate（太甜）
(1, '0123456789012', 'DISLIKE', 'Peanut allergy, avoid completely', NOW()),
(1, '5678901234567', 'LIKE', 'Healthy option, good for dinner', NOW()),
(1, '7890123456789', 'BLACKLIST', 'Too sweet, not suitable for my diet', NOW()),

-- 用户 2 Bob：喜欢 Greek Yogurt（高蛋白）、拉黑 Gluten-Free Bread（不喜欢口感）
(2, '6789012345678', 'LIKE', 'High protein, fits muscle gain goals', NOW()),
(2, '3456789012345', 'BLACKLIST', 'Texture not appealing', NOW()),

-- 用户 3 Carol：喜欢 Coconut Water（锻炼后补水）、不喜欢 Rice Crackers（过敏）、拉黑 Almond Butter（坚果过敏）
(3, '8901234567890', 'LIKE', 'Refreshing after workout', NOW()),
(3, '1357924680135', 'DISLIKE', 'Sesame causes allergic reaction', NOW()),
(3, '2345678901234', 'BLACKLIST', 'Tree nut allergy', NOW()),

-- 用户 4 David：喜欢 Soy Sauce（做饭用），拉黑 Milk 产品（乳糖不耐）
(4, '2468135792468', 'LIKE', 'Essential for cooking', NOW()),
(4, '1234567890123', 'BLACKLIST', 'Lactose intolerant', NOW());


-- ============================================
-- 14. 推荐日志数据 (recommendation_log) - 测试推荐系统日志
-- ============================================
INSERT INTO recommendation_log (user_id, request_barcode, request_type, 
                               recommended_products, created_at, processing_time_ms) 
VALUES 
-- Alice的推荐日志
(1, '1234567890123', 'BARCODE', 
 '{"alternatives": [{"barcode": "1111111111111", "name": "Oat Milk", "reason": "Lactose-free alternative", "score": 8.5}, {"barcode": "2222222222222", "name": "Almond Milk", "reason": "Lower calories", "score": 7.8}], "nutritionComparison": {"original": {"calories": 66, "protein": 3.2}, "recommended": {"calories": 31, "protein": 0.8}}}', 
 DATE_SUB(NOW(), INTERVAL 12 HOUR), 1200),

(1, '0123456789012', 'BARCODE', 
 '{"alternatives": [{"barcode": "6666666666666", "name": "Sunflower Seed Butter", "reason": "Peanut-free alternative", "score": 8.9}, {"barcode": "2345678901234", "name": "Almond Butter", "reason": "Tree nut option", "score": 7.5}], "nutritionComparison": {"original": {"calories": 570, "protein": 25.0}, "recommended": {"calories": 575, "protein": 19.3}}}', 
 DATE_SUB(NOW(), INTERVAL 8 HOUR), 1500),

-- Bob的推荐日志
(2, '9012345678901', 'BARCODE', 
 '{"alternatives": [{"barcode": "3456789012345", "name": "Gluten-Free Bread", "reason": "Suitable for gluten sensitivity", "score": 8.2}, {"barcode": "1414141414141", "name": "Rice Bread", "reason": "Grain-free option", "score": 7.9}], "nutritionComparison": {"original": {"calories": 250, "protein": 8.5}, "recommended": {"calories": 250, "protein": 4.8}}}', 
 DATE_SUB(NOW(), INTERVAL 4 HOUR), 900),

(2, '1818181818181', 'BARCODE', 
 '{"alternatives": [{"barcode": "4567890123456", "name": "Wild Salmon Fillet", "reason": "Rich in omega-3", "score": 9.2}, {"barcode": "1919191919191", "name": "Tofu", "reason": "Plant-based protein", "score": 7.8}], "nutritionComparison": {"original": {"calories": 165, "protein": 31.0}, "recommended": {"calories": 135, "protein": 13.95}}}', 
 DATE_SUB(NOW(), INTERVAL 3 HOUR), 1000),

-- Carol的推荐日志
(3, '1357924680135', 'BARCODE', 
 '{"alternatives": [{"barcode": "2626262626262", "name": "Quinoa Chips", "reason": "Sesame-free option", "score": 8.1}, {"barcode": "2424242424242", "name": "Kale Chips", "reason": "Healthier alternative", "score": 8.7}], "nutritionComparison": {"original": {"calories": 400, "protein": 8.0}, "recommended": {"calories": 410, "protein": 12.0}}}', 
 DATE_SUB(NOW(), INTERVAL 2 HOUR), 1200),

(3, '3737373737373', 'BARCODE', 
 '{"alternatives": [{"barcode": "3636363636363", "name": "Coconut Yogurt", "reason": "Tree nut-free option", "score": 8.4}, {"barcode": "3838383838383", "name": "Soy Yogurt", "reason": "Plant-based alternative", "score": 7.6}], "nutritionComparison": {"original": {"calories": 70, "protein": 1.5}, "recommended": {"calories": 96, "protein": 1.25}}}', 
 DATE_SUB(NOW(), INTERVAL 1 HOUR), 1100),

-- David的推荐日志
(4, '3030303030303', 'BARCODE', 
 '{"alternatives": [{"barcode": "2828282828282", "name": "Coconut Aminos", "reason": "Soy-free alternative", "score": 8.8}, {"barcode": "3131313131313", "name": "Fish Sauce", "reason": "Umami flavor", "score": 7.3}], "nutritionComparison": {"original": {"calories": 60, "protein": 8.0}, "recommended": {"calories": 60, "protein": 5.5}}}', 
 DATE_SUB(NOW(), INTERVAL 30 MINUTE), 1000),

-- 更多测试数据
(1, '3434343434343', 'BARCODE', 
 '{"alternatives": [{"barcode": "1111111111111", "name": "Oat Milk Latte", "reason": "Nut-free alternative", "score": 8.3}, {"barcode": "8901234567890", "name": "Coconut Water", "reason": "Natural hydration", "score": 8.9}], "nutritionComparison": {"original": {"calories": 45, "protein": 1.5}, "recommended": {"calories": 32, "protein": 0.85}}}', 
 DATE_SUB(NOW(), INTERVAL 15 MINUTE), 1100),

(2, '1717171717171', 'BARCODE', 
 '{"alternatives": [{"barcode": "4567890123456", "name": "Wild Salmon Fillet", "reason": "High omega-3", "score": 9.2}, {"barcode": "1616161616161", "name": "Cod Fillet", "reason": "Lean protein", "score": 8.6}], "nutritionComparison": {"original": {"calories": 100, "protein": 20.1}, "recommended": {"calories": 136, "protein": 21.4}}}', 
 DATE_SUB(NOW(), INTERVAL 5 MINUTE), 900),

-- 巧克力推荐日志
(1, '7890123456789', 'BARCODE', 
 '{"alternatives": [{"barcode": "4040404040404", "name": "Raw Cacao", "reason": "Lower sugar content", "score": 8.1}, {"barcode": "4242424242424", "name": "Stevia Chocolate", "reason": "Sugar-free option", "score": 8.5}], "nutritionComparison": {"original": {"calories": 540, "protein": 8.0}, "recommended": {"calories": 361, "protein": 11.0}}}', 
 DATE_SUB(NOW(), INTERVAL 10 MINUTE), 1200);

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
UNION ALL SELECT 
  'recommendation_log', COUNT(*) FROM recommendation_log
ORDER BY table_name;

-- ============================================
-- 新增数据总结 - 推荐系统测试专用
-- ============================================
-- 新增了以下数据用于推荐系统测试：
-- 1. 产品数据：新增 33 个产品，涵盖各种类别和过敏原
--    - 乳制品替代品：燕麦奶、杏仁奶、豆奶、椰奶、无乳糖牛奶
--    - 坚果酱替代品：葵花籽酱、腰果酱、芝麻酱、榛子酱
--    - 面包类：以西结面包、黑麦面包、全麦面包、米面包
--    - 蛋白质：金枪鱼、鳕鱼、虾、鸡胸肉、豆腐
--    - 意面：糙米面、扁豆面、鹰嘴豆面、全麦面
--    - 零食：甘蓝片、海苔、藜麦片、红薯片
--    - 调味品：椰子氨基酸、日式酱油、液体氨基酸、鱼露
--    - 饮料：绿茶、康普茶、杏仁奶拿铁、花草茶
--    - 酸奶：椰子酸奶、杏仁酸奶、豆奶酸奶、开菲尔
--    - 巧克力：生可可、椰子巧克力、甜菊糖巧克力、蛋白棒
--
-- 2. 过敏原关联：为新产品添加了 23 个过敏原关联记录
--
-- 3. 扫描历史：新增 11 个扫描记录，专门测试推荐系统
--    - 测试不同过敏原的推荐逻辑
--    - 测试不同类别产品的替代品推荐
--    - 涵盖所有用户的不同过敏情况
--
-- 4. 推荐日志：新增 10 个推荐日志记录
--    - 记录推荐系统的历史调用
--    - 包含详细的推荐结果和营养对比
--    - 测试日志记录功能

-- ============================================
-- 示例查询：验证推荐系统测试数据
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

-- 查看推荐系统可用的替代品数量（按类别）
SELECT 
    p.category,
    COUNT(*) as product_count,
    COUNT(DISTINCT pa.allergen_id) as allergen_types
FROM product p
LEFT JOIN product_allergen pa ON p.barcode = pa.barcode
GROUP BY p.category
ORDER BY product_count DESC;

-- 查看推荐日志统计
SELECT 
    rl.user_id,
    COUNT(*) as recommendation_count,
    AVG(rl.processing_time_ms) as avg_processing_time
FROM recommendation_log rl
GROUP BY rl.user_id
ORDER BY recommendation_count DESC; 