package com.demo.backend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StreamUtils;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Data Initialization Service
 * Automatically imports data in specified order after Spring Boot application startup
 * 
 * Import order:
 * 1. data_import.sql
 * 2. product_allergen_data.sql  
 * 3. test-data.sql
 * 4. allergen_dictionary.csv
 * 5. ireland_products_final.csv
 */
@Service
public class DataInitializationService implements CommandLineRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Value("${app.data.auto-import:true}")
    private boolean autoImport;
    
    @Value("${app.data.force-reimport:false}")
    private boolean forceReimport;

    @Override
    public void run(String... args) throws Exception {
        if (!autoImport) {
            System.out.println("Automatic data import is disabled (app.data.auto-import=false)");
            return;
        }
        
        System.out.println("=== Starting Data Initialization Process ===");
        
        // Check if data initialization should be skipped (avoid duplicate imports)
        if (!forceReimport && shouldSkipDataInitialization()) {
            System.out.println("Database already contains data, skipping data initialization (use app.data.force-reimport=true to force re-import)");
            return;
        }
        
        if (forceReimport) {
            System.out.println("Force re-import mode enabled, cleaning existing data...");
            cleanExistingData();
        }

        try {
            // 1. Execute data_import.sql
            executeDataImportSql();
            
            // 2. Execute product_allergen_data.sql
            executeProductAllergenDataSql();
            
            // 3. Execute test-data.sql
            executeTestDataSql();
            
            // 4. Import allergen_dictionary.csv
            importAllergenDictionary();
            
            // 5. Import ireland_products_final.csv
            importIrelandProducts();
            
            System.out.println("=== Data Initialization Complete ===");
            
        } catch (Exception e) {
            System.err.println("Data initialization failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // Public methods for controller usage
    public boolean isAutoImportEnabled() {
        return autoImport;
    }
    
    public boolean isForceReimportEnabled() {
        return forceReimport;
    }
    
    public void setAutoImport(boolean autoImport) {
        this.autoImport = autoImport;
    }
    
    public void setForceReimport(boolean forceReimport) {
        this.forceReimport = forceReimport;
    }
    
    /**
     * Check if data initialization should be skipped
     * Skip if database already contains data
     */
    public boolean shouldSkipDataInitialization() {
        try {
            // Check if key tables have data
            Integer userCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM user", Integer.class);
            Integer productCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM product", Integer.class);
            Integer allergenCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM allergen", Integer.class);
            
            return (userCount != null && userCount > 0) || 
                   (productCount != null && productCount > 0) || 
                   (allergenCount != null && allergenCount > 0);
                   
        } catch (Exception e) {
            System.out.println("Error checking database status, continuing with data initialization: " + e.getMessage());
            return false;
        }
    }
    
    /**
     * Clean existing data (for force re-import)
     */
    public void cleanExistingData() {
        try {
            System.out.println("Cleaning existing data...");
            
            // Delete data in reverse order of foreign key dependencies
            String[] cleanupTables = {
                "recommendation_log", "barcode_history", "receipt_history", 
                "purchase_item", "purchase_record", "scan_history",
                "daily_sugar_summary", "sugar_intake_history", "sugar_goals", 
                "monthly_statistics", "product_preference", "user_allergen", 
                "user_preference", "product_allergen", "product", "allergen", "user"
            };
            
            for (String table : cleanupTables) {
                try {
                    jdbcTemplate.execute("DELETE FROM " + table);
                    System.out.println("Cleaned table: " + table);
                } catch (Exception e) {
                    System.out.println("Error cleaning table " + table + " (table may not exist): " + e.getMessage());
                }
            }
            
            System.out.println("********** Data cleanup complete");
            
        } catch (Exception e) {
            System.err.println("Error during data cleanup: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Execute data_import.sql
     */
    private void executeDataImportSql() {
        System.out.println("1. Executing data_import.sql...");
        executeSqlFile("data/data_import.sql");
        System.out.println("**********  data_import.sql execution complete");
    }

    /**
     * Execute product_allergen_data.sql
     */
    private void executeProductAllergenDataSql() {
        System.out.println("2. Executing product_allergen_data.sql...");
        executeSqlFile("data/product_allergen_data.sql");
        System.out.println("**********  product_allergen_data.sql execution complete");
    }

    /**
     * Execute test-data.sql
     */
    private void executeTestDataSql() {
        System.out.println("3. Executing test-data.sql...");
        executeSqlFile("data/test-data.sql");
        System.out.println("**********  test-data.sql execution complete");
    }

    /**
     * Import allergen_dictionary.csv
     */
    private void importAllergenDictionary() {
        System.out.println("4. Importing allergen_dictionary.csv...");
        
        try {
            ClassPathResource resource = new ClassPathResource("data/allergen_dictionary.csv");
            if (!resource.exists()) {
                System.err.println("XXXXXXXXX File not found: data/allergen_dictionary.csv");
                return;
            }
            
            BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8));
            
            String line;
            boolean isFirstLine = true;
            int importedCount = 0;
            int errorCount = 0;
            
            while ((line = reader.readLine()) != null) {
                if (isFirstLine) {
                    isFirstLine = false;
                    continue; // Skip header row
                }
                
                try {
                    String[] parts = parseCsvLineAdvanced(line);
                    if (parts.length >= 5) {
                        String allergenIdStr = cleanString(parts[0]);
                        String name = cleanString(parts[1]);
                        String category = cleanString(parts[2]);
                        String isCommonStr = cleanString(parts[3]);
                        String description = cleanString(parts[4]);
                        
                        if (!allergenIdStr.isEmpty() && !name.isEmpty()) {
                            // Insert or update allergen data
                            String sql = "INSERT IGNORE INTO allergen (allergen_id, name, category, is_common, description) VALUES (?, ?, ?, ?, ?)";
                            int allergenId = Integer.parseInt(allergenIdStr);
                            boolean isCommon = "true".equalsIgnoreCase(isCommonStr) || "1".equals(isCommonStr);
                            
                            jdbcTemplate.update(sql, allergenId, name, category, isCommon, description);
                            importedCount++;
                        }
                    }
                } catch (Exception e) {
                    errorCount++;
                    System.err.println("Failed to import allergen record: " + line.substring(0, Math.min(50, line.length())) + "... - " + e.getMessage());
                }
            }
            reader.close();
            
            System.out.println("**********  allergen_dictionary.csv import complete, success: " + importedCount + " records, failed: " + errorCount + " records");
            
        } catch (Exception e) {
            System.err.println("Failed to import allergen_dictionary.csv: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Import ireland_products_final.csv
     */
    private void importIrelandProducts() {
        System.out.println("5. Importing ireland_products_final.csv...");
        
        try {
            ClassPathResource resource = new ClassPathResource("data/ireland_products_final.csv");
            if (!resource.exists()) {
                System.err.println("XXXXXXXXX File not found: data/ireland_products_final.csv");
                return;
            }
            
            BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8));
            
            String line;
            boolean isFirstLine = true;
            int importedCount = 0;
            int errorCount = 0;
            int batchSize = 1000;
            
            System.out.println("Starting product data import, this may take some time...");
            
            while ((line = reader.readLine()) != null) {
                if (isFirstLine) {
                    isFirstLine = false;
                    continue; // Skip header row
                }
                
                try {
                    // Parse CSV line
                    String[] parts = parseCsvLineAdvanced(line);
                    if (parts.length >= 14) { // Ensure sufficient fields
                        if (insertProductData(parts)) {
                            importedCount++;
                        } else {
                            errorCount++;
                        }
                        
                        if ((importedCount + errorCount) % batchSize == 0) {
                            System.out.println("Processed " + (importedCount + errorCount) + " records, success: " + importedCount + ", failed: " + errorCount);
                        }
                    } else {
                        errorCount++;
                    }
                } catch (Exception e) {
                    errorCount++;
                    if (errorCount % 100 == 0) { // Only show partial errors to avoid excessive logging
                        System.err.println("Failed to import product record (error #" + errorCount + "): " + e.getMessage());
                    }
                }
            }
            reader.close();
            
            System.out.println("**********  ireland_products_final.csv import complete, success: " + importedCount + " records, failed: " + errorCount + " records");
            
        } catch (Exception e) {
            System.err.println("Failed to import ireland_products_final.csv: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Parse CSV line, handle quotes and commas
     */
    private String[] parseCsvLine(String line) {
        // Simple CSV parsing, can be improved as needed
        return line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
    }
    
    /**
     * Advanced CSV line parsing, better handling of quotes and special characters
     */
    private String[] parseCsvLineAdvanced(String line) {
        if (line == null || line.trim().isEmpty()) {
            return new String[0];
        }
        
        // More robust method for handling quotes and commas in CSV
        return line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)");
    }

    /**
     * Insert product data
     * CSV format: barcode,name,brand,ingredients,allergens,energy_100g,energy_kcal_100g,fat_100g,saturated_fat_100g,carbohydrates_100g,sugars_100g,proteins_100g,serving_size,category
     * @return true if successful, false if failed
     */
    private boolean insertProductData(String[] parts) {
        if (parts.length < 14) return false; // Ensure sufficient fields
        
        try {
            String barcode = cleanString(parts[0]);
            String name = cleanString(parts[1]);
            String brand = cleanString(parts[2]);
            String ingredients = cleanString(parts[3]);
            String allergens = cleanString(parts[4]);
            
            // Nutrition information
            Float energy100g = parseFloat(parts[5]);
            Float energyKcal100g = parseFloat(parts[6]);
            Float fat100g = parseFloat(parts[7]);
            Float saturatedFat100g = parseFloat(parts[8]);
            Float carbohydrates100g = parseFloat(parts[9]);
            Float sugars100g = parseFloat(parts[10]);
            Float proteins100g = parseFloat(parts[11]);
            String servingSize = cleanString(parts[12]);
            String category = cleanString(parts[13]);
            
            if (!barcode.isEmpty() && !name.isEmpty()) {
                String sql = "INSERT IGNORE INTO product (barcode, name, brand, ingredients, allergens, " +
                            "energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g, carbohydrates_100g, " +
                            "sugars_100g, proteins_100g, serving_size, category) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                jdbcTemplate.update(sql, barcode, name, brand, ingredients, allergens,
                                   energy100g, energyKcal100g, fat100g, saturatedFat100g, carbohydrates100g,
                                   sugars100g, proteins100g, servingSize, category);
                return true;
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Safely parse float values
     */
    private Float parseFloat(String str) {
        try {
            String cleaned = cleanString(str);
            return cleaned.isEmpty() ? null : Float.parseFloat(cleaned);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Clean string, remove quotes and trim whitespace
     */
    private String cleanString(String str) {
        if (str == null) return "";
        return str.trim().replace("\"", "");
    }

    /**
     * Execute SQL file
     */
    private void executeSqlFile(String filePath) {
        try {
            ClassPathResource resource = new ClassPathResource(filePath);
            String content = StreamUtils.copyToString(resource.getInputStream(), StandardCharsets.UTF_8);
            
            // Remove LOAD DATA statements due to cross-platform path incompatibility
            content = removeLoadDataStatements(content);
            
            // More intelligent SQL statement splitting
            String[] statements = splitSqlStatements(content);
            
            int successCount = 0;
            int errorCount = 0;
            int skippedCount = 0;
            
            for (String statement : statements) {
                statement = statement.trim();
                if (!statement.isEmpty() && !isCommentLine(statement)) {
                    try {
                        // Skip statements containing variable references that need special handling
                        if (containsVariableReferences(statement)) {
                            skippedCount++;
                            continue;
                        }
                        
                        jdbcTemplate.execute(statement);
                        successCount++;
                    } catch (Exception e) {
                        errorCount++;
                        // Only show unexpected errors
                        if (!isExpectedError(e.getMessage())) {
                            System.err.println("Failed to execute SQL statement: " + statement.substring(0, Math.min(100, statement.length())) + "...");
                            System.err.println("Error: " + e.getMessage());
                        }
                        // Continue executing other statements without interrupting the entire process
                    }
                }
            }
            
            if (skippedCount > 0) {
                System.out.println("SQL file execution complete - success: " + successCount + ", failed: " + errorCount + ", skipped: " + skippedCount);
            } else {
                System.out.println("SQL file execution complete - success: " + successCount + ", failed: " + errorCount);
            }
            
        } catch (Exception e) {
            System.err.println("Failed to execute SQL file " + filePath + ": " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Remove LOAD DATA statements, replace with Java CSV import
     */
    private String removeLoadDataStatements(String content) {
        // Remove LOAD DATA LOCAL INFILE statements
        content = content.replaceAll("(?i)LOAD\\s+DATA\\s+LOCAL\\s+INFILE[^;]*;", 
                                   "-- LOAD DATA statement removed (replaced by Java CSV import)");
        return content;
    }
    
    /**
     * Check if statement contains variable references
     */
    private boolean containsVariableReferences(String statement) {
        String upperStatement = statement.toUpperCase();
        return statement.contains("@") || 
               (upperStatement.contains("SELECT") && statement.contains("LIMIT") && statement.contains("barcode")) ||
               upperStatement.contains("LOAD DATA") ||
               statement.contains("INTO TABLE TEMP_");
    }
    
    /**
     * Check if error is expected (can be ignored)
     */
    private boolean isExpectedError(String errorMessage) {
        if (errorMessage == null) return false;
        
        return errorMessage.contains("Duplicate entry") ||
               errorMessage.contains("doesn't exist") ||
               errorMessage.contains("Unknown column") ||
               errorMessage.contains("foreign key constraint fails") ||
               errorMessage.contains("Table") && errorMessage.contains("already exists");
    }
    
    /**
     * Intelligently split SQL statements
     */
    private String[] splitSqlStatements(String content) {
        // Remove multi-line comments
        content = content.replaceAll("/\\*[\\s\\S]*?\\*/", "");
        
        // Process line by line, remove single-line comments
        String[] lines = content.split("\n");
        StringBuilder cleanedContent = new StringBuilder();
        
        for (String line : lines) {
            line = line.trim();
            if (!isCommentLine(line) && !line.isEmpty()) {
                cleanedContent.append(line).append("\n");
            }
        }
        
        // Split by semicolon while preserving complete statements
        return cleanedContent.toString().split(";(?=\\s*(?:[^']*'[^']*')*[^']*$)");
    }
    
    /**
     * Check if line is a comment
     */
    private boolean isCommentLine(String line) {
        line = line.trim();
        return line.startsWith("--") || line.startsWith("/*") || line.startsWith("*") || 
               line.startsWith("#") || line.equals("*/");
    }
} 