package org.user.pojo.DTO;

import java.util.List;

public class SugarHistoryStatsDto {
    private List<DailyDataDto> dailyData;
    private Double averageDailyIntake;
    private Double totalIntake;
    private Integer daysOverGoal;
    private List<String> topFoodSources;
    
    // 内嵌类：每日数据
    public static class DailyDataDto {
        private String date;
        private Double intakeMg;
        private Double goalMg;
        
        public DailyDataDto() {}
        
        public DailyDataDto(String date, Double intakeMg, Double goalMg) {
            this.date = date;
            this.intakeMg = intakeMg;
            this.goalMg = goalMg;
        }
        
        // Getters and Setters
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        
        public Double getIntakeMg() { return intakeMg; }
        public void setIntakeMg(Double intakeMg) { this.intakeMg = intakeMg; }
        
        public Double getGoalMg() { return goalMg; }
        public void setGoalMg(Double goalMg) { this.goalMg = goalMg; }
    }
    
    // 构造函数
    public SugarHistoryStatsDto() {}
    
    public SugarHistoryStatsDto(List<DailyDataDto> dailyData, Double averageDailyIntake, 
                               Double totalIntake, Integer daysOverGoal, List<String> topFoodSources) {
        this.dailyData = dailyData;
        this.averageDailyIntake = averageDailyIntake;
        this.totalIntake = totalIntake;
        this.daysOverGoal = daysOverGoal;
        this.topFoodSources = topFoodSources;
    }
    
    // Getters and Setters
    public List<DailyDataDto> getDailyData() { return dailyData; }
    public void setDailyData(List<DailyDataDto> dailyData) { this.dailyData = dailyData; }
    
    public Double getAverageDailyIntake() { return averageDailyIntake; }
    public void setAverageDailyIntake(Double averageDailyIntake) { this.averageDailyIntake = averageDailyIntake; }
    
    public Double getTotalIntake() { return totalIntake; }
    public void setTotalIntake(Double totalIntake) { this.totalIntake = totalIntake; }
    
    public Integer getDaysOverGoal() { return daysOverGoal; }
    public void setDaysOverGoal(Integer daysOverGoal) { this.daysOverGoal = daysOverGoal; }
    
    public List<String> getTopFoodSources() { return topFoodSources; }
    public void setTopFoodSources(List<String> topFoodSources) { this.topFoodSources = topFoodSources; }
    
    @Override
    public String toString() {
        return "SugarHistoryStatsDto{" +
                "dailyData=" + dailyData +
                ", averageDailyIntake=" + averageDailyIntake +
                ", totalIntake=" + totalIntake +
                ", daysOverGoal=" + daysOverGoal +
                ", topFoodSources=" + topFoodSources +
                '}';
    }
} 