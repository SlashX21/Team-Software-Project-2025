package org.user.pojo.DTO;

import org.user.enums.GoalLevel;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;

public class SugarGoalRequestDto {
    @NotNull(message = "daily_goal_mg cannot be null")
    @Min(value = 0, message = "daily_goal_mg must be greater than or equal to 0")
    private Double dailyGoalMg;
    
    private GoalLevel goalLevel;
    
    // constructor
    public SugarGoalRequestDto() {}
    
    public SugarGoalRequestDto(Double dailyGoalMg, GoalLevel goalLevel) {
        this.dailyGoalMg = dailyGoalMg;
        this.goalLevel = goalLevel;
    }
    
    // Getters and Setters
    public Double getDailyGoalMg() { return dailyGoalMg; }
    public void setDailyGoalMg(Double dailyGoalMg) { this.dailyGoalMg = dailyGoalMg; }
    
    public GoalLevel getGoalLevel() { return goalLevel; }
    public void setGoalLevel(GoalLevel goalLevel) { this.goalLevel = goalLevel; }
    
    @Override
    public String toString() {
        return "SugarGoalRequestDto{" +
                "dailyGoalMg=" + dailyGoalMg +
                ", goalLevel=" + goalLevel +
                '}';
    }
} 