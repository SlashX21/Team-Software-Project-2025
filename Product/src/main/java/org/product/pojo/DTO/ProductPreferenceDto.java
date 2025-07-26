package org.product.pojo.DTO;

import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.product.enums.PreferenceType;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDateTime;

public class ProductPreferenceDto {
    
    private Integer preferenceId;
    
    // userId is not required in the request body, it will be set from the path parameter
    private Integer userId;
    
    @NotBlank(message = "Bar code cannot be empty")
    @JsonProperty("barcode") // support JSON with "barcode" field name
    private String barCode;
    
    @NotNull(message = "Preference type cannot be null")
    @Enumerated(EnumType.STRING)
    private PreferenceType preferenceType;
    
    private String reason;
    
    private LocalDateTime createdAt;
    
    // associated product information (for response)
    private String productName;
    private String brand;
    private String category;
    
    // default constructor
    public ProductPreferenceDto() {}
    
    // constructor with parameters
    public ProductPreferenceDto(Integer userId, String barCode, PreferenceType preferenceType, String reason) {
        this.userId = userId;
        this.barCode = barCode;
        this.preferenceType = preferenceType;
        this.reason = reason;
    }
    
    // Getters and Setters
    public Integer getPreferenceId() {
        return preferenceId;
    }
    
    public void setPreferenceId(Integer preferenceId) {
        this.preferenceId = preferenceId;
    }
    
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    
    public String getBarCode() {
        return barCode;
    }
    
    public void setBarCode(String barCode) {
        this.barCode = barCode;
    }
    
    public PreferenceType getPreferenceType() {
        return preferenceType;
    }
    
    public void setPreferenceType(PreferenceType preferenceType) {
        this.preferenceType = preferenceType;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public String getProductName() {
        return productName;
    }
    
    public void setProductName(String productName) {
        this.productName = productName;
    }
    
    public String getBrand() {
        return brand;
    }
    
    public void setBrand(String brand) {
        this.brand = brand;
    }
    
    public String getCategory() {
        return category;
    }
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    @Override
    public String toString() {
        return "ProductPreferenceDto{" +
                "preferenceId=" + preferenceId +
                ", userId=" + userId +
                ", barCode='" + barCode + '\'' +
                ", preferenceType=" + preferenceType +
                ", reason='" + reason + '\'' +
                ", createdAt=" + createdAt +
                ", productName='" + productName + '\'' +
                ", brand='" + brand + '\'' +
                ", category='" + category + '\'' +
                '}';
    }
} 