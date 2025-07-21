-- =====================================================
-- 简化版产品-过敏原关联生成器
-- 避免临时表的复杂操作和MySQL限制
-- =====================================================

USE springboot_demo;

-- =====================================================
-- 第一步：清理和状态检查
-- =====================================================

SELECT '====== 开始生成产品-过敏原关联 ======' AS step_info;

-- 关闭安全模式
SET SQL_SAFE_UPDATES = 0;

-- 清理现有数据
TRUNCATE TABLE product_allergen;

-- 检查数据状态
SELECT 
    'Products with allergen info' AS data_type,
    COUNT(*) AS count
FROM product 
WHERE allergens IS NOT NULL AND allergens != ''
UNION ALL
SELECT 
    'Total allergens in dictionary' AS data_type,
    COUNT(*) AS count
FROM allergen;

-- =====================================================
-- 第二步：直接生成关联关系（避免临时表）
-- =====================================================

-- 创建数字表用于分割字符串
DROP TABLE IF EXISTS numbers_temp;
CREATE TABLE numbers_temp (n INT PRIMARY KEY);
INSERT INTO numbers_temp VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20);

-- 1. 精确匹配插入
INSERT INTO product_allergen (barcode, allergen_id, presence_type, confidence_score)
SELECT DISTINCT
    p.barcode,
    a.allergen_id,
    'CONTAINS',
    0.95
FROM product p
CROSS JOIN numbers_temp num
JOIN allergen a ON LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1))) = LOWER(TRIM(a.name))
WHERE p.allergens IS NOT NULL 
  AND p.allergens != ''
  AND CHAR_LENGTH(p.allergens) - CHAR_LENGTH(REPLACE(p.allergens, ',', '')) >= num.n - 1
  AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1)) != '';

-- 2. 包含匹配插入（避免重复）
INSERT INTO product_allergen (barcode, allergen_id, presence_type, confidence_score)
SELECT DISTINCT
    p.barcode,
    a.allergen_id,
    'MAY_CONTAIN',
    0.85
FROM product p
CROSS JOIN numbers_temp num
JOIN allergen a ON LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1))) LIKE CONCAT('%', LOWER(a.name), '%')
WHERE p.allergens IS NOT NULL 
  AND p.allergens != ''
  AND CHAR_LENGTH(p.allergens) - CHAR_LENGTH(REPLACE(p.allergens, ',', '')) >= num.n - 1
  AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1)) != ''
  AND CHAR_LENGTH(a.name) >= 4
  AND NOT EXISTS (
    SELECT 1 FROM product_allergen pa_existing 
    WHERE pa_existing.barcode = p.barcode 
    AND pa_existing.allergen_id = a.allergen_id
  );

-- 3. 常见同义词匹配
INSERT INTO product_allergen (barcode, allergen_id, presence_type, confidence_score)
SELECT DISTINCT
    p.barcode,
    a.allergen_id,
    'CONTAINS',
    0.90
FROM product p
CROSS JOIN numbers_temp num
JOIN allergen a ON (
    -- 麸质相关同义词
    (LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1))) IN ('gluten', 'wheat', 'barley', 'rye') 
     AND LOWER(a.name) LIKE '%gluten%') OR
    -- 坚果相关同义词
    (LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1))) IN ('nuts', 'tree-nuts', 'almonds', 'hazelnuts', 'walnuts') 
     AND LOWER(a.name) LIKE '%nut%') OR
    -- 鸡蛋相关同义词
    (LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1))) IN ('egg', 'eggs', 'egg-white', 'egg-yolk') 
     AND LOWER(a.name) = 'eggs') OR
    -- 大豆相关同义词
    (LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1))) IN ('soy', 'soya', 'soybean') 
     AND LOWER(a.name) = 'soybeans') OR
    -- 硫化物相关同义词
    (LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1))) IN ('sulphites', 'sulfites', 'sulphur-dioxide') 
     AND LOWER(a.name) LIKE '%sulph%')
)
WHERE p.allergens IS NOT NULL 
  AND p.allergens != ''
  AND CHAR_LENGTH(p.allergens) - CHAR_LENGTH(REPLACE(p.allergens, ',', '')) >= num.n - 1
  AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.allergens, ',', num.n), ',', -1)) != ''
  AND NOT EXISTS (
    SELECT 1 FROM product_allergen pa_existing 
    WHERE pa_existing.barcode = p.barcode 
    AND pa_existing.allergen_id = a.allergen_id
  );

-- 清理临时数字表
DROP TABLE numbers_temp;

-- =====================================================
-- 第三步：数据分析和报告
-- =====================================================

SELECT '====== 生成结果分析 ======' AS analysis_section;

-- 基础统计
SELECT 
    'Total associations created' AS metric,
    COUNT(*) AS count
FROM product_allergen
UNION ALL
SELECT 
    'Products with associations' AS metric,
    COUNT(DISTINCT barcode) AS count
FROM product_allergen
UNION ALL
SELECT 
    'Allergens found' AS metric,
    COUNT(DISTINCT allergen_id) AS count
FROM product_allergen;

-- 按置信度类型统计
SELECT 'Associations by confidence type' AS breakdown_type;
SELECT 
    presence_type,
    COUNT(*) as count,
    COUNT(DISTINCT barcode) as unique_products,
    ROUND(AVG(confidence_score), 3) as avg_confidence
FROM product_allergen
GROUP BY presence_type;

-- 最常见的过敏原
SELECT 'Most common allergens in products' AS common_allergens;
SELECT 
    a.name as allergen_name,
    a.category,
    a.is_common,
    COUNT(pa.barcode) as product_count,
    ROUND(AVG(pa.confidence_score), 3) as avg_confidence
FROM allergen a
JOIN product_allergen pa ON a.allergen_id = pa.allergen_id
GROUP BY a.allergen_id, a.name, a.category, a.is_common
ORDER BY product_count DESC
LIMIT 15;

-- EU 14 过敏原覆盖情况
SELECT 'EU 14 allergen coverage' AS eu14_status;
SELECT 
    a.name as allergen_name,
    CASE WHEN COUNT(pa.barcode) > 0 THEN CONCAT('✅ ', COUNT(pa.barcode), ' products') 
         ELSE '❌ Not found' END as status
FROM allergen a
LEFT JOIN product_allergen pa ON a.allergen_id = pa.allergen_id
WHERE a.is_common = TRUE
GROUP BY a.allergen_id, a.name
ORDER BY COUNT(pa.barcode) DESC;

-- 数据质量评估
SELECT 'Data quality metrics' AS quality_check;
SELECT 
    'Products with original allergen text' AS metric,
    COUNT(*) AS count
FROM product WHERE allergens IS NOT NULL AND allergens != ''
UNION ALL
SELECT 
    'Products successfully processed' AS metric,
    COUNT(DISTINCT barcode) AS count
FROM product_allergen
UNION ALL
SELECT 
    'Processing success rate (%)' AS metric,
    ROUND(
        (SELECT COUNT(DISTINCT barcode) FROM product_allergen) * 100.0 / 
        (SELECT COUNT(*) FROM product WHERE allergens IS NOT NULL AND allergens != ''), 
        1
    ) AS count;

-- 一些具体的关联示例
SELECT 'Sample product-allergen associations' AS sample_data;
SELECT 
    p.name as product_name,
    p.allergens as original_allergens,
    a.name as matched_allergen,
    pa.presence_type,
    pa.confidence_score
FROM product_allergen pa
JOIN product p ON pa.barcode = p.barcode
JOIN allergen a ON pa.allergen_id = a.allergen_id
ORDER BY pa.confidence_score DESC, p.name
LIMIT 10;

-- 恢复安全模式
SET SQL_SAFE_UPDATES = 1;

SELECT '🎉 产品-过敏原关联表生成完成！' AS completion_message;
SELECT 'ℹ️  现在可以运行用户测试数据脚本进行完整的关联测试。' AS next_step;