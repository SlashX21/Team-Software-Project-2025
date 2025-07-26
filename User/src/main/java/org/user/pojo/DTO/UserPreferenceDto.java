package org.user.pojo.DTO;

import org.user.enums.PreferenceSource;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class UserPreferenceDto {
    
    private Integer preferenceId;
    
    @NotNull(message = "User ID cannot be empty")
    private Integer userId;
    
    @JsonProperty("prefer_low_sugar")
    private Boolean preferLowSugar = false;
    
    @JsonProperty("prefer_low_fat")
    private Boolean preferLowFat = false;
    
    @JsonProperty("prefer_high_protein")
    private Boolean preferHighProtein = false;
    
    @JsonProperty("prefer_low_sodium")
    private Boolean preferLowSodium = false;
    
    @JsonProperty("prefer_organic")
    private Boolean preferOrganic = false;
    
    @JsonProperty("prefer_low_calorie")
    private Boolean preferLowCalorie = false;
    
    @JsonProperty("preference_source")
    private PreferenceSource preferenceSource = PreferenceSource.USER_MANUAL;
    
    @JsonProperty("inference_confidence")
    @DecimalMin(value = "0.0", message = "推断置信度不能小于0")
    @DecimalMax(value = "1.0", message = "推断置信度不能大于1")
    private BigDecimal inferenceConfidence = BigDecimal.ZERO;
    
    private Integer version = 1;
    
    @JsonProperty("created_at")
    private LocalDateTime createdAt;
    
    @JsonProperty("updated_at")
    private LocalDateTime updatedAt;
    
    // constructor
    public UserPreferenceDto() {}
    
    public UserPreferenceDto(Integer userId) {
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
    
    @Override
    public String toString() {
        return "UserPreferenceDto{" +
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