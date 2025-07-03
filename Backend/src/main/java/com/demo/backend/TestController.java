// package com.demo.backend;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.context.ApplicationContext;
// import org.springframework.web.bind.annotation.GetMapping;
// import org.springframework.web.bind.annotation.RestController;
// import org.springframework.jdbc.core.JdbcTemplate;
// import org.springframework.web.bind.annotation.PostMapping;

// @RestController
// public class TestController {
    
//     @Autowired
//     private ApplicationContext applicationContext;
    
//     @Autowired
//     private JdbcTemplate jdbcTemplate;
    
//     @GetMapping("/test")
//     public String test() {
//         return "Spring Boot Backend is working!";
//     }
    
//     @GetMapping("/beans")
//     public String listBeans() {
//         StringBuilder sb = new StringBuilder();
//         String[] beanNames = applicationContext.getBeanDefinitionNames();
//         sb.append("Total beans: ").append(beanNames.length).append("\n\n");
        
//         for (String beanName : beanNames) {
//             if (beanName.toLowerCase().contains("controller") || 
//                 beanName.toLowerCase().contains("user") ||
//                 beanName.toLowerCase().contains("scan") ||
//                 beanName.toLowerCase().contains("history")) {
//                 sb.append(beanName).append(" -> ")
//                   .append(applicationContext.getBean(beanName).getClass().getName())
//                   .append("\n");
//             }
//         }
//         return sb.toString();
//     }
    
//     @GetMapping("/test/tables")
//     public String checkTables() {
//         try {
//             StringBuilder sb = new StringBuilder();
//             sb.append("Database Tables:\n\n");
            
//             String sql = "SHOW TABLES";
//             var tables = jdbcTemplate.queryForList(sql, String.class);
            
//             for (String table : tables) {
//                 sb.append(table).append("\n");
//             }
            
//             return sb.toString();
//         } catch (Exception e) {
//             return "Error checking tables: " + e.getMessage();
//         }
//     }
    
//     @GetMapping("/test/user-structure")
//     public String checkUserStructure() {
//         try {
//             StringBuilder sb = new StringBuilder();
//             sb.append("User table structure:\n\n");
            
//             String sql = "DESCRIBE user";
//             var columns = jdbcTemplate.queryForList(sql);
            
//             for (var column : columns) {
//                 sb.append(column.toString()).append("\n");
//             }
            
//             return sb.toString();
//         } catch (Exception e) {
//             return "Error checking user structure: " + e.getMessage();
//         }
//     }
    
//     @PostMapping("/test/add-scan-data") 
//     public String addTestScanData() {
//         try {
//             // First drop the problematic foreign key constraint if it exists
//             try {
//                 String dropFkSql = "ALTER TABLE scan_history DROP FOREIGN KEY fk_scan_history_product";
//                 jdbcTemplate.execute(dropFkSql);
//             } catch (Exception e) {
//                 // Ignore if constraint doesn't exist
//             }
            
//             // Check if user exists, if not create one
//             String checkUserSql = "SELECT COUNT(*) FROM user WHERE user_id = 1";
//             Integer userCount = jdbcTemplate.queryForObject(checkUserSql, Integer.class);
            
//             if (userCount == 0) {
//                 String userSql = "INSERT INTO user (user_id, username, password_hash, email) VALUES (1, 'testuser', 'password123', 'test@example.com')";
//                 jdbcTemplate.update(userSql);
//             }
            
//             // Then add scan history
//             String sql = "INSERT INTO scan_history (user_id, barcode, scan_time, scan_type, action_taken, allergen_detected) VALUES (1, '123456789', NOW(), 'BARCODE', 'PURCHASE', false)";
            
//             int result = jdbcTemplate.update(sql);
//             return "Successfully added test user and " + result + " scan history record(s)";
            
//         } catch (Exception e) {
//             return "Error adding scan data: " + e.getMessage();
//         }
//     }
// } 