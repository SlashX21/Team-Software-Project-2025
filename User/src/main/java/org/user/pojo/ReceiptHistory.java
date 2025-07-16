package org.user.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "receipt_history")
public class ReceiptHistory {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "receipt_id")
    private Integer receiptId;
    
    @Column(name = "user_id", nullable = false)
    private Integer userId;
    
    @Column(name = "scan_time", nullable = false)
    private LocalDateTime scanTime;
    
    @Column(name = "recommendation_id")
    private String recommendationId;
    
    @Column(name = "purchased_items", columnDefinition = "LONGTEXT", nullable = false)
    private String purchasedItems;
    
    @Column(name = "llm_summary", columnDefinition = "LONGTEXT")
    private String llmSummary;
    
    @Column(name = "recommendations_list", columnDefinition = "LONGTEXT")
    private String recommendationsList;
    
    @Column(name = "created_at", columnDefinition = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createdAt;
    
    // constructor
    public ReceiptHistory() {}
    
    public ReceiptHistory(Integer userId, LocalDateTime scanTime, String purchasedItems) {
        this.userId = userId;
        this.scanTime = scanTime;
        this.purchasedItems = purchasedItems;
    }
    
    // Getters and Setters
    public Integer getReceiptId() {
        return receiptId;
    }
    
    public void setReceiptId(Integer receiptId) {
        this.receiptId = receiptId;
    }
    
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
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
    
    public String getPurchasedItems() {
        return purchasedItems;
    }
    
    public void setPurchasedItems(String purchasedItems) {
        this.purchasedItems = purchasedItems;
    }
    
    public String getLlmSummary() {
        return llmSummary;
    }
    
    public void setLlmSummary(String llmSummary) {
        this.llmSummary = llmSummary;
    }
    
    public String getRecommendationsList() {
        return recommendationsList;
    }
    
    public void setRecommendationsList(String recommendationsList) {
        this.recommendationsList = recommendationsList;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}