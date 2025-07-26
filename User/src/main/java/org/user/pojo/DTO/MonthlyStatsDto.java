package org.user.pojo.DTO;

import java.util.List;

public class MonthlyStatsDto {
    private String month;
    private Double averageDailyIntake;
    private Double goalAchievementRate;
    private Integer totalDaysTracked;
    private List<DailyDataDto> dailyData;
    private TrendsDto trends;
    
    // inner class: daily data
    public static class DailyDataDto {
        private String date;
        private Integer intake;
        private Integer goal;
        private Boolean exceeded;
        
        public DailyDataDto() {}
        
        public DailyDataDto(String date, Integer intake, Integer goal, Boolean exceeded) {
            this.date = date;
            this.intake = intake;
            this.goal = goal;
            this.exceeded = exceeded;
        }
        
        // Getters and Setters
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        
        public Integer getIntake() { return intake; }
        public void setIntake(Integer intake) { this.intake = intake; }
        
        public Integer getGoal() { return goal; }
        public void setGoal(Integer goal) { this.goal = goal; }
        
        public Boolean getExceeded() { return exceeded; }
        public void setExceeded(Boolean exceeded) { this.exceeded = exceeded; }
    }
    
    // inner class: trends data
    public static class TrendsDto {
        private Integer improvingDays;
        private Integer worseningDays;
        private String peakIntakeDay;
        private String bestDay;
        
        public TrendsDto() {}
        
        public TrendsDto(Integer improvingDays, Integer worseningDays, String peakIntakeDay, String bestDay) {
            this.improvingDays = improvingDays;
            this.worseningDays = worseningDays;
            this.peakIntakeDay = peakIntakeDay;
            this.bestDay = bestDay;
        }
        
        // Getters and Setters
        public Integer getImprovingDays() { return improvingDays; }
        public void setImprovingDays(Integer improvingDays) { this.improvingDays = improvingDays; }
        
        public Integer getWorseningDays() { return worseningDays; }
        public void setWorseningDays(Integer worseningDays) { this.worseningDays = worseningDays; }
        
        public String getPeakIntakeDay() { return peakIntakeDay; }
        public void setPeakIntakeDay(String peakIntakeDay) { this.peakIntakeDay = peakIntakeDay; }
        
        public String getBestDay() { return bestDay; }
        public void setBestDay(String bestDay) { this.bestDay = bestDay; }
    }
    
    // constructor
    public MonthlyStatsDto() {}
    
    public MonthlyStatsDto(String month, Double averageDailyIntake, Double goalAchievementRate, 
                          Integer totalDaysTracked, List<DailyDataDto> dailyData, TrendsDto trends) {
        this.month = month;
        this.averageDailyIntake = averageDailyIntake;
        this.goalAchievementRate = goalAchievementRate;
        this.totalDaysTracked = totalDaysTracked;
        this.dailyData = dailyData;
        this.trends = trends;
    }
    
    // Getters and Setters
    public String getMonth() { return month; }
    public void setMonth(String month) { this.month = month; }
    
    public Double getAverageDailyIntake() { return averageDailyIntake; }
    public void setAverageDailyIntake(Double averageDailyIntake) { this.averageDailyIntake = averageDailyIntake; }
    
    public Double getGoalAchievementRate() { return goalAchievementRate; }
    public void setGoalAchievementRate(Double goalAchievementRate) { this.goalAchievementRate = goalAchievementRate; }
    
    public Integer getTotalDaysTracked() { return totalDaysTracked; }
    public void setTotalDaysTracked(Integer totalDaysTracked) { this.totalDaysTracked = totalDaysTracked; }
    
    public List<DailyDataDto> getDailyData() { return dailyData; }
    public void setDailyData(List<DailyDataDto> dailyData) { this.dailyData = dailyData; }
    
    public TrendsDto getTrends() { return trends; }
    public void setTrends(TrendsDto trends) { this.trends = trends; }
    
    @Override
    public String toString() {
        return "MonthlyStatsDto{" +
                "month='" + month + '\'' +
                ", averageDailyIntake=" + averageDailyIntake +
                ", goalAchievementRate=" + goalAchievementRate +
                ", totalDaysTracked=" + totalDaysTracked +
                ", dailyData=" + dailyData +
                ", trends=" + trends +
                '}';
    }
} 