package org.user.pojo.DTO;

import org.user.enums.SourceType;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public class SugarIntakeHistoryDto {
    
    @JsonProperty("intake_id")
    private Integer intakeId;
    
    @JsonProperty("user_id")
    private Integer userId;
    
    @NotBlank(message = "Food name cannot be empty")
    @Size(max = 200, message = "Food name cannot exceed 200 characters")
    @JsonProperty("food_name")
    private String foodName;
    
    @NotNull(message = "Sugar amount cannot be null")
    @DecimalMin(value = "0.0", message = "Sugar amount must be non-negative")
    @JsonProperty("sugar_amount_mg")
    private Float sugarAmountMg;
    
    @NotNull(message = "Intake time cannot be null")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @JsonProperty("intake_time")
    private LocalDateTime intakeTime;
    
    @JsonProperty("source_type")
    private SourceType sourceType = SourceType.MANUAL;
    
    // @Size(max = 255, message = "Barcode cannot exceed 255 characters")
    // @JsonProperty("barcode")
    // private String barcode;
    
    @Size(max = 50, message = "Serving size cannot exceed 50 characters")
    @JsonProperty("serving_size")
    private String servingSize;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @JsonProperty("created_at")
    private LocalDateTime createdAt;
    
    // constructor
    public SugarIntakeHistoryDto() {}
    
    public SugarIntakeHistoryDto(String foodName, Float sugarAmountMg, LocalDateTime intakeTime) {
        this.foodName = foodName;
        this.sugarAmountMg = sugarAmountMg;
        this.intakeTime = intakeTime;
    }
    
    // Getters and Setters
    public Integer getIntakeId() {
        return intakeId;
    }
    
    public void setIntakeId(Integer intakeId) {
        this.intakeId = intakeId;
    }
    
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    
    public String getFoodName() {
        return foodName;
    }
    
    public void setFoodName(String foodName) {
        this.foodName = foodName;
    }
    
    public Float getSugarAmountMg() {
        return sugarAmountMg;
    }
    
    public void setSugarAmountMg(Float sugarAmountMg) {
        this.sugarAmountMg = sugarAmountMg;
    }
    
    public LocalDateTime getIntakeTime() {
        return intakeTime;
    }
    
    public void setIntakeTime(LocalDateTime intakeTime) {
        this.intakeTime = intakeTime;
    }
    
    public SourceType getSourceType() {
        return sourceType;
    }
    
    public void setSourceType(SourceType sourceType) {
        this.sourceType = sourceType;
    }
    
    // public String getBarcode() {
    //     return barcode;
    // }
    
    // public void setBarcode(String barcode) {
    //     this.barcode = barcode;
    // }
    
    public String getServingSize() {
        return servingSize;
    }
    
    public void setServingSize(String servingSize) {
        this.servingSize = servingSize;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    @Override
    public String toString() {
        return "SugarIntakeHistoryDto{" +
                "intakeId=" + intakeId +
                ", userId=" + userId +
                ", foodName='" + foodName + '\'' +
                ", sugarAmountMg=" + sugarAmountMg +
                ", intakeTime=" + intakeTime +
                ", sourceType=" + sourceType +
                ", servingSize='" + servingSize + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
} 