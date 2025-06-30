-- =====================================================
-- Grocery Guardian 数据库清理和重新导入脚本
-- 清理多余表和数据，然后重新导入CSV数据
-- =====================================================

USE springboot_demo;

-- 显示当前数据库状态
SELECT 'Current database status before cleanup:' AS info;
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    DATA_LENGTH,
    INDEX_LENGTH
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'springboot_demo'
ORDER BY TABLE_NAME;

-- =====================================================
-- 第一步：清理多余的临时表
-- =====================================================

SELECT '🧹 Step 1: Cleaning up temporary tables...' AS status;

-- 删除临时导入表（如果存在）
DROP TABLE IF EXISTS TEMP_PRODUCT_IMPORT;
DROP TABLE IF EXISTS TEMP_ALLERGEN_IMPORT;

SELECT '✅ Temporary tables cleaned' AS status;

-- =====================================================
-- 第二步：清理数据表内容（保留结构）
-- =====================================================

SELECT '🧹 Step 2: Cleaning up table data...' AS status;

-- 暂时禁用外键检查
SET FOREIGN_KEY_CHECKS = 0;

-- 清空有外键依赖的表（先清理子表）
TRUNCATE TABLE PRODUCT_ALLERGEN;
TRUNCATE TABLE USER_ALLERGEN;
TRUNCATE TABLE SCAN_HISTORY;
TRUNCATE TABLE PURCHASE_ITEM;
TRUNCATE TABLE PURCHASE_RECORD;
TRUNCATE TABLE PRODUCT_PREFERENCE;
TRUNCATE TABLE RECOMMENDATION_LOG;
TRUNCATE TABLE USER_PREFERENCE;

-- 清空主数据表
TRUNCATE TABLE PRODUCT;
TRUNCATE TABLE ALLERGEN;

-- 保留USER表数据（因为有8个用户记录是有用的）
-- TRUNCATE TABLE USER;  -- 注释掉，保留用户数据

-- 重新启用外键检查
SET FOREIGN_KEY_CHECKS = 1;

SELECT '✅ Table data cleaned (USER table preserved)' AS status;

-- =====================================================
-- 第三步：重置自增ID
-- =====================================================

SELECT '🔧 Step 3: Resetting auto-increment IDs...' AS status;

ALTER TABLE ALLERGEN AUTO_INCREMENT = 1;
ALTER TABLE PRODUCT_ALLERGEN AUTO_INCREMENT = 1;
ALTER TABLE USER_ALLERGEN AUTO_INCREMENT = 1;
ALTER TABLE SCAN_HISTORY AUTO_INCREMENT = 1;
ALTER TABLE PURCHASE_RECORD AUTO_INCREMENT = 1;
ALTER TABLE PURCHASE_ITEM AUTO_INCREMENT = 1;
ALTER TABLE PRODUCT_PREFERENCE AUTO_INCREMENT = 1;
ALTER TABLE RECOMMENDATION_LOG AUTO_INCREMENT = 1;
ALTER TABLE USER_PREFERENCE AUTO_INCREMENT = 1;

SELECT '✅ Auto-increment IDs reset' AS status;

-- =====================================================
-- 第四步：启用本地文件导入
-- =====================================================

SELECT '🔧 Step 4: Enabling local file import...' AS status;

-- 启用本地数据加载
SET GLOBAL local_infile = 1;

SELECT '✅ Local file import enabled' AS status;

-- =====================================================
-- 显示清理后的数据库状态
-- =====================================================

SELECT 'Database status after cleanup:' AS info;
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND(DATA_LENGTH/1024/1024, 2) AS 'DATA_SIZE_MB',
    ROUND(INDEX_LENGTH/1024/1024, 2) AS 'INDEX_SIZE_MB'
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'springboot_demo'
ORDER BY TABLE_NAME;

-- 显示保留的用户数据
SELECT 'Preserved user data:' AS info;
SELECT user_id, user_name, email, nutrition_goal FROM USER;

SELECT '🎉 Database cleanup completed successfully!' AS status;
SELECT '💡 Next steps:' AS info;
SELECT '1. Run updated_allergen_import.sql' AS step1;
SELECT '2. Run updated_product_import.sql' AS step2;
SELECT '3. Verify data import success' AS step3; 