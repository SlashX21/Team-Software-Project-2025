package org.product.pojo;

import jakarta.persistence.*;
import org.product.enums.PreferenceType;

import java.time.LocalDateTime;

@Entity
@Table(name = "product_preference")
public class ProductPreference {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "preference_id")
    private Integer preferenceId;
    
    @Column(name = "user_id", nullable = false)
    private Integer userId;
    
    @Column(name = "bar_code", nullable = false)
    private String barCode;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "preference_type", nullable = false)
    private PreferenceType preferenceType;
    
    @Column(name = "reason", columnDefinition = "TEXT")
    private String reason;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    // associated product entity (optional)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bar_code", referencedColumnName = "barcode", insertable = false, updatable = false)
    private Product product;
    
    // default constructor
    public ProductPreference() {}
    
    // constructor with parameters
    public ProductPreference(Integer userId, String barCode, PreferenceType preferenceType, String reason) {
        this.userId = userId;
        this.barCode = barCode;
        this.preferenceType = preferenceType;
        this.reason = reason;
        this.createdAt = LocalDateTime.now();
    }
    
    // set the creation time before persisting
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
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
    
    public Product getProduct() {
        return product;
    }
    
    public void setProduct(Product product) {
        this.product = product;
    }
    
    @Override
    public String toString() {
        return "ProductPreference{" +
                "preferenceId=" + preferenceId +
                ", userId=" + userId +
                ", barCode='" + barCode + '\'' +
                ", preferenceType=" + preferenceType +
                ", reason='" + reason + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        
        ProductPreference that = (ProductPreference) o;
        
        if (preferenceId != null ? !preferenceId.equals(that.preferenceId) : that.preferenceId != null)
            return false;
        if (userId != null ? !userId.equals(that.userId) : that.userId != null) return false;
        return barCode != null ? barCode.equals(that.barCode) : that.barCode == null;
    }
    
    @Override
    public int hashCode() {
        int result = preferenceId != null ? preferenceId.hashCode() : 0;
        result = 31 * result + (userId != null ? userId.hashCode() : 0);
        result = 31 * result + (barCode != null ? barCode.hashCode() : 0);
        return result;
    }
} 