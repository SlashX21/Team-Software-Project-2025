package org.recommendation.pojo;

public class BarcodeRecommendationRequest {
    private Integer userId;
    private String productBarcode;

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }
    public String getProductBarcode() { return productBarcode; }
    public void setProductBarcode(String productBarcode) { this.productBarcode = productBarcode; }
} 