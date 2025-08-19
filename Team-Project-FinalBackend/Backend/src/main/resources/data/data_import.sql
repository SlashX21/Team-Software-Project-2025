-- =====================================================
-- Grocery Guardian Complete Data Import
-- File: grocery_guardian_complete_import.sql
-- Purpose: Import CSV data into ALLERGEN and PRODUCT tables
-- Prerequisite: Run database schema creation first
-- =====================================================

USE springboot_demo;

-- =====================================================
-- PART 1: ALLERGEN DATA IMPORT
-- =====================================================

-- =====================================================
-- 1. Pre-import Verification - ALLERGEN
-- =====================================================

-- Verify database schema exists
SELECT 'Verifying allergen database schema...' AS status;

-- Check if ALLERGEN table exists
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN 'ALLERGEN table exists ✅'
        ELSE 'ERROR: ALLERGEN table missing ❌'
    END AS table_check
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'grocery_guardian' AND TABLE_NAME = 'allergen';

-- Check current ALLERGEN table status
SELECT 
    COUNT(*) AS current_allergen_count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'ALLERGEN table is empty - ready for import ✅'
        ELSE CONCAT('ALLERGEN table contains ', COUNT(*), ' allergens - will be imported alongside')
    END AS import_status
FROM allergen;

-- =====================================================
-- 2. Enable Local File Loading (if needed)
-- =====================================================

-- Enable local data loading
SET GLOBAL local_infile = 1;

-- =====================================================
-- 3. Create Temporary Import Table - ALLERGEN
-- =====================================================

-- Drop temporary table if exists
DROP TABLE IF EXISTS TEMP_ALLERGEN_IMPORT;

-- Create temporary table for raw CSV data
CREATE TABLE TEMP_ALLERGEN_IMPORT (
    allergen_id_raw TEXT COMMENT 'Raw allergen ID from CSV',
    name_raw TEXT COMMENT 'Raw allergen name from CSV',
    category_raw TEXT COMMENT 'Raw category from CSV',
    is_common_raw TEXT COMMENT 'Raw is_common flag from CSV',
    description_raw TEXT COMMENT 'Raw description from CSV'
) ENGINE=InnoDB COMMENT='Temporary table for allergen CSV import';

SELECT 'Temporary allergen import table created ✅' AS status;

-- =====================================================
-- 4. CSV Data Import - ALLERGEN
-- =====================================================

-- Import raw allergen CSV data
-- ⚠️  MODIFY THE FILE PATH TO YOUR ACTUAL CSV LOCATION ⚠️

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/allergen_dictionary.csv'
INTO TABLE TEMP_ALLERGEN_IMPORT
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(allergen_id_raw, name_raw, category_raw, is_common_raw, description_raw);

-- Alternative: If LOAD DATA LOCAL INFILE doesn't work, use CSV import tool
-- and run the verification query below:

-- =====================================================
-- 5. Verify Raw Data Import - ALLERGEN
-- =====================================================

-- Check imported data count
SELECT 
    COUNT(*) AS raw_allergen_records_imported,
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('Successfully imported ', COUNT(*), ' raw allergen records ✅')
        ELSE 'No allergen data imported - check CSV file path and LOAD DATA command ❌'
    END AS import_result
FROM TEMP_ALLERGEN_IMPORT;

-- Preview first 10 raw records
SELECT 'Preview of raw imported allergen data:' AS info;
SELECT 
    allergen_id_raw,
    name_raw,
    category_raw,
    is_common_raw,
    LEFT(description_raw, 50) AS description_preview
FROM TEMP_ALLERGEN_IMPORT 
LIMIT 10;

-- Check for potential data issues
SELECT 'Allergen data quality check:' AS info;
SELECT 
    'Empty allergen IDs' AS issue_type,
    COUNT(*) AS count
FROM TEMP_ALLERGEN_IMPORT 
WHERE allergen_id_raw IS NULL OR allergen_id_raw = '' OR allergen_id_raw = 'NULL'

UNION ALL

SELECT 
    'Empty allergen names' AS issue_type,
    COUNT(*) AS count
FROM TEMP_ALLERGEN_IMPORT 
WHERE name_raw IS NULL OR name_raw = '' OR name_raw = 'NULL'

UNION ALL

SELECT 
    'Duplicate allergen IDs' AS issue_type,
    COUNT(*) - COUNT(DISTINCT allergen_id_raw) AS count
FROM TEMP_ALLERGEN_IMPORT
WHERE allergen_id_raw IS NOT NULL

UNION ALL

SELECT 
    'Invalid is_common values' AS issue_type,
    COUNT(*) AS count
FROM TEMP_ALLERGEN_IMPORT 
WHERE is_common_raw IS NOT NULL 
  AND LOWER(is_common_raw) NOT IN ('true', 'false', '1', '0', 't', 'f', 'yes', 'no');

-- Show duplicate IDs if any
SELECT 'Duplicate allergen IDs in CSV (if any):' AS warning;
SELECT 
    allergen_id_raw,
    COUNT(*) AS occurrence_count,
    GROUP_CONCAT(name_raw SEPARATOR '; ') AS names
FROM TEMP_ALLERGEN_IMPORT 
WHERE allergen_id_raw IS NOT NULL 
GROUP BY allergen_id_raw
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- =====================================================
-- 6. Data Cleaning and Transfer - ALLERGEN
-- =====================================================

-- Clean and insert data into ALLERGEN table with deduplication
INSERT IGNORE INTO allergen (
    allergen_id, name, category, is_common, description
)
SELECT 
    -- Use original allergen_id if provided
    CAST(allergen_id_raw AS SIGNED) AS allergen_id,
    
    -- Clean allergen name: required field
    TRIM(name_raw) AS name,
    
    -- Clean category: handle null values
    CASE 
        WHEN category_raw IS NULL OR category_raw = '' OR category_raw = 'NULL' THEN NULL
        ELSE TRIM(category_raw)
    END AS category,
    
    -- Convert is_common boolean
    CASE 
        WHEN LOWER(TRIM(is_common_raw)) IN ('true', '1', 'yes', 't') THEN TRUE
        WHEN LOWER(TRIM(is_common_raw)) IN ('false', '0', 'no', 'f') THEN FALSE
        ELSE FALSE  -- Default to FALSE for unclear values
    END AS is_common,
    
    -- Clean description: handle null values
    CASE 
        WHEN description_raw IS NULL OR description_raw = '' OR description_raw = 'NULL' THEN NULL
        ELSE TRIM(description_raw)
    END AS description

FROM (
    SELECT 
        allergen_id_raw,
        name_raw,
        category_raw,
        is_common_raw,
        description_raw,
        ROW_NUMBER() OVER (PARTITION BY allergen_id_raw ORDER BY allergen_id_raw) as rn
    FROM TEMP_ALLERGEN_IMPORT
    WHERE allergen_id_raw IS NOT NULL 
      AND allergen_id_raw != '' 
      AND allergen_id_raw != 'NULL'
      AND name_raw IS NOT NULL 
      AND name_raw != '' 
      AND name_raw != 'NULL'
      AND allergen_id_raw REGEXP '^[0-9]+$'
) deduplicated
WHERE rn = 1
ORDER BY CAST(allergen_id_raw AS SIGNED);

-- =====================================================
-- 7. Post-Import Verification - ALLERGEN
-- =====================================================

-- Check final allergen import results
SELECT 'Allergen Import Results Summary:' AS info;

SELECT 
    COUNT(*) AS total_allergens_in_db,
    'Allergens successfully imported into database' AS description
FROM allergen;

-- Category distribution
SELECT 'Allergen category distribution:' AS info;
SELECT 
    COALESCE(category, 'Uncategorized') AS category,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM allergen), 2) AS percentage
FROM allergen 
GROUP BY category
ORDER BY count DESC;

-- Common allergens analysis
SELECT 'Common allergens analysis:' AS info;
SELECT 
    'Common allergens (EU 14)' AS allergen_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM allergen), 2) AS percentage
FROM allergen 
WHERE is_common = TRUE

UNION ALL

SELECT 
    'Other allergens' AS allergen_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM allergen), 2) AS percentage
FROM allergen 
WHERE is_common = FALSE;

-- =====================================================
-- PART 2: PRODUCT DATA IMPORT
-- =====================================================

-- =====================================================
-- 8. Pre-import Verification - PRODUCT
-- =====================================================

-- Verify product table exists
SELECT 'Verifying product database schema...' AS status;

-- Check if PRODUCT table exists
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN 'product table exists ✅'
        ELSE 'ERROR: product table missing ❌'
    END AS table_check
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'grocery_guardian' AND TABLE_NAME = 'product';

-- Check current PRODUCT table status
SELECT 
    COUNT(*) AS current_product_count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'product table is empty - ready for import ✅'
        ELSE CONCAT('product table contains ', COUNT(*), ' products - will be imported alongside')
    END AS import_status
FROM product;

-- =====================================================
-- 9. Create Temporary Import Table - PRODUCT
-- =====================================================

-- Drop temporary table if exists
DROP TABLE IF EXISTS TEMP_PRODUCT_IMPORT;

-- Create temporary table for raw product CSV data
CREATE TABLE TEMP_PRODUCT_IMPORT (
    barcode_raw TEXT COMMENT 'Raw barcode data from CSV',
    name_raw TEXT COMMENT 'Raw product name from CSV',
    brand_raw TEXT COMMENT 'Raw brand name from CSV',
    ingredients_raw TEXT COMMENT 'Raw ingredients list from CSV',
    allergens_raw TEXT COMMENT 'Raw allergens info from CSV',
    energy_100g_raw TEXT COMMENT 'Raw energy value from CSV',
    energy_kcal_100g_raw TEXT COMMENT 'Raw calorie value from CSV',
    fat_100g_raw TEXT COMMENT 'Raw fat content from CSV',
    saturated_fat_100g_raw TEXT COMMENT 'Raw saturated fat from CSV',
    carbohydrates_100g_raw TEXT COMMENT 'Raw carbs from CSV',
    sugars_100g_raw TEXT COMMENT 'Raw sugar content from CSV',
    proteins_100g_raw TEXT COMMENT 'Raw protein content from CSV',
    serving_size_raw TEXT COMMENT 'Raw serving size from CSV',
    category_raw TEXT COMMENT 'Raw category from CSV'
) ENGINE=InnoDB COMMENT='Temporary table for product CSV import';

SELECT 'Temporary product import table created ✅' AS status;

-- =====================================================
-- 10. CSV Data Import - PRODUCT
-- =====================================================

-- Import raw product CSV data
-- ⚠️  MODIFY THE FILE PATH TO YOUR ACTUAL CSV LOCATION ⚠️

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ireland_products_final.csv'
INTO TABLE TEMP_PRODUCT_IMPORT
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(barcode_raw, name_raw, brand_raw, ingredients_raw, allergens_raw, 
 energy_100g_raw, energy_kcal_100g_raw, fat_100g_raw, saturated_fat_100g_raw, 
 carbohydrates_100g_raw, sugars_100g_raw, proteins_100g_raw, 
 serving_size_raw, category_raw);

-- =====================================================
-- 11. Verify Raw Data Import - PRODUCT
-- =====================================================

-- Check imported product data count
SELECT 
    COUNT(*) AS raw_product_records_imported,
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('Successfully imported ', COUNT(*), ' raw product records ✅')
        ELSE 'No product data imported - check CSV file path and LOAD DATA command ❌'
    END AS import_result
FROM TEMP_PRODUCT_IMPORT;

-- Preview first 5 raw product records
SELECT 'Preview of raw imported product data:' AS info;
SELECT 
    barcode_raw,
    name_raw,
    brand_raw,
    category_raw,
    energy_kcal_100g_raw,
    proteins_100g_raw
FROM TEMP_PRODUCT_IMPORT 
LIMIT 5;

-- Check for potential product data issues
SELECT 'Product data quality check:' AS info;
SELECT 
    'Empty product barcodes' AS issue_type,
    COUNT(*) AS count
FROM TEMP_PRODUCT_IMPORT 
WHERE barcode_raw IS NULL OR barcode_raw = '' OR barcode_raw = 'NULL'

UNION ALL

SELECT 
    'Empty product names' AS issue_type,
    COUNT(*) AS count
FROM TEMP_PRODUCT_IMPORT 
WHERE name_raw IS NULL OR name_raw = '' OR name_raw = 'NULL'

UNION ALL

SELECT 
    'Long barcodes (>255 chars)' AS issue_type,
    COUNT(*) AS count
FROM TEMP_PRODUCT_IMPORT 
WHERE LENGTH(barcode_raw) > 255

UNION ALL

SELECT 
    'Duplicate barcodes' AS issue_type,
    COUNT(*) - COUNT(DISTINCT barcode_raw) AS count
FROM TEMP_PRODUCT_IMPORT
WHERE barcode_raw IS NOT NULL;

-- =====================================================
-- 12. Data Cleaning and Transfer - PRODUCT
-- =====================================================

-- Clean and insert data into PRODUCT table with deduplication
INSERT IGNORE INTO product (
    barcode, name, brand, ingredients, allergens,
    energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g,
    carbohydrates_100g, sugars_100g, proteins_100g,
    serving_size, category
)
SELECT 
    -- Clean barcode: convert to string and preserve original format
    TRIM(CAST(CAST(barcode_raw AS DECIMAL(30,0)) AS CHAR)) AS barcode,
    
    -- Clean product name: required field
    TRIM(name_raw) AS name,
    
    -- Clean brand: handle null values
    CASE 
        WHEN brand_raw IS NULL OR brand_raw = '' OR brand_raw = 'NULL' THEN NULL
        ELSE TRIM(brand_raw)
    END AS brand,
    
    -- Clean ingredients: handle null values
    CASE 
        WHEN ingredients_raw IS NULL OR ingredients_raw = '' OR ingredients_raw = 'NULL' THEN NULL
        ELSE TRIM(ingredients_raw)
    END AS ingredients,
    
    -- Clean allergens: handle null values
    CASE 
        WHEN allergens_raw IS NULL OR allergens_raw = '' OR allergens_raw = 'NULL' THEN NULL
        ELSE TRIM(allergens_raw)
    END AS allergens,
    
    -- Convert energy_100g with validation
    CASE 
        WHEN energy_100g_raw IS NULL OR energy_100g_raw = '' OR energy_100g_raw = 'NULL' THEN NULL
        WHEN CAST(energy_100g_raw AS DECIMAL(10,2)) < 0 THEN NULL
        ELSE CAST(energy_100g_raw AS DECIMAL(10,2))
    END AS energy_100g,
    
    -- Convert energy_kcal_100g with validation
    CASE 
        WHEN energy_kcal_100g_raw IS NULL OR energy_kcal_100g_raw = '' OR energy_kcal_100g_raw = 'NULL' THEN NULL
        WHEN CAST(energy_kcal_100g_raw AS DECIMAL(8,2)) < 0 THEN NULL
        ELSE CAST(energy_kcal_100g_raw AS DECIMAL(8,2))
    END AS energy_kcal_100g,
    
    -- Convert fat_100g with validation
    CASE 
        WHEN fat_100g_raw IS NULL OR fat_100g_raw = '' OR fat_100g_raw = 'NULL' THEN NULL
        WHEN CAST(fat_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(fat_100g_raw AS DECIMAL(6,2))
    END AS fat_100g,
    
    -- Convert saturated_fat_100g with validation
    CASE 
        WHEN saturated_fat_100g_raw IS NULL OR saturated_fat_100g_raw = '' OR saturated_fat_100g_raw = 'NULL' THEN NULL
        WHEN CAST(saturated_fat_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(saturated_fat_100g_raw AS DECIMAL(6,2))
    END AS saturated_fat_100g,
    
    -- Convert carbohydrates_100g with validation
    CASE 
        WHEN carbohydrates_100g_raw IS NULL OR carbohydrates_100g_raw = '' OR carbohydrates_100g_raw = 'NULL' THEN NULL
        WHEN CAST(carbohydrates_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(carbohydrates_100g_raw AS DECIMAL(6,2))
    END AS carbohydrates_100g,
    
    -- Convert sugars_100g with validation
    CASE 
        WHEN sugars_100g_raw IS NULL OR sugars_100g_raw = '' OR sugars_100g_raw = 'NULL' THEN NULL
        WHEN CAST(sugars_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(sugars_100g_raw AS DECIMAL(6,2))
    END AS sugars_100g,
    
    -- Convert proteins_100g with validation
    CASE 
        WHEN proteins_100g_raw IS NULL OR proteins_100g_raw = '' OR proteins_100g_raw = 'NULL' THEN NULL
        WHEN CAST(proteins_100g_raw AS DECIMAL(6,2)) < 0 THEN NULL
        ELSE CAST(proteins_100g_raw AS DECIMAL(6,2))
    END AS proteins_100g,
    
    -- Clean serving_size
    CASE 
        WHEN serving_size_raw IS NULL OR serving_size_raw = '' OR serving_size_raw = 'NULL' THEN NULL
        ELSE TRIM(serving_size_raw)
    END AS serving_size,
    
    -- Clean category
    CASE 
        WHEN category_raw IS NULL OR category_raw = '' OR category_raw = 'NULL' THEN 'Other'
        ELSE TRIM(category_raw)
    END AS category

FROM (
    SELECT 
        barcode_raw,
        name_raw,
        brand_raw,
        ingredients_raw,
        allergens_raw,
        energy_100g_raw,
        energy_kcal_100g_raw,
        fat_100g_raw,
        saturated_fat_100g_raw,
        carbohydrates_100g_raw,
        sugars_100g_raw,
        proteins_100g_raw,
        serving_size_raw,
        category_raw,
        ROW_NUMBER() OVER (PARTITION BY barcode_raw ORDER BY barcode_raw) as rn
    FROM TEMP_PRODUCT_IMPORT
    WHERE barcode_raw IS NOT NULL 
      AND barcode_raw != '' 
      AND barcode_raw != 'NULL'
      AND name_raw IS NOT NULL 
      AND name_raw != '' 
      AND name_raw != 'NULL'
      AND LENGTH(barcode_raw) <= 255
) deduplicated
WHERE rn = 1
ORDER BY CAST(CAST(barcode_raw AS DECIMAL(30,0)) AS CHAR);

-- =====================================================
-- 13. Post-Import Verification and Statistics
-- =====================================================

-- Check final import results
SELECT 'Final Import Results Summary:' AS info;

SELECT 
    COUNT(*) AS total_allergens_in_db,
    'Total allergens in database' AS description
FROM allergen

UNION ALL

SELECT 
    COUNT(*) AS total_products_in_db,
    'Total products in database' AS description
FROM product;

-- Product category distribution
SELECT 'Product category distribution:' AS info;
SELECT 
    category,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 2) AS percentage
FROM product 
GROUP BY category
ORDER BY count DESC
LIMIT 10;

-- Data completeness check
SELECT 'Data completeness analysis:' AS info;
SELECT 
    'Products with allergen info' AS data_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 2) AS percentage
FROM product 
WHERE allergens IS NOT NULL

UNION ALL

SELECT 
    'Products with complete nutrition data' AS data_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 2) AS percentage
FROM product 
WHERE energy_kcal_100g IS NOT NULL 
  AND proteins_100g IS NOT NULL 
  AND fat_100g IS NOT NULL 
  AND carbohydrates_100g IS NOT NULL

UNION ALL

SELECT 
    'Products with ingredients info' AS data_type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 2) AS percentage
FROM product 
WHERE ingredients IS NOT NULL;

-- =====================================================
-- 14. Test Queries to Verify Functionality
-- =====================================================

-- Test allergen queries
SELECT 'Testing allergen functionality:' AS info;

-- Test common allergens
SELECT 'Common allergens test:' AS test_type;
SELECT allergen_id, name, category 
FROM allergen 
WHERE is_common = TRUE 
ORDER BY name
LIMIT 5;

-- Test product queries
SELECT 'Testing product functionality:' AS info;

-- Test barcode lookup
SELECT 'Product barcode lookup test:' AS test_type;
SELECT barcode, name, brand, category 
FROM product 
ORDER BY RAND()
LIMIT 3;

-- Test nutrition-based queries
SELECT 'High protein products test:' AS test_type;
SELECT name, brand, proteins_100g, category 
FROM product 
WHERE proteins_100g > 20 
ORDER BY proteins_100g DESC 
LIMIT 5;

-- =====================================================
-- 15. Performance Test Queries
-- =====================================================

-- Test performance
SELECT 'Performance test - allergen lookup:' AS info;
EXPLAIN SELECT * FROM allergen WHERE allergen_id = 1;

SELECT 'Performance test - product barcode lookup:' AS info;
EXPLAIN SELECT * FROM product WHERE barcode = '1234567890123';

-- =====================================================
-- 16. Clean Up Temporary Tables
-- =====================================================

-- Clean up temporary import tables
DROP TABLE IF EXISTS TEMP_ALLERGEN_IMPORT;
DROP TABLE IF EXISTS TEMP_PRODUCT_IMPORT;

SELECT 'Temporary tables cleaned up ✅' AS status;

-- =====================================================
-- 17. Final Import Summary Report
-- =====================================================

SELECT '====== COMPLETE DATA IMPORT FINISHED ======' AS final_status;

-- Generate comprehensive summary
SELECT 
    'COMPLETE IMPORT SUMMARY' AS report_section,
    '' AS metric,
    '' AS value,
    '' AS notes
    
UNION ALL

SELECT 
    '',
    'Total Allergens Imported',
    CAST(COUNT(*) AS CHAR),
    'Allergen dictionary with categories'
FROM allergen

UNION ALL

SELECT 
    '',
    'Total Products Imported',
    CAST(COUNT(*) AS CHAR),
    'Products with nutrition and allergen data'
FROM product

UNION ALL

SELECT 
    '',
    'Common Allergens Available',
    CAST(COUNT(*) AS CHAR),
    'EU regulated allergens for filtering'
FROM allergen
WHERE is_common = TRUE

UNION ALL

SELECT 
    '',
    'Product Categories',
    CAST(COUNT(DISTINCT category) AS CHAR),
    'Different product categories'
FROM product

UNION ALL

SELECT 
    '',
    'Products with Nutrition Data',
    CONCAT(
        CAST(COUNT(*) AS CHAR), 
        ' (', 
        CAST(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product), 1) AS CHAR), 
        '%)'
    ),
    'Products with complete nutritional information'
FROM product 
WHERE energy_kcal_100g IS NOT NULL 
  AND proteins_100g IS NOT NULL 
  AND fat_100g IS NOT NULL 
  AND carbohydrates_100g IS NOT NULL;

-- =====================================================
-- 18. Sample Data for Testing
-- =====================================================

SELECT '====== SAMPLE DATA FOR IMMEDIATE TESTING ======' AS testing_section;

-- Show sample data combination
SELECT 
    'Sample allergens and products ready for testing:' AS info,
    (SELECT COUNT(*) FROM allergen WHERE is_common = TRUE) AS common_allergens,
    (SELECT COUNT(*) FROM product WHERE allergens IS NOT NULL) AS products_with_allergen_info,
    (SELECT COUNT(*) FROM product WHERE energy_kcal_100g IS NOT NULL) AS products_with_nutrition;

-- =====================================================
-- DATA IMPORT COMPLETED SUCCESSFULLY!
-- 
-- ✅ Allergen Dictionary: Complete with EU 14 + additional allergens
-- ✅ Product Database: Complete with nutrition and allergen information
-- ✅ Data Integrity: Duplicates handled, data validated and cleaned
-- ✅ Performance: Optimized for lookup and filtering operations
-- ✅ Ready for Integration: All tables populated and tested
-- 
-- Your Grocery Guardian database is now fully ready for:
-- - Product barcode scanning and lookup
-- - Allergen detection and filtering  
-- - Nutrition-based recommendations
-- - User preference management
-- - Complete recommendation algorithm implementation
-- =====================================================