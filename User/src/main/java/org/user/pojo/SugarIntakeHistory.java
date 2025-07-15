package org.user.pojo;

import org.user.enums.SourceType;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sugar_intake_history")
public class SugarIntakeHistory {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Integer intakeId;
    
    @Column(name = "user_id", nullable = false)
    private Integer userId;
    
    @Column(name = "food_name", nullable = false, length = 200)
    private String foodName;
    
    @Column(name = "sugar_amount_mg", nullable = false)
    private Float sugarAmountMg;
    
    @Column(name = "quantity", nullable = false)
    private Float quantity;

    @Column(name = "consumed_at", nullable = false, updatable = false)
    private LocalDateTime consumedAt;
    
    // @Column(name = "barcode", length = 255)
    // private String barcode;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    // 构造函数
    public SugarIntakeHistory() {}
    
    public SugarIntakeHistory(Integer userId, String foodName, Float sugarAmountMg, 
                             Float quantity) {
        this.userId = userId;
        this.foodName = foodName;
        this.sugarAmountMg = sugarAmountMg;
        this.quantity = quantity;
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
    
    public Float getQuantity() {
        return quantity;
    }
    
    public void setQuantity(Float quantity) {
        this.quantity = quantity;
    }
    
    public LocalDateTime getConsumedAt() {
        return consumedAt;
    }
    
    public void setConsumedAt(LocalDateTime consumedAt) {
        this.consumedAt = consumedAt;
    }
    
    // public String getBarcode() {
    //     return barcode;
    // }
    
    // public void setBarcode(String barcode) {
    //     this.barcode = barcode;
    // }
    
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
                ", quantity=" + quantity +
                ", consumedAt=" + consumedAt +
                ", createdAt=" + createdAt +
                '}';
    }
} 