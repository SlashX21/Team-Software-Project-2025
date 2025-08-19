// package com.demo.backend;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.boot.CommandLineRunner;
// import org.springframework.core.io.ClassPathResource;
// import org.springframework.jdbc.core.JdbcTemplate;
// import org.springframework.stereotype.Service;
// import org.springframework.util.StreamUtils;

// import java.io.BufferedReader;
// import java.io.InputStreamReader;
// import java.nio.charset.StandardCharsets;

// /**
//  * 启动时自动初始化数据
//  * 执行顺序：
//  * 1. data_import.sql
//  * 2. allergen_dictionary.csv
//  * 3. ireland_products_final.csv
//  * 4. product_allergen_data.sql
//  * 5. test-data.sql
//  */
// @Service
// public class DataInitializationService implements CommandLineRunner {

//     @Autowired
//     private JdbcTemplate jdbcTemplate;

//     @Override
//     public void run(String... args) throws Exception {
//         System.out.println("=== 开始数据初始化 ===");
        
//         try {
//             // 1. 执行 data_import.sql
//             System.out.println("\n\n******************\n\n");
//             executeSqlFile("data/data_import.sql");
//             System.out.println("\n\n******************\n\n");


//             // 2. 导入 allergen_dictionary.csv
//             System.out.println("\n\n******************\n\n");
//             importAllergenDictionary();
//             System.out.println("\n\n******************\n\n");

//             // 3. 导入 ireland_products_final.csv
//             System.out.println("\n\n******************\n\n");
//             importIrelandProducts();
//             System.out.println("\n\n******************\n\n");
            
//             // 4. 执行 product_allergen_data.sql
//             System.out.println("\n\n******************\n\n");
//             executeSqlFile("data/product_allergen_data.sql");
//             System.out.println("\n\n******************\n\n");

//             // 5. 执行 test-data.sql
//             System.out.println("\n\n******************\n\n");
//             executeSqlFile("data/test-data.sql");
//             System.out.println("\n\n******************\n\n");
            
//             System.out.println("=== 数据初始化完成 ===");
            
//         } catch (Exception e) {
//             System.err.println("数据初始化失败: " + e.getMessage());
//             e.printStackTrace();
//         }
//     }

//     /**
//      * 执行 SQL 文件
//      */
//     private void executeSqlFile(String filePath) {
//         System.out.println("执行文件: " + filePath);
//         try {
//             ClassPathResource resource = new ClassPathResource(filePath);
//             String content = StreamUtils.copyToString(resource.getInputStream(), StandardCharsets.UTF_8);
            
//             // 移除 LOAD DATA 语句和临时表查询（因为我们用Java处理CSV）
//             content = cleanSqlContent(content);
            
//             // 更智能的SQL语句分割
//             String[] statements = splitSqlStatements(content);
            
//             int count = 0;
//             int skipped = 0;
//             for (String statement : statements) {
//                 statement = statement.trim();
//                 if (!statement.isEmpty() && !isCommentLine(statement)) {
//                     // 跳过临时表相关操作和变量赋值
//                     if (shouldSkipStatement(statement)) {
//                         skipped++;
//                         continue;
//                     }
                    
//                     try {
//                         jdbcTemplate.execute(statement);
//                         count++;
//                     } catch (Exception e) {
//                         // 忽略预期的错误
//                         if (!isExpectedError(e.getMessage())) {
//                             System.err.println("SQL 执行错误: " + e.getMessage());
//                             System.err.println("语句: " + statement.substring(0, Math.min(100, statement.length())) + "...");
//                         }
//                     }
//                 }
//             }
//             System.out.println(filePath + " 执行完成，成功: " + count + " 条，跳过: " + skipped + " 条");
            
//         } catch (Exception e) {
//             System.err.println("执行 " + filePath + " 失败: " + e.getMessage());
//         }
//     }

//     /**
//      * 清理SQL内容，移除不需要的部分
//      */
//     private String cleanSqlContent(String content) {
//         // 移除 LOAD DATA 语句
//         content = content.replaceAll("(?i)LOAD\\s+DATA[^;]*;", "-- LOAD DATA removed");
        
//         // 移除 USE 语句
//         content = content.replaceAll("(?i)USE\\s+[^;]+;", "-- USE statement removed");
        
//         // 移除 SET GLOBAL 语句
//         content = content.replaceAll("(?i)SET\\s+GLOBAL[^;]*;", "-- SET GLOBAL removed");
        
//         return content;
//     }

//     /**
//      * 智能分割SQL语句
//      */
//     private String[] splitSqlStatements(String content) {
//         // 移除多行注释
//         content = content.replaceAll("/\\*[\\s\\S]*?\\*/", "");
        
//         // 按行处理，移除单行注释
//         String[] lines = content.split("\n");
//         StringBuilder cleanedContent = new StringBuilder();
        
//         for (String line : lines) {
//             line = line.trim();
//             if (!isCommentLine(line) && !line.isEmpty()) {
//                 cleanedContent.append(line).append("\n");
//             }
//         }
        
//         // 更智能的分号分割，考虑字符串中的分号
//         return cleanedContent.toString().split(";(?=\\s*(?:[^']*'[^']*')*[^']*$)");
//     }

//     /**
//      * 判断是否为注释行
//      */
//     private boolean isCommentLine(String line) {
//         line = line.trim();
//         return line.startsWith("--") || line.startsWith("/*") || line.startsWith("*") || 
//                line.startsWith("#") || line.equals("*/");
//     }

//     /**
//      * 判断是否应该跳过该语句
//      */
//     private boolean shouldSkipStatement(String statement) {
//         String upper = statement.toUpperCase();
        
//         // 跳过临时表相关操作
//         if (upper.contains("TEMP_") || upper.contains("TEMPORARY")) {
//             return true;
//         }
        
//         // 跳过 SELECT 查询（这些主要是验证语句）
//         if (upper.startsWith("SELECT") && !upper.contains("INTO")) {
//             return true;
//         }
        
//         return false;
//     }

//     /**
//      * 判断是否为预期错误（可以忽略）
//      */
//     private boolean isExpectedError(String errorMessage) {
//         if (errorMessage == null) return false;
        
//         String lowerMessage = errorMessage.toLowerCase();
        
//         return lowerMessage.contains("duplicate entry") ||
//                lowerMessage.contains("doesn't exist") ||
//                lowerMessage.contains("unknown column") ||
//                lowerMessage.contains("foreign key constraint fails") ||
//                lowerMessage.contains("table") && lowerMessage.contains("already exists") ||
//                lowerMessage.contains("syntax error") ||
//                lowerMessage.contains("out of range value");
//     }

//     /**
//      * 导入 allergen_dictionary.csv
//      */
//     private void importAllergenDictionary() {
//         System.out.println("导入文件: allergen_dictionary.csv");
//         try {
//             ClassPathResource resource = new ClassPathResource("data/allergen_dictionary.csv");
//             BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8));
            
//             String line;
//             boolean isFirstLine = true;
//             int count = 0;
            
//             while ((line = reader.readLine()) != null) {
//                 if (isFirstLine) {
//                     isFirstLine = false;
//                     continue; // 跳过标题行
//                 }
                
//                 try {
//                     String[] parts = line.split(",");
//                     if (parts.length >= 5) {
//                         String allergenId = parts[0].trim().replace("\"", "");
//                         String name = parts[1].trim().replace("\"", "");
//                         String category = parts[2].trim().replace("\"", "");
//                         String isCommon = parts[3].trim().replace("\"", "");
//                         String description = parts[4].trim().replace("\"", "");
                        
//                         String sql = "INSERT IGNORE INTO allergen (allergen_id, name, category, is_common, description) VALUES (?, ?, ?, ?, ?)";
//                         jdbcTemplate.update(sql, Integer.parseInt(allergenId), name, category, 
//                                           "true".equalsIgnoreCase(isCommon), description);
//                         count++;
//                     }
//                 } catch (Exception e) {
//                     // 忽略单行错误
//                 }
//             }
//             reader.close();
//             System.out.println("allergen_dictionary.csv 导入完成，共 " + count + " 条记录");
            
//         } catch (Exception e) {
//             System.err.println("导入 allergen_dictionary.csv 失败: " + e.getMessage());
//         }
//     }

//     /**
//      * 导入 ireland_products_final.csv
//      */
//     private void importIrelandProducts() {
//         System.out.println("导入文件: ireland_products_final.csv");
//         try {
//             ClassPathResource resource = new ClassPathResource("data/ireland_products_final.csv");
//             BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8));
            
//             String line;
//             boolean isFirstLine = true;
//             int count = 0;
            
//             while ((line = reader.readLine()) != null) {
//                 if (isFirstLine) {
//                     isFirstLine = false;
//                     continue; // 跳过标题行
//                 }
                
//                 try {
//                     String[] parts = line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
//                     if (parts.length >= 14) {
//                         String barcode = clean(parts[0]);
//                         String name = clean(parts[1]);
//                         String brand = clean(parts[2]);
//                         String ingredients = clean(parts[3]);
//                         String allergens = clean(parts[4]);
                        
//                         String sql = "INSERT IGNORE INTO product (barcode, name, brand, ingredients, allergens, " +
//                                    "energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g, carbohydrates_100g, " +
//                                    "sugars_100g, proteins_100g, serving_size, category) " +
//                                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                        
//                         jdbcTemplate.update(sql, barcode, name, brand, ingredients, allergens,
//                                           parseFloat(parts[5]), parseFloat(parts[6]), parseFloat(parts[7]),
//                                           parseFloat(parts[8]), parseFloat(parts[9]), parseFloat(parts[10]),
//                                           parseFloat(parts[11]), clean(parts[12]), clean(parts[13]));
//                         count++;
                        
//                         if (count % 1000 == 0) {
//                             System.out.println("已处理 " + count + " 条产品记录");
//                         }
//                     }
//                 } catch (Exception e) {
//                     // 忽略单行错误
//                 }
//             }
//             reader.close();
//             System.out.println("ireland_products_final.csv 导入完成，共 " + count + " 条记录");
            
//         } catch (Exception e) {
//             System.err.println("导入 ireland_products_final.csv 失败: " + e.getMessage());
//         }
//     }

//     /**
//      * 清理字符串
//      */
//     private String clean(String str) {
//         if (str == null) return "";
//         return str.trim().replace("\"", "");
//     }

//     /**
//      * 解析浮点数
//      */
//     private Float parseFloat(String str) {
//         try {
//             String cleaned = clean(str);
//             return cleaned.isEmpty() ? null : Float.parseFloat(cleaned);
//         } catch (Exception e) {
//             return null;
//         }
//     }
// } 