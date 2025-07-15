package org.user.pojo.DTO;

import org.user.enums.SugarSummaryStatus;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.DecimalMin;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class DailySugarSummaryDto {
    
    private Integer id;
    
    @JsonProperty("user_id")
    private Integer userId;
    
    @NotNull(message = "Date cannot be empty")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate date;
    
    @NotNull(message = "Total intake cannot be empty")
    @DecimalMin(value = "0.0", message = "Total intake must be greater than or equal to 0")
    @JsonProperty("total_intake_mg")
    private BigDecimal totalIntakeMg = BigDecimal.ZERO;
    
    @NotNull(message = "Daily goal cannot be empty")
    @DecimalMin(value = "0.01", message = "Daily goal must be greater than 0")
    @JsonProperty("daily_goal_mg")
    private BigDecimal dailyGoalMg;
    
    @JsonProperty("progress_percentage")
    private BigDecimal progressPercentage = BigDecimal.ZERO;
    
    private SugarSummaryStatus status = SugarSummaryStatus.GOOD;
    
    @JsonProperty("record_count")
    private Integer recordCount = 0;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @JsonProperty("created_at")
    private LocalDateTime createdAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @JsonProperty("updated_at")
    private LocalDateTime updatedAt;
    
    // constructor
    public DailySugarSummaryDto() {}
    
    public DailySugarSummaryDto(Integer userId, LocalDate date, BigDecimal dailyGoalMg) {
        this.userId = userId;
        this.date = date;
        this.dailyGoalMg = dailyGoalMg;
    }
    
    // Getters and Setters
    public Integer getId() {
        return id;
    }
    
    public void setId(Integer id) {
        this.id = id;
    }
    
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    
    public LocalDate getDate() {
        return date;
    }
    
    public void setDate(LocalDate date) {
        this.date = date;
    }
    
    public BigDecimal getTotalIntakeMg() {
        return totalIntakeMg;
    }
    
    public void setTotalIntakeMg(BigDecimal totalIntakeMg) {
        this.totalIntakeMg = totalIntakeMg;
    }
    
    public BigDecimal getDailyGoalMg() {
        return dailyGoalMg;
    }
    
    public void setDailyGoalMg(BigDecimal dailyGoalMg) {
        this.dailyGoalMg = dailyGoalMg;
    }
    
    public BigDecimal getProgressPercentage() {
        return progressPercentage;
    }
    
    public void setProgressPercentage(BigDecimal progressPercentage) {
        this.progressPercentage = progressPercentage;
    }
    
    public SugarSummaryStatus getStatus() {
        return status;
    }
    
    public void setStatus(SugarSummaryStatus status) {
        this.status = status;
    }
    
    public Integer getRecordCount() {
        return recordCount;
    }
    
    public void setRecordCount(Integer recordCount) {
        this.recordCount = recordCount;
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
        return "DailySugarSummaryDto{" +
                "id=" + id +
                ", userId=" + userId +
                ", date=" + date +
                ", totalIntakeMg=" + totalIntakeMg +
                ", dailyGoalMg=" + dailyGoalMg +
                ", progressPercentage=" + progressPercentage +
                ", status=" + status +
                ", recordCount=" + recordCount +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
} 