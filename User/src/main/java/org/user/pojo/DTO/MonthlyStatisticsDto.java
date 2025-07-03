package org.user.pojo.DTO;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;

public class MonthlyStatisticsDto {
    private Integer statId;

    @NotNull(message = "user_id can not be null")
    private Integer userId;

    @NotNull(message = "year can not be null")
    @Min(value = 2020, message = "year must be greater than 2020")
    @Max(value = 2100, message = "year must be less than 2100")
    private Integer year;

    @NotNull(message = "month can not be null")
    @Min(value = 1, message = "month must be between 1 and 12")
    @Max(value = 12, message = "month must be between 1 and 12")
    private Integer month;

    private Integer receiptUploads;
    
    private Integer totalProducts;

    private Double totalSpent;

    // JSON string containing category breakdown data
    private String categoryBreakdown;
    
    // JSON string containing popular products data
    private String popularProducts; 

    // JSON string containing nutrition breakdown data
    private String nutritionBreakdown;

    private String calculatedAt;

    private String updateAt;

    @Override
    public String toString() {
        return "MonthlyStatisticsDto{" +
                "statId=" + statId +
                ", userId=" + userId +
                ", year=" + year +
                ", month=" + month +
                ", receiptUploads=" + receiptUploads +
                ", totalProducts=" + totalProducts +
                ", totalSpent=" + totalSpent +
                ", categoryBreakdown='" + categoryBreakdown + '\'' +
                ", popularProducts='" + popularProducts + '\'' +
                ", nutritionBreakdown='" + nutritionBreakdown + '\'' +
                ", calculatedAt='" + calculatedAt + '\'' +
                ", updateAt='" + updateAt + '\'' +
                '}';
    }

    /**
     * @return Integer return the statId
     */
    public Integer getStatId() {
        return statId;
    }

    /**
     * @param statId the statId to set
     */
    public void setStatId(Integer statId) {
        this.statId = statId;
    }

    /**
     * @return Integer return the userId
     */
    public Integer getUserId() {
        return userId;
    }

    /**
     * @param userId the userId to set
     */
    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    /**
     * @return Integer return the year
     */
    public Integer getYear() {
        return year;
    }

    /**
     * @param year the year to set
     */
    public void setYear(Integer year) {
        this.year = year;
    }

    /**
     * @return Integer return the month
     */
    public Integer getMonth() {
        return month;
    }

    /**
     * @param month the month to set
     */
    public void setMonth(Integer month) {
        this.month = month;
    }

    /**
     * @return Integer return the receiptUploads
     */
    public Integer getReceiptUploads() {
        return receiptUploads;
    }

    /**
     * @param receiptUploads the receiptUploads to set
     */
    public void setReceiptUploads(Integer receiptUploads) {
        this.receiptUploads = receiptUploads;
    }

    /**
     * @return Integer return the totalProducts
     */
    public Integer getTotalProducts() {
        return totalProducts;
    }

    /**
     * @param totalProducts the totalProducts to set
     */
    public void setTotalProducts(Integer totalProducts) {
        this.totalProducts = totalProducts;
    }

    /**
     * @return Double return the totalSpent
     */
    public Double getTotalSpent() {
        return totalSpent;
    }

    /**
     * @param totalSpent the totalSpent to set
     */
    public void setTotalSpent(Double totalSpent) {
        this.totalSpent = totalSpent;
    }

    /**
     * @return String return the categoryBreakdown
     */
    public String getCategoryBreakdown() {
        return categoryBreakdown;
    }

    /**
     * @param categoryBreakdown the categoryBreakdown to set
     */
    public void setCategoryBreakdown(String categoryBreakdown) {
        this.categoryBreakdown = categoryBreakdown;
    }

    /**
     * @return String return the popularProducts
     */
    public String getPopularProducts() {
        return popularProducts;
    }

    /**
     * @param popularProducts the popularProducts to set
     */
    public void setPopularProducts(String popularProducts) {
        this.popularProducts = popularProducts;
    }

    /**
     * @return String return the nutritionBreakdown
     */
    public String getNutritionBreakdown() {
        return nutritionBreakdown;
    }

    /**
     * @param nutritionBreakdown the nutritionBreakdown to set
     */
    public void setNutritionBreakdown(String nutritionBreakdown) {
        this.nutritionBreakdown = nutritionBreakdown;
    }

    /**
     * @return String return the calculatedAt
     */
    public String getCalculatedAt() {
        return calculatedAt;
    }

    /**
     * @param calculatedAt the calculatedAt to set
     */
    public void setCalculatedAt(String calculatedAt) {
        this.calculatedAt = calculatedAt;
    }

    /**
     * @return String return the updateAt
     */
    public String getUpdateAt() {
        return updateAt;
    }

    /**
     * @param updateAt the updateAt to set
     */
    public void setUpdateAt(String updateAt) {
        this.updateAt = updateAt;
    }
} 