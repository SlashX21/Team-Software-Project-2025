package org.user.pojo.DTO;

import org.user.enums.ScanType;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public class UserHistoryResponseDto {
    private String id;
    
    @JsonProperty("scanType")
    private ScanType scanType;
    
    @JsonProperty("createdAt")
    private String createdAt;
    
    @JsonProperty("productName")
    private String productName;
    
    @JsonProperty("productImage")
    private String productImage;
    
    private String barcode;
    
    @JsonProperty("healthScore")
    private Double healthScore;
    
    @JsonProperty("recommendationCount")
    private Integer recommendationCount;
    
    private SummaryDto summary;
    
    @JsonProperty("fullAnalysis")
    private FullAnalysisDto fullAnalysis;
    
    @JsonProperty("recommendations")
    private List<RecommendationDto> recommendations;
    
    @JsonProperty("nutritionData")
    private NutritionDataDto nutritionData;
    
    public static class SummaryDto {
        private Integer calories;
        private String sugar;
        private String status;
        
        public SummaryDto() {}
        
        public SummaryDto(Integer calories, String sugar, String status) {
            this.calories = calories;
            this.sugar = sugar;
            this.status = status;
        }
        
        public Integer getCalories() {
            return calories;
        }
        
        public void setCalories(Integer calories) {
            this.calories = calories;
        }
        
        public String getSugar() {
            return sugar;
        }
        
        public void setSugar(String sugar) {
            this.sugar = sugar;
        }
        
        public String getStatus() {
            return status;
        }
        
        public void setStatus(String status) {
            this.status = status;
        }
        
        @Override
        public String toString() {
            return "SummaryDto{" +
                    "calories=" + calories +
                    ", sugar='" + sugar + '\'' +
                    ", status='" + status + '\'' +
                    '}';
        }
    }
    
    public static class FullAnalysisDto {
        private List<String> ingredients;
        private List<String> allergens;
        
        @JsonProperty("nutrition_per_100g")
        private NutritionPer100gDto nutritionPer100g;
        
        public FullAnalysisDto() {}
        
        public FullAnalysisDto(List<String> ingredients, List<String> allergens, NutritionPer100gDto nutritionPer100g) {
            this.ingredients = ingredients;
            this.allergens = allergens;
            this.nutritionPer100g = nutritionPer100g;
        }
        
        public List<String> getIngredients() {
            return ingredients;
        }
        
        public void setIngredients(List<String> ingredients) {
            this.ingredients = ingredients;
        }
        
        public List<String> getAllergens() {
            return allergens;
        }
        
        public void setAllergens(List<String> allergens) {
            this.allergens = allergens;
        }
        
        public NutritionPer100gDto getNutritionPer100g() {
            return nutritionPer100g;
        }
        
        public void setNutritionPer100g(NutritionPer100gDto nutritionPer100g) {
            this.nutritionPer100g = nutritionPer100g;
        }
    }
    
    public static class NutritionPer100gDto {
        private Integer calories;
        private Double protein;
        private Double carbs;
        private Double fiber;
        private Double sugar;
        private Double fat;
        private Integer sodium;
        
        public NutritionPer100gDto() {}
        
        public NutritionPer100gDto(Integer calories, Double protein, Double carbs, Double fiber, 
                                   Double sugar, Double fat, Integer sodium) {
            this.calories = calories;
            this.protein = protein;
            this.carbs = carbs;
            this.fiber = fiber;
            this.sugar = sugar;
            this.fat = fat;
            this.sodium = sodium;
        }
        
        public Integer getCalories() {
            return calories;
        }
        
        public void setCalories(Integer calories) {
            this.calories = calories;
        }
        
        public Double getProtein() {
            return protein;
        }
        
        public void setProtein(Double protein) {
            this.protein = protein;
        }
        
        public Double getCarbs() {
            return carbs;
        }
        
        public void setCarbs(Double carbs) {
            this.carbs = carbs;
        }
        
        public Double getFiber() {
            return fiber;
        }
        
        public void setFiber(Double fiber) {
            this.fiber = fiber;
        }
        
        public Double getSugar() {
            return sugar;
        }
        
        public void setSugar(Double sugar) {
            this.sugar = sugar;
        }
        
        public Double getFat() {
            return fat;
        }
        
        public void setFat(Double fat) {
            this.fat = fat;
        }
        
        public Integer getSodium() {
            return sodium;
        }
        
        public void setSodium(Integer sodium) {
            this.sodium = sodium;
        }
    }
    
    public static class RecommendationDto {
        private String type;
        private String title;
        private String description;
        
        public RecommendationDto() {}
        
        public RecommendationDto(String type, String title, String description) {
            this.type = type;
            this.title = title;
            this.description = description;
        }
        
        public String getType() {
            return type;
        }
        
        public void setType(String type) {
            this.type = type;
        }
        
        public String getTitle() {
            return title;
        }
        
        public void setTitle(String title) {
            this.title = title;
        }
        
        public String getDescription() {
            return description;
        }
        
        public void setDescription(String description) {
            this.description = description;
        }
    }
    
    public static class NutritionDataDto {
        @JsonProperty("health_score")
        private Double healthScore;
        
        private String category;
        
        @JsonProperty("dietary_info")
        private List<String> dietaryInfo;
        
        private List<String> warnings;
        
        public NutritionDataDto() {}
        
        public NutritionDataDto(Double healthScore, String category, List<String> dietaryInfo, List<String> warnings) {
            this.healthScore = healthScore;
            this.category = category;
            this.dietaryInfo = dietaryInfo;
            this.warnings = warnings;
        }
        
        public Double getHealthScore() {
            return healthScore;
        }
        
        public void setHealthScore(Double healthScore) {
            this.healthScore = healthScore;
        }
        
        public String getCategory() {
            return category;
        }
        
        public void setCategory(String category) {
            this.category = category;
        }
        
        public List<String> getDietaryInfo() {
            return dietaryInfo;
        }
        
        public void setDietaryInfo(List<String> dietaryInfo) {
            this.dietaryInfo = dietaryInfo;
        }
        
        public List<String> getWarnings() {
            return warnings;
        }
        
        public void setWarnings(List<String> warnings) {
            this.warnings = warnings;
        }
    }
    
    @Override
    public String toString() {
        return "UserHistoryResponseDto{" +
                "id='" + id + '\'' +
                ", scanType=" + scanType +
                ", createdAt='" + createdAt + '\'' +
                ", productName='" + productName + '\'' +
                ", productImage='" + productImage + '\'' +
                ", barcode='" + barcode + '\'' +
                ", healthScore=" + healthScore +
                ", recommendationCount=" + recommendationCount +
                ", summary=" + summary +
                '}';
        // return "UserHistoryResponseDto{" +
        //         "id='" + id + '\'' +
        //         ", scanType=" + scanType +
        //         ", createdAt='" + createdAt + '\'' +
        //         ", productName='" + productName + '\'' +
        //         ", productImage='" + productImage + '\'' +
        //         ", barcode='" + barcode + '\'' +
        //         ", healthScore=" + healthScore +
        //         ", recommendationCount=" + recommendationCount +
        //         ", summary=" + summary +
        //         ", fullAnalysis=" + fullAnalysis +
        //         ", recommendations=" + recommendations +
        //         ", nutritionData=" + nutritionData +
        //         '}';
    }

    /**
     * @return String return the id
     */
    public String getId() {
        return id;
    }

    /**
     * @param id the id to set
     */
    public void setId(String id) {
        this.id = id;
    }

    /**
     * @return ScanType return the scanType
     */
    public ScanType getScanType() {
        return scanType;
    }

    /**
     * @param scanType the scanType to set
     */
    public void setScanType(ScanType scanType) {
        this.scanType = scanType;
    }

    /**
     * @return String return the createdAt
     */
    public String getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt the createdAt to set
     */
    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    /**
     * @return String return the productName
     */
    public String getProductName() {
        return productName;
    }

    /**
     * @param productName the productName to set
     */
    public void setProductName(String productName) {
        this.productName = productName;
    }

    /**
     * @return String return the productImage
     */
    public String getProductImage() {
        return productImage;
    }

    /**
     * @param productImage the productImage to set
     */
    public void setProductImage(String productImage) {
        this.productImage = productImage;
    }

    /**
     * @return String return the barcode
     */
    public String getBarcode() {
        return barcode;
    }

    /**
     * @param barcode the barcode to set
     */
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }

    /**
     * @return Double return the healthScore
     */
    public Double getHealthScore() {
        return healthScore;
    }

    /**
     * @param healthScore the healthScore to set
     */
    public void setHealthScore(Double healthScore) {
        this.healthScore = healthScore;
    }

    /**
     * @return Integer return the recommendationCount
     */
    public Integer getRecommendationCount() {
        return recommendationCount;
    }

    /**
     * @param recommendationCount the recommendationCount to set
     */
    public void setRecommendationCount(Integer recommendationCount) {
        this.recommendationCount = recommendationCount;
    }

    /**
     * @return SummaryDto return the summary
     */
    public SummaryDto getSummary() {
        return summary;
    }

    /**
     * @param summary the summary to set
     */
    public void setSummary(SummaryDto summary) {
        this.summary = summary;
    }
    
    public FullAnalysisDto getFullAnalysis() {
        return fullAnalysis;
    }
    
    public void setFullAnalysis(FullAnalysisDto fullAnalysis) {
        this.fullAnalysis = fullAnalysis;
    }
    
    public List<RecommendationDto> getRecommendations() {
        return recommendations;
    }
    
    public void setRecommendations(List<RecommendationDto> recommendations) {
        this.recommendations = recommendations;
    }
    
    public NutritionDataDto getNutritionData() {
        return nutritionData;
    }
    
    public void setNutritionData(NutritionDataDto nutritionData) {
        this.nutritionData = nutritionData;
    }
} 