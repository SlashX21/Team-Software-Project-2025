package org.user.pojo;

import org.user.enums.SourceType;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sugar_intake_history")
public class SugarIntakeHistory {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "intake_id")
    private Integer intakeId;
    
    @Column(name = "user_id", nullable = false)
    private Integer userId;
    
    @Column(name = "food_name", nullable = false, length = 200)
    private String foodName;
    
    @Column(name = "sugar_amount_mg", nullable = false)
    private Float sugarAmountMg;
    
    @Column(name = "intake_time", nullable = false)
    private LocalDateTime intakeTime;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false)
    private SourceType sourceType = SourceType.MANUAL;
    
    @Column(name = "barcode", length = 255)
    private String barcode;
    
    @Column(name = "serving_size", length = 50)
    private String servingSize;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    // 构造函数
    public SugarIntakeHistory() {}
    
    public SugarIntakeHistory(Integer userId, String foodName, Float sugarAmountMg, 
                             LocalDateTime intakeTime, SourceType sourceType) {
        this.userId = userId;
        this.foodName = foodName;
        this.sugarAmountMg = sugarAmountMg;
        this.intakeTime = intakeTime;
        this.sourceType = sourceType;
    }
    
    // PrePersist回调
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
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
    
    public String getBarcode() {
        return barcode;
    }
    
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }
    
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
        return "SugarIntakeHistory{" +
                "intakeId=" + intakeId +
                ", userId=" + userId +
                ", foodName='" + foodName + '\'' +
                ", sugarAmountMg=" + sugarAmountMg +
                ", intakeTime=" + intakeTime +
                ", sourceType=" + sourceType +
                ", barcode='" + barcode + '\'' +
                ", servingSize='" + servingSize + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
} 