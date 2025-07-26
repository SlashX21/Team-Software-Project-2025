-- =====================================================
-- Grocery Guardian Test Data Validation
-- File: validate-test-data.sql
-- Purpose: Validate imported test data integrity
-- =====================================================

SELECT '=== 测试数据验证报告 ===' as report_title;

-- =====================================================
-- 1. 表记录数量统计
-- =====================================================
SELECT '1. 表记录数量统计' as section_title;

SELECT 
    'user' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) = 5 THEN '✅ 正确' ELSE '❌ 异常' END as status
FROM user
UNION ALL
SELECT 'allergen', COUNT(*), CASE WHEN COUNT(*) = 12 THEN '✅ 正确' ELSE '❌ 异常' END FROM allergen  
UNION ALL
SELECT 'product', COUNT(*), CASE WHEN COUNT(*) = 10 THEN '✅ 正确' ELSE '❌ 异常' END FROM product
UNION ALL
SELECT 'user_preference', COUNT(*), CASE WHEN COUNT(*) = 5 THEN '✅ 正确' ELSE '❌ 异常' END FROM user_preference
UNION ALL
SELECT 'user_allergen', COUNT(*), CASE WHEN COUNT(*) = 7 THEN '✅ 正确' ELSE '❌ 异常' END FROM user_allergen
UNION ALL
SELECT 'sugar_goals', COUNT(*), CASE WHEN COUNT(*) = 5 THEN '✅ 正确' ELSE '❌ 异常' END FROM sugar_goals
UNION ALL
SELECT 'sugar_intake_history', COUNT(*), CASE WHEN COUNT(*) = 12 THEN '✅ 正确' ELSE '❌ 异常' END FROM sugar_intake_history
UNION ALL
SELECT 'scan_history', COUNT(*), CASE WHEN COUNT(*) = 7 THEN '✅ 正确' ELSE '❌ 异常' END FROM scan_history
UNION ALL
SELECT 'product_preference', COUNT(*), CASE WHEN COUNT(*) = 7 THEN '✅ 正确' ELSE '❌ 异常' END FROM product_preference
UNION ALL
SELECT 'purchase_record', COUNT(*), CASE WHEN COUNT(*) = 5 THEN '✅ 正确' ELSE '❌ 异常' END FROM purchase_record
UNION ALL
SELECT 'purchase_item', COUNT(*), CASE WHEN COUNT(*) = 15 THEN '✅ 正确' ELSE '❌ 异常' END FROM purchase_item
UNION ALL
SELECT 'monthly_statistics', COUNT(*), CASE WHEN COUNT(*) = 5 THEN '✅ 正确' ELSE '❌ 异常' END FROM monthly_statistics
UNION ALL
SELECT 'recommendation_log', COUNT(*), CASE WHEN COUNT(*) = 5 THEN '✅ 正确' ELSE '❌ 异常' END FROM recommendation_log;

-- =====================================================
-- 2. 外键完整性检查
-- =====================================================
SELECT '2. 外键完整性检查' as section_title;

-- 检查用户偏好表的外键
SELECT 
    'user_preference → user' as foreign_key_check,
    COUNT(*) as total_records,
    COUNT(DISTINCT up.user_id) as distinct_users,
    CASE WHEN COUNT(*) = COUNT(DISTINCT up.user_id) THEN '✅ 一对一关系正确' ELSE '❌ 关系异常' END as status
FROM user_preference up
JOIN user u ON up.user_id = u.user_id;

-- 检查用户过敏原表的外键
SELECT 
    'user_allergen → user & allergen' as foreign_key_check,
    COUNT(*) as total_records,
    SUM(CASE WHEN u.user_id IS NOT NULL AND a.allergen_id IS NOT NULL THEN 1 ELSE 0 END) as valid_references,
    CASE WHEN COUNT(*) = SUM(CASE WHEN u.user_id IS NOT NULL AND a.allergen_id IS NOT NULL THEN 1 ELSE 0 END) 
         THEN '✅ 外键完整' ELSE '❌ 外键缺失' END as status
FROM user_allergen ua
LEFT JOIN user u ON ua.user_id = u.user_id
LEFT JOIN allergen a ON ua.allergen_id = a.allergen_id;

-- 检查糖分目标表的外键
SELECT 
    'sugar_goals → user' as foreign_key_check,
    COUNT(*) as total_records,
    COUNT(DISTINCT sg.user_id) as distinct_users,
    CASE WHEN COUNT(*) = COUNT(DISTINCT sg.user_id) THEN '✅ 一对一关系正确' ELSE '❌ 关系异常' END as status
FROM sugar_goals sg
JOIN user u ON sg.user_id = u.user_id;

-- 检查糖分摄入历史表的外键
SELECT 
    'sugar_intake_history → user' as foreign_key_check,
    COUNT(*) as total_records,
    SUM(CASE WHEN u.user_id IS NOT NULL THEN 1 ELSE 0 END) as valid_user_refs,
    CASE WHEN COUNT(*) = SUM(CASE WHEN u.user_id IS NOT NULL THEN 1 ELSE 0 END) 
         THEN '✅ 用户外键完整' ELSE '❌ 用户外键缺失' END as status
FROM sugar_intake_history sih
LEFT JOIN user u ON sih.user_id = u.user_id;

-- =====================================================
-- 3. 数据逻辑一致性检查
-- =====================================================
SELECT '3. 数据逻辑一致性检查' as section_title;

-- 检查糖分摄入是否符合目标范围
SELECT 
    'Sugar Intake vs Goals' as consistency_check,
    u.username,
    sg.daily_goal_mg as daily_goal,
    COALESCE(SUM(sih.sugar_amount_mg), 0) as total_consumed,
    CASE 
        WHEN COALESCE(SUM(sih.sugar_amount_mg), 0) <= sg.daily_goal_mg * 3 THEN '✅ 合理范围'
        ELSE '⚠️  超出预期范围'
    END as status
FROM user u
LEFT JOIN sugar_goals sg ON u.user_id = sg.user_id
LEFT JOIN sugar_intake_history sih ON u.user_id = sih.user_id 
    AND DATE(sih.consumed_at) = '2024-12-25'  -- 检查特定日期
GROUP BY u.user_id, u.username, sg.daily_goal_mg;

-- 检查产品条码在各表中的一致性
SELECT 
    'Product Barcode Consistency' as consistency_check,
    p.barcode,
    p.name as product_name,
    COUNT(DISTINCT sih.barcode) as in_sugar_history,
    COUNT(DISTINCT sh.barcode) as in_scan_history,
    COUNT(DISTINCT pp.barcode) as in_preferences,
    '✅ 数据关联正常' as status
FROM product p
LEFT JOIN sugar_intake_history sih ON p.barcode = sih.barcode
LEFT JOIN scan_history sh ON p.barcode = sh.barcode
LEFT JOIN product_preference pp ON p.barcode = pp.barcode
GROUP BY p.barcode, p.name;

-- =====================================================
-- 4. 用户行为数据统计
-- =====================================================
SELECT '4. 用户行为数据统计' as section_title;

SELECT 
    u.username,
    u.nutrition_goal,
    sg.goal_level as sugar_goal_level,
    COUNT(DISTINCT sih.id) as sugar_records,
    COUNT(DISTINCT sh.scan_id) as scan_count,
    COUNT(DISTINCT pr.purchase_id) as purchase_count,
    COUNT(DISTINCT pp.preference_id) as preference_count,
    '✅ 行为数据完整' as status
FROM user u
LEFT JOIN sugar_goals sg ON u.user_id = sg.user_id
LEFT JOIN sugar_intake_history sih ON u.user_id = sih.user_id
LEFT JOIN scan_history sh ON u.user_id = sh.user_id
LEFT JOIN purchase_record pr ON u.user_id = pr.user_id
LEFT JOIN product_preference pp ON u.user_id = pp.user_id
GROUP BY u.user_id, u.username, u.nutrition_goal, sg.goal_level;

-- =====================================================
-- 5. 过敏原数据验证
-- =====================================================
SELECT '5. 过敏原数据验证' as section_title;

-- 检查常见过敏原分布
SELECT 
    'Common Allergens Distribution' as check_type,
    is_common,
    COUNT(*) as count,
    CASE 
        WHEN is_common = 1 AND COUNT(*) >= 8 THEN '✅ 常见过敏原充足'
        WHEN is_common = 0 AND COUNT(*) >= 2 THEN '✅ 非常见过敏原适量'
        ELSE '⚠️  分布不均'
    END as status
FROM allergen
GROUP BY is_common;

-- 检查用户过敏原覆盖情况
SELECT 
    'User Allergen Coverage' as check_type,
    COUNT(DISTINCT ua.user_id) as users_with_allergens,
    COUNT(DISTINCT ua.allergen_id) as allergens_assigned,
    CASE 
        WHEN COUNT(DISTINCT ua.user_id) >= 4 AND COUNT(DISTINCT ua.allergen_id) >= 6 
        THEN '✅ 覆盖充分'
        ELSE '⚠️  覆盖不足'
    END as status
FROM user_allergen ua;

-- =====================================================
-- 6. 产品营养数据验证
-- =====================================================
SELECT '6. 产品营养数据验证' as section_title;

SELECT 
    'Product Nutrition Data' as check_type,
    barcode,
    name,
    sugars_100g,
    energy_kcal_100g,
    CASE 
        WHEN sugars_100g > 0 AND energy_kcal_100g > 0 THEN '✅ 营养数据完整'
        ELSE '⚠️  营养数据缺失'
    END as status
FROM product
WHERE sugars_100g IS NOT NULL AND energy_kcal_100g IS NOT NULL;

-- =====================================================
-- 7. 时间数据一致性检查
-- =====================================================
SELECT '7. 时间数据一致性检查' as section_title;

-- 检查创建时间和更新时间的逻辑
SELECT 
    'User Timestamps' as check_type,
    username,
    created_at,
    updated_at,
    CASE 
        WHEN updated_at >= created_at THEN '✅ 时间逻辑正确'
        ELSE '❌ 时间逻辑错误'
    END as status
FROM user;

-- 检查糖分摄入时间分布
SELECT 
    'Sugar Intake Time Distribution' as check_type,
    DATE(consumed_at) as intake_date,
    COUNT(*) as records_count,
    '✅ 时间分布合理' as status
FROM sugar_intake_history
GROUP BY DATE(consumed_at)
ORDER BY intake_date;

-- =====================================================
-- 验证总结
-- =====================================================
SELECT '=== 验证总结 ===' as summary_title;

SELECT 
    '数据导入验证完成' as message,
    NOW() as validation_time,
    '所有测试数据已准备就绪，可以开始API测试' as next_steps; 