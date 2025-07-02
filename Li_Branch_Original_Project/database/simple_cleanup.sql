-- =====================================================
-- 简化数据库清理脚本 (只清理存在的表)
-- =====================================================

USE springboot_demo;

-- 显示清理前状态
SELECT 'Before cleanup - table status:' AS info;
SELECT TABLE_NAME, TABLE_ROWS FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'springboot_demo' AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 清空现有数据表（保留结构，只清理存在的表）
SET FOREIGN_KEY_CHECKS = 0;

-- 清空product表数据
TRUNCATE TABLE product;
SELECT 'Cleaned PRODUCT table' AS status;

-- 清空allergen表数据  
TRUNCATE TABLE allergen;
SELECT 'Cleaned ALLERGEN table' AS status;

-- 保留USER表数据（因为有有用的测试用户）
-- TRUNCATE TABLE user;  -- 注释掉，保留用户数据

SET FOREIGN_KEY_CHECKS = 1;

-- 重置自增ID
ALTER TABLE product AUTO_INCREMENT = 1;
ALTER TABLE allergen AUTO_INCREMENT = 1;

-- 启用本地文件导入
SET GLOBAL local_infile = 1;

-- 显示清理后状态
SELECT 'After cleanup - table status:' AS info;
SELECT TABLE_NAME, TABLE_ROWS FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'springboot_demo' AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

SELECT '✅ Database cleanup completed successfully!' AS result; 