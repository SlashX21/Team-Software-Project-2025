package org.user.pojo;

import org.user.enums.GoalLevel;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Enumerated;
import jakarta.persistence.EnumType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Table(name = "sugar_goals")
@Entity
public class SugarGoals {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="goal_id")
    private Integer goalId;

    @Column(name="user_id", nullable = false)
    private Integer userId;

    @Column(name="daily_goal_mg")
    private Double dailyGoalMg;

    @Column(name="goal_level")
    @Enumerated(EnumType.STRING)
    private GoalLevel goalLevel;

    @Column(name="created_at", columnDefinition = "DATETIME")
    private String createdAt;
    
    @Column(name="updated_at", columnDefinition = "DATETIME")
    private String updatedAt;

    @Column(name="is_active")
    private Boolean isActive;
    
    @Override
    public String toString() {
        return "SugarGoals{" +
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
    public Boolean isIsActive() {
        return isActive;
    }

    /**
     * @param isActive the isActive to set
     */
    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

}
