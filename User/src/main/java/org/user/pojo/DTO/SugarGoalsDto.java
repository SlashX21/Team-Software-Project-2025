package org.user.pojo.DTO;

import org.user.enums.GoalLevel;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;

public class SugarGoalsDto {
    private Integer goalId;

    @NotNull(message = "user_id can not be null")
    private Integer userId;

    @NotNull(message = "daily_goal_mg can not be null")
    @Min(value = 0, message = "daily_goal_mg must be greater than or equal to 0")
    private Double dailyGoalMg;

    @NotNull(message = "goal_level can not be null")
    private GoalLevel goalLevel;

    private String createdAt;
    
    private String updatedAt;

    private Boolean isActive;
    
    @Override
    public String toString() {
        return "SugarGoalsDto{" +
                "goalId=" + goalId +
                ", userId=" + userId +
                ", dailyGoalMg=" + dailyGoalMg +
                ", goalLevel=" + goalLevel +
                ", createdAt='" + createdAt + '\'' +
                ", updatedAt='" + updatedAt + '\'' +
                ", isActive=" + isActive +
                '}';
    }

    /**
     * @return Integer return the goalId
     */
    public Integer getGoalId() {
        return goalId;
    }

    /**
     * @param goalId the goalId to set
     */
    public void setGoalId(Integer goalId) {
        this.goalId = goalId;
    }

    /**
     * @return Integer return the userId
     */
    public Integer getUserId() {
        return userId;
    }

    /**
     * @param userId the userId to set
     */
    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    /**
     * @return Double return the dailyGoalMg
     */
    public Double getDailyGoalMg() {
        return dailyGoalMg;
    }

    /**
     * @param dailyGoalMg the dailyGoalMg to set
     */
    public void setDailyGoalMg(Double dailyGoalMg) {
        this.dailyGoalMg = dailyGoalMg;
    }

    /**
     * @return GoalLevel return the goalLevel
     */
    public GoalLevel getGoalLevel() {
        return goalLevel;
    }

    /**
     * @param goalLevel the goalLevel to set
     */
    public void setGoalLevel(GoalLevel goalLevel) {
        this.goalLevel = goalLevel;
    }

    /**
     * @return String return the createdAt
     */
    public String getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt the createdAt to set
     */
    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    /**
     * @return String return the updatedAt
     */
    public String getUpdatedAt() {
        return updatedAt;
    }

    /**
     * @param updatedAt the updatedAt to set
     */
    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }

    /**
     * @return Boolean return the isActive
     */
    public Boolean getIsActive() {
        return isActive;
    }

    /**
     * @param isActive the isActive to set
     */
    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }
} 