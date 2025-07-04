package org.user.pojo.DTO;

import org.user.enums.Source;

public class SugarRecordResponseDto {
    private String id;
    private String foodName;
    private Double sugarAmountMg;
    private Double quantity;
    private String consumedAt;
    private String productBarcode;
    private String createdAt;
    
    // constructor
    public SugarRecordResponseDto() {}
    
    public SugarRecordResponseDto(String id, String foodName, Double sugarAmountMg, 
                                 Double quantity, String consumedAt, String productBarcode, String createdAt) {
        this.id = id;
        this.foodName = foodName;
        this.sugarAmountMg = sugarAmountMg;
        this.quantity = quantity;
        this.consumedAt = consumedAt;
        this.productBarcode = productBarcode;
        this.createdAt = createdAt;
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
    
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    
    @Override
    public String toString() {
        return "SugarRecordResponseDto{" +
                "id='" + id + '\'' +
                ", foodName='" + foodName + '\'' +
                ", sugarAmountMg=" + sugarAmountMg +
                ", quantity=" + quantity +
                ", consumedAt='" + consumedAt + '\'' +
                ", productBarcode='" + productBarcode + '\'' +
                ", createdAt='" + createdAt + '\'' +
                '}';
    }
} 