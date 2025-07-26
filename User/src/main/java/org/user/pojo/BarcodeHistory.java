package org.user.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "barcode_history")
public class BarcodeHistory {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "barcode_id")
    private Integer barcodeId;
    
    @Column(name = "user_id", nullable = false)
    private Integer userId;
    
    @Column(name = "barcode", nullable = false)
    private String barcode;
    
    @Column(name = "scan_time", nullable = false)
    private LocalDateTime scanTime;
    
    @Column(name = "recommendation_id")
    private String recommendationId;
    
    @Column(name = "recommended_products", columnDefinition = "LONGTEXT")
    private String recommendedProducts;
    
    @Column(name = "llm_analysis", columnDefinition = "LONGTEXT")
    private String llmAnalysis;
    
    @Column(name = "created_at", columnDefinition = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createdAt;
    
    // constructor
    public BarcodeHistory() {}
    
    public BarcodeHistory(Integer userId, String barcode, LocalDateTime scanTime) {
        this.userId = userId;
        this.barcode = barcode;
        this.scanTime = scanTime;
    }
    
    // Getters and Setters
    public Integer getBarcodeId() {
        return barcodeId;
    }
    
    public void setBarcodeId(Integer barcodeId) {
        this.barcodeId = barcodeId;
    }
    
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    
    public String getBarcode() {
        return barcode;
    }
    
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }
    
    public LocalDateTime getScanTime() {
        return scanTime;
    }
    
    public void setScanTime(LocalDateTime scanTime) {
        this.scanTime = scanTime;
    }
    
    public String getRecommendationId() {
        return recommendationId;
    }
    
    public void setRecommendationId(String recommendationId) {
        this.recommendationId = recommendationId;
    }
    
    public String getRecommendedProducts() {
        return recommendedProducts;
    }
    
    public void setRecommendedProducts(String recommendedProducts) {
        this.recommendedProducts = recommendedProducts;
    }
    
    public String getLlmAnalysis() {
        return llmAnalysis;
    }
    
    public void setLlmAnalysis(String llmAnalysis) {
        this.llmAnalysis = llmAnalysis;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
} 