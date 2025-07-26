package org.user.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.jdbc.core.JdbcTemplate;
import org.user.enums.ScanType;
import org.user.enums.ActionTaken;
import org.user.pojo.DTO.UserHistoryResponseDto;
import org.user.pojo.DTO.UserHistoryListDto;
import org.user.pojo.ScanHistory;
import org.user.repository.ScanHistoryRepository;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class UserHistoryService implements IUserHistoryService {

    @Autowired
    private ScanHistoryRepository scanHistoryRepository;
    
    // use JdbcTemplate to query product table directly
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public Page<UserHistoryListDto> getUserHistory(Integer userId, int page, int limit, 
                                                       String search, String type, String range) {
        // Note: Spring Data JPA's page starts from 0
        Pageable pageable = PageRequest.of(page - 1, limit);
        
        // construct query parameters
        String scanType = mapTypeToScanType(type);
        String[] dateRange = calculateDateRange(range);
        String startDate = dateRange[0];
        String endDate = dateRange[1];
        
        // execute query
        Page<ScanHistory> scanHistoryPage = scanHistoryRepository.findUserHistoryWithFilters(
                userId, search, scanType, startDate, endDate, pageable);
        
        // System.out.println("scanHistoryPage content: " + scanHistoryPage.getContent());
        // convert response DTO
        List<UserHistoryListDto> responseDtos = scanHistoryPage.getContent()
                .stream()
                .map(this::convertToListDto)
                .collect(Collectors.toList());
        
        return new PageImpl<>(responseDtos, pageable, scanHistoryPage.getTotalElements());
    }
    
    @Override
    public UserHistoryResponseDto getUserHistoryById(Integer userId, String historyId) {
        // analysis historyId to obtain scanId
        Integer scanId;
        try {
            if (historyId.startsWith("hist_")) {
                scanId = Integer.parseInt(historyId.substring(5));
            } else {
                scanId = Integer.parseInt(historyId);
            }
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid history ID format: " + historyId);
        }
        
        // 查询扫描历史记录
        ScanHistory scanHistory = scanHistoryRepository.findById(scanId)
                .orElseThrow(() -> new IllegalArgumentException("History record not found for ID: " + historyId));
        
        // 验证记录是否属于指定用户
        if (!scanHistory.getUserId().equals(userId)) {
            throw new IllegalArgumentException("History record does not belong to user: " + userId);
        }
        
        // 转换为详细的响应DTO（包含完整分析数据）
        return convertToDetailedResponseDto(scanHistory);
    }
    
    @Override
    public void deleteUserHistoryById(Integer userId, String historyId) {
        Integer scanId;
        // analysis historyId to obtain scanId
        try{
            if (historyId.startsWith("hist_")){
                scanId = Integer.parseInt(historyId.substring(5));
            } else {
                scanId = Integer.parseInt(historyId);
            }
        }
        catch(Exception e){
            throw new IllegalArgumentException("Invalid history ID format: "+historyId);
        }
        scanHistoryRepository.deleteById(scanId);
    }
    
    @Override
    public Map<String, Object> getUserHistoryStats(Integer userId, String period) {
        Map<String, Object> stats = new HashMap<>();
        
        // calculate date range
        String[] dateRange = calculateDateRange(period);
        String startDate = dateRange[0];
        String endDate = dateRange[1];
        
        // obtain scan history list with specific date range
        List<ScanHistory> scanHistoryList = scanHistoryRepository.findByUserIdAndDateRange(userId, startDate, endDate);
        
        // statistic different types of scans
        int barcodeScans = 0;
        int receiptScans = 0;
        double totalHealthScore = 0.0;
        int healthScoreCount = 0;
        Map<String, Integer> scansByDate = new HashMap<>();
        Map<String, Integer> categoryCount = new HashMap<>();
        
        for (ScanHistory scanHistory : scanHistoryList) {
            // statistics scan type
            if (scanHistory.getScanType() == ScanType.BARCODE) {
                barcodeScans++;
            } else if (scanHistory.getScanType() == ScanType.RECEIPT) {
                receiptScans++;
            }
            
            // statistics daily scans
            String scanDate = extractDateFromScanTime(scanHistory.getScanTime());
            scansByDate.put(scanDate, scansByDate.getOrDefault(scanDate, 0) + 1);
            
            // calculate health score
            ProductInfo productInfo = getProductInfoByBarcode(scanHistory.getBarcode());
            if (productInfo != null) {
                Double healthScore = calculateHealthScoreFromProductInfo(productInfo);
                if (healthScore != null) {
                    totalHealthScore += healthScore;
                    healthScoreCount++;
                }
                
                // statistics product category
                String category = determineProductCategory(productInfo);
                if (category != null && !category.isEmpty()) {
                    categoryCount.put(category, categoryCount.getOrDefault(category, 0) + 1);
                }
            }
        }
        
        // calculate average health score
        Double averageHealthScore = healthScoreCount > 0 ? totalHealthScore / healthScoreCount : 0.0;
        
        // obtain top category
        List<String> topCategories = categoryCount.entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                .limit(4)
                .map(Map.Entry::getKey)
                .collect(Collectors.toList());
        
        // build return data
        stats.put("totalScans", scanHistoryList.size());
        stats.put("barcodeScans", barcodeScans);
        stats.put("receiptScans", receiptScans);
        // keep 1 decimal place
        stats.put("averageHealthScore", Math.round(averageHealthScore * 10.0) / 10.0); 
        stats.put("scansByDate", scansByDate);
        stats.put("topCategories", topCategories);
        
        return stats;
    }

    /**
     * convert ScanHistory to UserHistoryListDto for list interface
     */
    private UserHistoryListDto convertToListDto(ScanHistory scanHistory) {
        UserHistoryListDto dto = new UserHistoryListDto();
        
        // basic information
        dto.setId("hist_" + scanHistory.getScanId());
        dto.setScanType(scanHistory.getScanType());
        dto.setCreatedAt(scanHistory.getScanTime());
        dto.setBarcode(scanHistory.getBarcode());
        
        // add allergen detected and user action information
        dto.setAllergenDetected(scanHistory.isAllergenDetected());
        dto.setActionTaken(scanHistory.getActionTaken());
        
        // query product table to obtain product information directly
        ProductInfo productInfo = getProductInfoByBarcode(scanHistory.getBarcode());
        
        if (productInfo != null) {
            // set real product information
            dto.setProductName(productInfo.productName);
            dto.setHealthScore(calculateHealthScoreFromProductInfo(productInfo));
            
            // create summary based on actual nutrition data
            Integer calories = productInfo.energyKcal100g != null ? 
                Math.round(productInfo.energyKcal100g) : null;
            String sugar = productInfo.sugars100g != null ? 
                String.format("%.1fg", productInfo.sugars100g) : "N/A";
            String healthLevel = determineHealthLevelFromProductInfo(productInfo);
            
            dto.setSummary(new UserHistoryListDto.SummaryDto(calories, sugar, healthLevel));
        } else {
            // if product is not found, use default value
            dto.setProductName("Unknown Product" + scanHistory.getBarcode());
            dto.setHealthScore(null);
            dto.setSummary(new UserHistoryListDto.SummaryDto(null, "N/A", "unknown"));
        }
        
        // set product image (placeholder for now, could be enhanced later)
        dto.setProductImage("https://via.placeholder.com/150x150?text=Product");
        
        // extract recommendation count from recommendation response
        dto.setRecommendationCount(extractRecommendationCount(scanHistory.getRecommendationResponse()));
        
        return dto;
    }

    /**
     * convert ScanHistory to UserHistoryResponseDto
     * query product tables directly
     */
    private UserHistoryResponseDto convertToResponseDto(ScanHistory scanHistory) {
        UserHistoryResponseDto dto = new UserHistoryResponseDto();
        
        // basic information
        dto.setId("hist_" + scanHistory.getScanId());
        dto.setScanType(scanHistory.getScanType());
        dto.setCreatedAt(scanHistory.getScanTime());
        dto.setBarcode(scanHistory.getBarcode());
        
        // query product table to obtain product information directly
        ProductInfo productInfo = getProductInfoByBarcode(scanHistory.getBarcode());
        
        if (productInfo != null) {
            // set real product information
            dto.setProductName(productInfo.productName);
            dto.setHealthScore(calculateHealthScoreFromProductInfo(productInfo));
            
            // create summary based on actual nutrition data
            Integer calories = productInfo.energyKcal100g != null ? 
                Math.round(productInfo.energyKcal100g) : null;
            String sugar = productInfo.sugars100g != null ? 
                String.format("%.1fg", productInfo.sugars100g) : "N/A";
            String healthLevel = determineHealthLevelFromProductInfo(productInfo);
            
            dto.setSummary(new UserHistoryResponseDto.SummaryDto(calories, sugar, healthLevel));
        } else {
            // if product is not found, use default value
            dto.setProductName("Unknown Product" + scanHistory.getBarcode());
            dto.setHealthScore(null);
            dto.setSummary(new UserHistoryResponseDto.SummaryDto(null, "N/A", "unknown"));
        }
        
        // set product image (placeholder for now, could be enhanced later)
        dto.setProductImage("https://via.placeholder.com/150x150?text=Product");
        
        // extract recommendation count from recommendation response
        dto.setRecommendationCount(extractRecommendationCount(scanHistory.getRecommendationResponse()));
        
        return dto;
    }
    
    /**
     * convert ScanHistory to detailed UserHistoryResponseDto with full analysis
     */
    private UserHistoryResponseDto convertToDetailedResponseDto(ScanHistory scanHistory) {
        UserHistoryResponseDto dto = new UserHistoryResponseDto();
        
        // basic information
        dto.setId("hist_" + scanHistory.getScanId());
        dto.setScanType(scanHistory.getScanType());
        dto.setCreatedAt(scanHistory.getScanTime());
        dto.setBarcode(scanHistory.getBarcode());
        
        // query product information
        ProductInfo productInfo = getProductInfoByBarcode(scanHistory.getBarcode());
        
        if (productInfo != null) {
            dto.setProductName(productInfo.productName);
            dto.setHealthScore(calculateHealthScoreFromProductInfo(productInfo));
            
            // create basic summary
            Integer calories = productInfo.energyKcal100g != null ? 
                Math.round(productInfo.energyKcal100g) : null;
            String sugar = productInfo.sugars100g != null ? 
                String.format("%.1fg", productInfo.sugars100g) : "N/A";
            String healthLevel = determineHealthLevelFromProductInfo(productInfo);
            
            dto.setSummary(new UserHistoryResponseDto.SummaryDto(calories, sugar, healthLevel));
            
            // create full analysis data
            dto.setFullAnalysis(createFullAnalysis(scanHistory.getBarcode(), productInfo));
            
            // create nutrition data
            dto.setNutritionData(createNutritionData(productInfo));
        } else {
            dto.setProductName("Unknown Product " + scanHistory.getBarcode());
            dto.setHealthScore(null);
            dto.setSummary(new UserHistoryResponseDto.SummaryDto(null, "N/A", "unknown"));
            
            // create default data for unknown product
            dto.setFullAnalysis(createDefaultFullAnalysis());
            dto.setNutritionData(createDefaultNutritionData());
        }
        
        // set product image
        dto.setProductImage("https://via.placeholder.com/150x150?text=Product");
        
        // extract recommendations
        List<UserHistoryResponseDto.RecommendationDto> recommendations = 
            extractRecommendations(scanHistory.getRecommendationResponse());
        dto.setRecommendations(recommendations);
        dto.setRecommendationCount(recommendations.size());
        
        return dto;
    }
    
    /**
     * create full analysis data
     */
    private UserHistoryResponseDto.FullAnalysisDto createFullAnalysis(String barcode, ProductInfo productInfo) {
        List<String> ingredients = parseIngredients(productInfo.ingredients);
        List<String> allergens = parseAllergens(productInfo.allergens);
        
        UserHistoryResponseDto.NutritionPer100gDto nutrition = new UserHistoryResponseDto.NutritionPer100gDto(
            productInfo.energyKcal100g != null ? Math.round(productInfo.energyKcal100g) : null,
            productInfo.proteins100g != null ? productInfo.proteins100g.doubleValue() : null,
            productInfo.carbohydrates100g != null ? productInfo.carbohydrates100g.doubleValue() : null,
            null, // fiber - 需要在数据库中添加fiber字段
            productInfo.sugars100g != null ? productInfo.sugars100g.doubleValue() : null,
            productInfo.fat100g != null ? productInfo.fat100g.doubleValue() : null,
            null  // sodium - 需要在数据库中添加sodium字段
        );
        
        return new UserHistoryResponseDto.FullAnalysisDto(ingredients, allergens, nutrition);
    }
    
    /**
     * create default full analysis data (for unknown product)
     */
    private UserHistoryResponseDto.FullAnalysisDto createDefaultFullAnalysis() {
        List<String> ingredients = List.of("Information not available");
        List<String> allergens = List.of();
        
        UserHistoryResponseDto.NutritionPer100gDto nutrition = new UserHistoryResponseDto.NutritionPer100gDto(
            null, null, null, null, null, null, null);
        
        return new UserHistoryResponseDto.FullAnalysisDto(ingredients, allergens, nutrition);
    }
    
    /**
     * create nutrition data
     */
    private UserHistoryResponseDto.NutritionDataDto createNutritionData(ProductInfo productInfo) {
        Double healthScore = calculateHealthScoreFromProductInfo(productInfo);
        String category = determineProductCategory(productInfo);
        List<String> dietaryInfo = determineDietaryInfo(productInfo);
        List<String> warnings = determineWarnings(productInfo);
        
        return new UserHistoryResponseDto.NutritionDataDto(healthScore, category, dietaryInfo, warnings);
    }
    
    /**
     * create default nutrition data (for unknown product)
     */
    private UserHistoryResponseDto.NutritionDataDto createDefaultNutritionData() {
        return new UserHistoryResponseDto.NutritionDataDto(null, "Unknown", List.of(), List.of());
    }
    
    /**
     * analysis ingredients string to ingredients list
     */
    private List<String> parseIngredients(String ingredientsString) {
        if (ingredientsString == null || ingredientsString.trim().isEmpty()) {
            return List.of("Information not available");
        }
        
        // assume ingredients are separated by commas
        return Arrays.stream(ingredientsString.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }
    
    /**
     * analysis allergens string to allergens list
     */
    private List<String> parseAllergens(String allergensString) {
        if (allergensString == null || allergensString.trim().isEmpty()) {
            return List.of();
        }
        
        // assume allergens are separated by commas
        return Arrays.stream(allergensString.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }
    
    /**
     * get product ingredients list (simulated implementation, now replaced by parseIngredients)
     */
    private List<String> getProductIngredients(String barcode) {
        // 这里可以调用产品服务API或从数据库查询
        // 目前返回示例数据
        return List.of("Organic wheat flour", "Water", "Sea salt", "Yeast");
    }
    
    /**
     * get product allergens list (simulated implementation, now replaced by parseAllergens)
     */
    private List<String> getProductAllergens(String barcode) {
        // 这里可以调用过敏原服务API
        // 目前返回示例数据
        return List.of("Gluten");
    }
    
    /**
     * determine product category
     */
    private String determineProductCategory(ProductInfo productInfo) {
        // use category information from database first
        if (productInfo.category != null && !productInfo.category.trim().isEmpty()) {
            return productInfo.category;
        }
        // if no category information in database, return default value
        return "Unknown";
    }
    
    /**
     * determine dietary information
     */
    private List<String> determineDietaryInfo(ProductInfo productInfo) {
        List<String> dietaryInfo = new ArrayList<>();
        
        // based on nutrition information to determine dietary information
        if (productInfo.proteins100g != null && productInfo.proteins100g > 10) {
            dietaryInfo.add("High Protein");
        }
        
        // TODO: can add more judgment logic        
        dietaryInfo.add("Vegetarian");
        
        return dietaryInfo;
    }
    
    /**
     * determine warnings
     */
    private List<String> determineWarnings(ProductInfo productInfo) {
        List<String> warnings = new ArrayList<>();
        
        // based on nutrition information to determine warnings
        if (productInfo.sugars100g != null && productInfo.sugars100g > 15) {
            warnings.add("High Sugar Content");
        }
        
        if (productInfo.fat100g != null && productInfo.fat100g > 20) {
            warnings.add("High Fat Content");
        }
        
        return warnings;
    }
    
    /**
     * extract recommendations from recommendation response
     */
    private List<UserHistoryResponseDto.RecommendationDto> extractRecommendations(String recommendationResponse) {
        if (recommendationResponse == null || recommendationResponse.isEmpty()) {
            // return default recommendations
            return List.of(new UserHistoryResponseDto.RecommendationDto(
                "alternative", 
                "Try healthier alternatives", 
                "Consider products with lower sugar and fat content."
            ));
        }
        
        try {
            // System.out.println("recommendationResponse: " + recommendationResponse);
            JsonNode jsonNode = objectMapper.readTree(recommendationResponse);
            // System.out.println("jsonNode: " + jsonNode);
            JsonNode recommendationsNode = jsonNode.path("recommendations");
            
            List<UserHistoryResponseDto.RecommendationDto> recommendations = new ArrayList<>();
            
            if (recommendationsNode.isArray()) {
                for (JsonNode recNode : recommendationsNode) {
                    // System.out.println("recNode: " + recNode);
                    String type = recNode.path("type").asText("general");
                    String title = recNode.path("title").asText("Recommendation");
                    String description = recNode.path("description").asText("");
                    
                    recommendations.add(new UserHistoryResponseDto.RecommendationDto(type, title, description));
                }
            }
            
            return recommendations.isEmpty() ? 
                List.of(new UserHistoryResponseDto.RecommendationDto(
                    "general", 
                    "No specific recommendations", 
                    "This product appears to meet general nutritional guidelines."
                )) : recommendations;
                
        } catch (JsonProcessingException e) {
            // return default recommendations when parsing fails
            return List.of(new UserHistoryResponseDto.RecommendationDto(
                "error", 
                "Analysis unavailable", 
                "Unable to provide detailed recommendations at this time."
            ));
        }
    }
    
    /**
     * simple ProductInfo class, used to store product information from database
     */
    private static class ProductInfo {
        String barcode;
        String productName;
        String brand;
        String ingredients;
        String allergens;
        Float energy100g;
        Float energyKcal100g;
        Float fat100g;
        Float saturatedFat100g;
        Float carbohydrates100g;
        Float sugars100g;
        Float proteins100g;
        String servingSize;
        String category;

        public ProductInfo(String barcode, String productName, String brand, String ingredients, 
                           String allergens, Float energy100g, Float energyKcal100g, Float fat100g, 
                           Float saturatedFat100g, Float carbohydrates100g, Float sugars100g, 
                           Float proteins100g, String servingSize, String category) {
            this.barcode = barcode;
            this.productName = productName;
            this.brand = brand;
            this.ingredients = ingredients;
            this.allergens = allergens;
            this.energy100g = energy100g;
            this.energyKcal100g = energyKcal100g;
            this.fat100g = fat100g;
            this.saturatedFat100g = saturatedFat100g;
            this.carbohydrates100g = carbohydrates100g;
            this.sugars100g = sugars100g;
            this.proteins100g = proteins100g;
            this.servingSize = servingSize;
            this.category = category;
        }
    }
    
    /**
     * query product table directly by barcode
     */
    private ProductInfo getProductInfoByBarcode(String barcode) {
        if (barcode == null || barcode.isEmpty()) {
            return null;
        }
        
        try {
            String sql = "SELECT * FROM product WHERE barcode = ?";
            
            return jdbcTemplate.queryForObject(sql, 
                (rs, rowNum) -> new ProductInfo(
                    rs.getString("barcode"),
                    rs.getString("name"),
                    rs.getString("brand"),
                    rs.getString("ingredients"),
                    rs.getString("allergens"),
                    rs.getObject("energy_100g", Float.class),
                    rs.getObject("energy_kcal_100g", Float.class),
                    rs.getObject("fat_100g", Float.class),
                    rs.getObject("saturated_fat_100g", Float.class),
                    rs.getObject("carbohydrates_100g", Float.class),
                    rs.getObject("sugars_100g", Float.class),
                    rs.getObject("proteins_100g", Float.class),
                    rs.getString("serving_size"),
                    rs.getString("category")
                ), 
                barcode);
        } catch (Exception e) {
            // if query fails or product is not found, return null
            System.out.println("No product found for barcode: " + barcode);
            return null;
        }
    }
    
    /**
     * calculate health score based on product information
     * 
     * In a real project, we can call the Product service via REST to get product information and calculate the score
     */
    private Double calculateHealthScoreFromProductInfo(ProductInfo productInfo) {
        if (productInfo == null) return null;
        
        double score = 100.0; // base score
        
        // adjust score based on nutrition information
        if (productInfo.sugars100g != null) {
            // sugar content adjustment
            if (productInfo.sugars100g > 20) score -= 20;
            else if (productInfo.sugars100g > 10) score -= 10;
        }
        
        if (productInfo.fat100g != null) {
            // fat content adjustment
            if (productInfo.fat100g > 30) score -= 15;
            else if (productInfo.fat100g > 15) score -= 8;
        }
        
        if (productInfo.proteins100g != null) {
            // protein content adjustment
            if (productInfo.proteins100g > 20) score += 10;
            else if (productInfo.proteins100g > 10) score += 5;
        }
        
        // ensure score is within reasonable range
        return Math.max(0, Math.min(100, score));
    }
    
    /**
     * determine health level based on product information
     */
    private String determineHealthLevelFromProductInfo(ProductInfo productInfo) {
        Double healthScore = calculateHealthScoreFromProductInfo(productInfo);
        if (healthScore == null) return "unknown";
        
        if (healthScore >= 80) return "healthy";
        else if (healthScore >= 60) return "moderate";
        else return "unhealthy";
    }
    
    /**
     * map API type parameter to database ScanType enum
     */
    private String mapTypeToScanType(String type) {
        if (type == null || type.isEmpty()) {
            return null;
        }
        
        switch (type.toLowerCase()) {
            case "barcode":
                return "BARCODE";
            case "receipt":
                return "RECEIPT";
            default:
                return null;
        }
    }
    
    /**
     * calculate start and end date based on time range
     */
    private String[] calculateDateRange(String range) {
        if (range == null || range.isEmpty()) {
            return new String[]{null, null};
        }
        
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startDate;
        
        switch (range.toLowerCase()) {
            case "week":
                startDate = now.minusDays(7);
                break;
            case "month":
                startDate = now.minusDays(30);
                break;
            case "year":
                startDate = now.minusDays(365);
                break;
            default:
                return new String[]{null, null};
        }
        
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        return new String[]{
                startDate.format(formatter),
                now.format(formatter)
        };
    }
    
    /**
     * calculate product health score(simplified version)
     * 
     * In a real project, we can call the Product service via REST to get product information and calculate the score
     */
    private Double calculateHealthScore(String barcode) {
        // simplified implementation: simulate health score calculation based on barcode
        return 85.0 + (barcode.hashCode() % 15);
    }
    public String getBrandFromBarcode(String barcode) {
        ProductInfo productInfo = getProductInfoByBarcode(barcode);
        if (productInfo != null) {
            return productInfo.brand;
        }
        return null;
    }

    @Override
    public Integer saveScanHistory(Integer userId, String barcode, String scanTime, String location, 
                                  Boolean allergenDetected, String actionTaken) {
        // create scan history entity
        ScanHistory scanHistory = new ScanHistory();
        scanHistory.setUserId(userId);
        scanHistory.setBarcode(barcode);
        scanHistory.setScanTime(convertIsoToDateTime(scanTime));
        scanHistory.setLocation(location);
        scanHistory.setAllergenDetected(allergenDetected != null ? allergenDetected : false);
        
        // convert actionTaken string to enum
        ActionTaken actionTakenEnum;
        try {
            if (actionTaken == null || actionTaken.isEmpty()) {
                actionTakenEnum = ActionTaken.UNKNOWN;
            } else {
                // map common action values to enum values
                switch (actionTaken.toLowerCase()) {
                    case "avoided":
                        actionTakenEnum = ActionTaken.AVOIDED;
                        break;
                    case "no_action":
                        actionTakenEnum = ActionTaken.NO_ACTION;
                        break;
                    case "purchased":
                        actionTakenEnum = ActionTaken.PURCHASED;
                        break;
                    default:
                        actionTakenEnum = ActionTaken.UNKNOWN;
                        break;
                }
            }
        } catch (Exception e) {
            actionTakenEnum = ActionTaken.UNKNOWN;
        }
        scanHistory.setActionTaken(actionTakenEnum);
        
        // set scan type as BARCODE by default
        scanHistory.setScanType(ScanType.BARCODE);
        
        // set scan result as empty JSON for now
        scanHistory.setScanResult("{}");
        
        // save to database
        ScanHistory savedScanHistory = scanHistoryRepository.save(scanHistory);
        
        return savedScanHistory.getScanId();
    }
    /**
     * convert datetime string to ISO 8601 format
     */
    private String convertToIsoDateTime(String dateTimeStr) {
        if (dateTimeStr == null || dateTimeStr.isEmpty()) {
            return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        }
        
        try {
            // assume input format is "yyyy-MM-dd HH:mm:ss"
            LocalDateTime dateTime = LocalDateTime.parse(dateTimeStr, DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            return dateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        } catch (Exception e) {
            // if parsing fails, return current time
            return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        }
    }
    
    /**
     * convert ISO 8601 format to MySQL DATETIME format
     */
    private String convertIsoToDateTime(String isoDateTime) {
        try {
            // try to parse ISO 8601 format (e.g. 2024-01-15T16:30:00Z)
            ZonedDateTime zonedDateTime = ZonedDateTime.parse(isoDateTime);
            LocalDateTime localDateTime = zonedDateTime.toLocalDateTime();
            return localDateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        } catch (DateTimeParseException e) {
            try {
                // try to parse simple ISO format (e.g. 2024-01-15T16:30:00)
                LocalDateTime localDateTime = LocalDateTime.parse(isoDateTime);
                return localDateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            } catch (DateTimeParseException e2) {
                // if both parsing fail, return current time
                return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            }
        }
    }


    /**
     * create nutrition summary(simplified version)
     * 
     * In a real project, we can call the Product service via REST to get product information and create the summary
     */
    private UserHistoryResponseDto.SummaryDto createNutritionSummary(String barcode) {
        // simplified implementation: simulate nutrition data
        int calories = 200 + (barcode.hashCode() % 100);
        String sugar = (barcode.hashCode() % 20) + "g";
        String status = "healthy";
        
        return new UserHistoryResponseDto.SummaryDto(calories, sugar, status);
    }
    
    /**
     * extract recommendation count from recommendation response
     * 
     * In a real project, we can call the Recommendation service via REST to get recommendation information
     */
    private Integer extractRecommendationCount(String recommendationResponse) {
        if (recommendationResponse == null || recommendationResponse.isEmpty()) {
            return 0;
        }
        
        try {
            JsonNode jsonNode = objectMapper.readTree(recommendationResponse);
            JsonNode recommendationsNode = jsonNode.path("recommendations");
            
            if (recommendationsNode.isArray()) {
                return recommendationsNode.size();
            }
            
            return 0;
        } catch (JsonProcessingException e) {
            return 0;
        }
    }
    
    /**
     * extract date from scan time string
     * 
     * @param scanTime scan time string (format: "yyyy-MM-dd HH:mm:ss")
     * @return date string (format: "yyyy-MM-dd")
     */
    private String extractDateFromScanTime(String scanTime) {
        if (scanTime == null || scanTime.isEmpty()) {
            return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        }
        
        try {
            // try to parse the full date time format
            if (scanTime.contains(" ")) {
                return scanTime.split(" ")[0];
            }
            // if already in date format, return directly
            return scanTime;
        } catch (Exception e) {
            // if parse failed, return current date
            return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        }
    }
} 