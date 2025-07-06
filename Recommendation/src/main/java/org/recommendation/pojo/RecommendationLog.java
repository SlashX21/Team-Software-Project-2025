package org.recommendation.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Table(name = "recommendation_log")
@Entity
public class RecommendationLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="log_id")
    private Integer logId;

    @Column(name="user_id", nullable = false)
    private Integer userId;

    @Column(name="request_barcode")
    private String requestBarcode;

    @Column(name="request_type", nullable = false)
    private String requestType;

    @Column(name="recommended_products", columnDefinition = "LONGTEXT")
    private String recommendedProducts;

    @Column(name="algorithm_version", nullable = false)
    private String algorithmVersion = "v1.0";

    @Column(name="llm_prompt", columnDefinition = "LONGTEXT")
    private String llmPrompt;

    @Column(name="llm_response", columnDefinition = "LONGTEXT")
    private String llmResponse;

    @Column(name="llm_analysis", columnDefinition = "LONGTEXT")
    private String llmAnalysis;

    @Column(name="processing_time_ms")
    private Integer processingTimeMs;

    @Column(name="total_candidates")
    private Integer totalCandidates;

    @Column(name="filtered_candidates")
    private Integer filteredCandidates;

    @Column(name="created_at", columnDefinition = "TIMESTAMP")
    private LocalDateTime createdAt;

    // Constructors
    public RecommendationLog() {
        this.createdAt = LocalDateTime.now();
    }

    public RecommendationLog(Integer userId, String requestType) {
        this.userId = userId;
        this.requestType = requestType;
        this.createdAt = LocalDateTime.now();
    }

    @Override
    public String toString() {
        return "RecommendationLog{" +
                "logId=" + logId +
                ", userId=" + userId +
                ", requestBarcode='" + requestBarcode + '\'' +
                ", requestType='" + requestType + '\'' +
                ", algorithmVersion='" + algorithmVersion + '\'' +
                ", processingTimeMs=" + processingTimeMs +
                ", totalCandidates=" + totalCandidates +
                ", filteredCandidates=" + filteredCandidates +
                ", createdAt=" + createdAt +
                '}';
    }

    // Getters and Setters
    public Integer getLogId() {
        return logId;
    }

    public void setLogId(Integer logId) {
        this.logId = logId;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getRequestBarcode() {
        return requestBarcode;
    }

    public void setRequestBarcode(String requestBarcode) {
        this.requestBarcode = requestBarcode;
    }

    public String getRequestType() {
        return requestType;
    }

    public void setRequestType(String requestType) {
        this.requestType = requestType;
    }

    public String getRecommendedProducts() {
        return recommendedProducts;
    }

    public void setRecommendedProducts(String recommendedProducts) {
        this.recommendedProducts = recommendedProducts;
    }

    public String getAlgorithmVersion() {
        return algorithmVersion;
    }

    public void setAlgorithmVersion(String algorithmVersion) {
        this.algorithmVersion = algorithmVersion;
    }

    public String getLlmPrompt() {
        return llmPrompt;
    }

    public void setLlmPrompt(String llmPrompt) {
        this.llmPrompt = llmPrompt;
    }

    public String getLlmResponse() {
        return llmResponse;
    }

    public void setLlmResponse(String llmResponse) {
        this.llmResponse = llmResponse;
    }

    public String getLlmAnalysis() {
        return llmAnalysis;
    }

    public void setLlmAnalysis(String llmAnalysis) {
        this.llmAnalysis = llmAnalysis;
    }

    public Integer getProcessingTimeMs() {
        return processingTimeMs;
    }

    public void setProcessingTimeMs(Integer processingTimeMs) {
        this.processingTimeMs = processingTimeMs;
    }

    public Integer getTotalCandidates() {
        return totalCandidates;
    }

    public void setTotalCandidates(Integer totalCandidates) {
        this.totalCandidates = totalCandidates;
    }

    public Integer getFilteredCandidates() {
        return filteredCandidates;
    }

    public void setFilteredCandidates(Integer filteredCandidates) {
        this.filteredCandidates = filteredCandidates;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
} 