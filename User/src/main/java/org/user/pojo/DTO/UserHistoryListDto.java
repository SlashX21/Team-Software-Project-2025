package org.user.pojo.DTO;

import org.user.enums.ScanType;
import org.user.enums.ActionTaken;
import com.fasterxml.jackson.annotation.JsonProperty;

public class UserHistoryListDto {
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
    
    @JsonProperty("allergenDetected")
    private Boolean allergenDetected;
    
    @JsonProperty("actionTaken")
    private ActionTaken actionTaken;
    
    private SummaryDto summary;
    
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
    
    @Override
    public String toString() {
        return "UserHistoryListDto{" +
                "id='" + id + '\'' +
                ", scanType=" + scanType +
                ", createdAt='" + createdAt + '\'' +
                ", productName='" + productName + '\'' +
                ", productImage='" + productImage + '\'' +
                ", barcode='" + barcode + '\'' +
                ", healthScore=" + healthScore +
                ", recommendationCount=" + recommendationCount +
                ", allergenDetected=" + allergenDetected +
                ", actionTaken=" + actionTaken +
                ", summary=" + summary +
                '}';
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public ScanType getScanType() {
        return scanType;
    }

    public void setScanType(ScanType scanType) {
        this.scanType = scanType;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getProductImage() {
        return productImage;
    }

    public void setProductImage(String productImage) {
        this.productImage = productImage;
    }

    public String getBarcode() {
        return barcode;
    }

    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }

    public Double getHealthScore() {
        return healthScore;
    }

    public void setHealthScore(Double healthScore) {
        this.healthScore = healthScore;
    }

    public Integer getRecommendationCount() {
        return recommendationCount;
    }

    public void setRecommendationCount(Integer recommendationCount) {
        this.recommendationCount = recommendationCount;
    }

    public SummaryDto getSummary() {
        return summary;
    }

    public void setSummary(SummaryDto summary) {
        this.summary = summary;
    }

    public Boolean getAllergenDetected() {
        return allergenDetected;
    }

    public void setAllergenDetected(Boolean allergenDetected) {
        this.allergenDetected = allergenDetected;
    }

    public ActionTaken getActionTaken() {
        return actionTaken;
    }

    public void setActionTaken(ActionTaken actionTaken) {
        this.actionTaken = actionTaken;
    }
} 