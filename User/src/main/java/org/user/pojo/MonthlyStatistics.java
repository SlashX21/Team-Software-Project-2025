package org.user.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Table(name = "monthly_statistics")
@Entity
public class MonthlyStatistics {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="stat_id")
    private Integer statId;

    @Column(name="user_id", nullable = false)
    private Integer userId;

    @Column(name="year")
    private Integer year;

    @Column(name="month")
    private Integer month;

    @Column(name="receipt_uploads")
    private Integer receiptUploads;
    
    @Column(name="total_products")
    private Integer totalProducts;

    @Column(name="total_spent", columnDefinition = "DECIMAL")
    private Double totalSpent;

    @Column(name="category_breakdown", columnDefinition = "LONGTEXT")
    private String categoryBreakdown;
    
    @Column(name="popular_products", columnDefinition = "LONGTEXT")
    private String popularProducts; 

    @Column(name="nutrition_breakdown", columnDefinition = "LONGTEXT")
    private String nutritionBreakdown;

    @Column(name="calculated_at", columnDefinition = "DATETIME")
    private String calculatedAt;

    @Column(name="update_at", columnDefinition = "DATETIME")
    private String updateAt;

    @Override
    public String toString() {
        return "MonthlyStatistics{" +
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
