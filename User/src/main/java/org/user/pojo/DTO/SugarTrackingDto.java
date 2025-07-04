package org.user.pojo.DTO;

import java.util.List;

public class SugarTrackingDto {
    private Double currentIntakeMg;
    private Double dailyGoalMg;
    private Double progressPercentage;
    private String status;
    private String date;
    private List<TopContributorDto> topContributors;
    
    // inner class: top contributors
    public static class TopContributorDto {
        private String id;
        private String foodName;
        private Double sugarAmountMg;
        private Double quantity;
        private String consumedAt;
        private String productBarcode;
        
        public TopContributorDto() {}
        
        public TopContributorDto(String id, String foodName, Double sugarAmountMg, Double quantity, String consumedAt, String productBarcode) {
            this.id = id;
            this.foodName = foodName;
            this.sugarAmountMg = sugarAmountMg;
            this.quantity = quantity;
            this.consumedAt = consumedAt;
            this.productBarcode = productBarcode;
        }
        
        // Getters and Setters
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        
        public String getFoodName() { return foodName; }
        public void setFoodName(String foodName) { this.foodName = foodName; }
        
        public Double getSugarAmountMg() { return sugarAmountMg; }
        public void setSugarAmountMg(Double sugarAmountMg) { this.sugarAmountMg = sugarAmountMg; }
        
        public Double getQuantity() { return quantity; }
        public void setQuantity(Double quantity) { this.quantity = quantity; }
        
        public String getConsumedAt() { return consumedAt; }
        public void setConsumedAt(String consumedAt) { this.consumedAt = consumedAt; }
        
        public String getProductBarcode() { return productBarcode; }
        public void setProductBarcode(String productBarcode) { this.productBarcode = productBarcode; }
    }
    
    // constructor
    public SugarTrackingDto() {}
    
    public SugarTrackingDto(Double currentIntakeMg, Double dailyGoalMg, Double progressPercentage, 
                           String status, String date, List<TopContributorDto> topContributors) {
        this.currentIntakeMg = currentIntakeMg;
        this.dailyGoalMg = dailyGoalMg;
        this.progressPercentage = progressPercentage;
        this.status = status;
        this.date = date;
        this.topContributors = topContributors;
    }
    
    // Getters and Setters
    public Double getCurrentIntakeMg() { return currentIntakeMg; }
    public void setCurrentIntakeMg(Double currentIntakeMg) { this.currentIntakeMg = currentIntakeMg; }
    
    public Double getDailyGoalMg() { return dailyGoalMg; }
    public void setDailyGoalMg(Double dailyGoalMg) { this.dailyGoalMg = dailyGoalMg; }
    
    public Double getProgressPercentage() { return progressPercentage; }
    public void setProgressPercentage(Double progressPercentage) { this.progressPercentage = progressPercentage; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }
    
    public List<TopContributorDto> getTopContributors() { return topContributors; }
    public void setTopContributors(List<TopContributorDto> topContributors) { this.topContributors = topContributors; }
    
    @Override
    public String toString() {
        return "SugarTrackingDto{" +
                "currentIntakeMg=" + currentIntakeMg +
                ", dailyGoalMg=" + dailyGoalMg +
                ", progressPercentage=" + progressPercentage +
                ", status='" + status + '\'' +
                ", date='" + date + '\'' +
                ", topContributors=" + topContributors +
                '}';
    }
} 