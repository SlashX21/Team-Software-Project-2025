package org.user.pojo;

import org.user.enums.SugarSummaryStatus;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "daily_sugar_summary")
public class DailySugarSummary {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Integer id;
    
    @Column(name = "user_id", nullable = false)
    private Integer userId;
    
    @Column(name = "date", nullable = false)
    private LocalDate date;
    
    @Column(name = "total_intake_mg", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalIntakeMg = BigDecimal.ZERO;
    
    @Column(name = "daily_goal_mg", nullable = false, precision = 10, scale = 2)
    private BigDecimal dailyGoalMg;
    
    @Column(name = "progress_percentage", nullable = false, precision = 5, scale = 2)
    private BigDecimal progressPercentage = BigDecimal.ZERO;
    
    @Column(name = "status", nullable = false)
    @Enumerated(EnumType.STRING)
    private SugarSummaryStatus status = SugarSummaryStatus.GOOD;
    
    @Column(name = "record_count", nullable = false)
    private Integer recordCount = 0;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    // constructor
    public DailySugarSummary() {}
    
    public DailySugarSummary(Integer userId, LocalDate date, BigDecimal dailyGoalMg) {
        this.userId = userId;
        this.date = date;
        this.dailyGoalMg = dailyGoalMg;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
    
    // PrePersist and PreUpdate callbacks
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
        updateStatusAndPercentage();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
        updateStatusAndPercentage();
    }
    
    /**
     * Calculate progress percentage and status based on intake and goal
     */
    public void updateStatusAndPercentage() {
        if (dailyGoalMg != null && dailyGoalMg.compareTo(BigDecimal.ZERO) > 0) {
            this.progressPercentage = totalIntakeMg.divide(dailyGoalMg, 4, BigDecimal.ROUND_HALF_UP)
                    .multiply(new BigDecimal("100"))
                    .setScale(2, BigDecimal.ROUND_HALF_UP);
            
            // Determine status based on progress percentage
            if (progressPercentage.compareTo(new BigDecimal("100")) > 0) {
                this.status = SugarSummaryStatus.OVER_LIMIT;
            } else if (progressPercentage.compareTo(new BigDecimal("80")) >= 0) {
                this.status = SugarSummaryStatus.WARNING;
            } else {
                this.status = SugarSummaryStatus.GOOD;
            }
        } else {
            this.progressPercentage = BigDecimal.ZERO;
            this.status = SugarSummaryStatus.GOOD;
        }
    }
    
    /**
     * Add sugar intake record
     */
    public void addIntake(BigDecimal sugarAmount) {
        if (sugarAmount != null && sugarAmount.compareTo(BigDecimal.ZERO) > 0) {
            this.totalIntakeMg = this.totalIntakeMg.add(sugarAmount);
            this.recordCount++;
            updateStatusAndPercentage();
        }
    }
    
    /**
     * Remove sugar intake record
     */
    public void removeIntake(BigDecimal sugarAmount) {
        if (sugarAmount != null && sugarAmount.compareTo(BigDecimal.ZERO) > 0) {
            this.totalIntakeMg = this.totalIntakeMg.subtract(sugarAmount);
            if (this.totalIntakeMg.compareTo(BigDecimal.ZERO) < 0) {
                this.totalIntakeMg = BigDecimal.ZERO;
            }
            this.recordCount = Math.max(0, this.recordCount - 1);
            updateStatusAndPercentage();
        }
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
        updateStatusAndPercentage();
    }
    
    public BigDecimal getDailyGoalMg() {
        return dailyGoalMg;
    }
    
    public void setDailyGoalMg(BigDecimal dailyGoalMg) {
        this.dailyGoalMg = dailyGoalMg;
        updateStatusAndPercentage();
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
        return "DailySugarSummary{" +
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