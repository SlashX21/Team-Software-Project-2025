package org.user.pojo;

import org.user.enums.PreferenceSource;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_preference")
public class UserPreference {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "preference_id")
    private Integer preferenceId;
    
    @Column(name = "user_id", nullable = false)
    private Integer userId;
    
    @Column(name = "prefer_low_sugar", nullable = false)
    private Boolean preferLowSugar = false;
    
    @Column(name = "prefer_low_fat", nullable = false)
    private Boolean preferLowFat = false;
    
    @Column(name = "prefer_high_protein", nullable = false)
    private Boolean preferHighProtein = false;
    
    @Column(name = "prefer_low_sodium", nullable = false)
    private Boolean preferLowSodium = false;
    
    @Column(name = "prefer_organic", nullable = false)
    private Boolean preferOrganic = false;
    
    @Column(name = "prefer_low_calorie", nullable = false)
    private Boolean preferLowCalorie = false;
    
    @Column(name = "preference_source", nullable = false)
    @Enumerated(EnumType.STRING)
    private PreferenceSource preferenceSource = PreferenceSource.USER_MANUAL;
    
    @Column(name = "inference_confidence", precision = 3, scale = 2)
    private BigDecimal inferenceConfidence = BigDecimal.ZERO;
    
    @Column(name = "version", nullable = false)
    private Integer version = 1;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    // constructor
    public UserPreference() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
    
    public UserPreference(Integer userId) {
        this();
        this.userId = userId;
    }
    
    // Getter and Setter methods
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
    
    public Boolean getPreferLowSugar() {
        return preferLowSugar;
    }
    
    public void setPreferLowSugar(Boolean preferLowSugar) {
        this.preferLowSugar = preferLowSugar;
    }
    
    public Boolean getPreferLowFat() {
        return preferLowFat;
    }
    
    public void setPreferLowFat(Boolean preferLowFat) {
        this.preferLowFat = preferLowFat;
    }
    
    public Boolean getPreferHighProtein() {
        return preferHighProtein;
    }
    
    public void setPreferHighProtein(Boolean preferHighProtein) {
        this.preferHighProtein = preferHighProtein;
    }
    
    public Boolean getPreferLowSodium() {
        return preferLowSodium;
    }
    
    public void setPreferLowSodium(Boolean preferLowSodium) {
        this.preferLowSodium = preferLowSodium;
    }
    
    public Boolean getPreferOrganic() {
        return preferOrganic;
    }
    
    public void setPreferOrganic(Boolean preferOrganic) {
        this.preferOrganic = preferOrganic;
    }
    
    public Boolean getPreferLowCalorie() {
        return preferLowCalorie;
    }
    
    public void setPreferLowCalorie(Boolean preferLowCalorie) {
        this.preferLowCalorie = preferLowCalorie;
    }
    
    public PreferenceSource getPreferenceSource() {
        return preferenceSource;
    }
    
    public void setPreferenceSource(PreferenceSource preferenceSource) {
        this.preferenceSource = preferenceSource;
    }
    
    public BigDecimal getInferenceConfidence() {
        return inferenceConfidence;
    }
    
    public void setInferenceConfidence(BigDecimal inferenceConfidence) {
        this.inferenceConfidence = inferenceConfidence;
    }
    
    public Integer getVersion() {
        return version;
    }
    
    public void setVersion(Integer version) {
        this.version = version;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    // update timestamp
    public void updateTimestamp() {
        this.updatedAt = LocalDateTime.now();
        this.version++;
    }
    
    @Override
    public String toString() {
        return "UserPreference{" +
                "preferenceId=" + preferenceId +
                ", userId=" + userId +
                ", preferLowSugar=" + preferLowSugar +
                ", preferLowFat=" + preferLowFat +
                ", preferHighProtein=" + preferHighProtein +
                ", preferLowSodium=" + preferLowSodium +
                ", preferOrganic=" + preferOrganic +
                ", preferLowCalorie=" + preferLowCalorie +
                ", preferenceSource=" + preferenceSource +
                ", inferenceConfidence=" + inferenceConfidence +
                ", version=" + version +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
} 