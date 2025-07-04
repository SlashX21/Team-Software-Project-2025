package org.user.pojo.DTO;

import org.user.enums.GoalLevel;

public class SugarGoalResponseDto {
    private Double dailyGoalMg;
    private GoalLevel goalLevel;
    private String createdAt;
    private String updatedAt;
    private Boolean isActive;
    
    // constructor
    public SugarGoalResponseDto() {}
    
    public SugarGoalResponseDto(Double dailyGoalMg, GoalLevel goalLevel, String createdAt, String updatedAt, Boolean isActive) {
        this.dailyGoalMg = dailyGoalMg;
        this.goalLevel = goalLevel;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.isActive = isActive;
    }
    public SugarGoalResponseDto(Double dailyGoalMg, String createdAt, String updatedAt) {
        this.dailyGoalMg = dailyGoalMg;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
    // Getters and Setters
    public Double getDailyGoalMg() { return dailyGoalMg; }
    public void setDailyGoalMg(Double dailyGoalMg) { this.dailyGoalMg = dailyGoalMg; }
    
    public GoalLevel getGoalLevel() { return goalLevel; }
    public void setGoalLevel(GoalLevel goalLevel) { this.goalLevel = goalLevel; }
    
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    
    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
    
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    
    @Override
    public String toString() {
        return "SugarGoalResponseDto{" +
                "dailyGoalMg=" + dailyGoalMg +
                ", goalLevel=" + goalLevel +
                ", createdAt='" + createdAt + '\'' +
                ", updatedAt='" + updatedAt + '\'' +
                ", isActive=" + isActive +
                '}';
    }
} 