package org.user.pojo.DTO;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public class MonthlyCalendarDto {
    private Integer year;
    private Integer month;
    
    @JsonProperty("monthlyAverageIntake")
    private Double monthlyAverageIntake;
    
    @JsonProperty("daysTracked")
    private Integer daysTracked;
    
    @JsonProperty("daysOverGoal")
    private Integer daysOverGoal;
    
    @JsonProperty("overallAchievementRate")
    private Double overallAchievementRate;
    
    @JsonProperty("dailySummaries")
    private List<DailySummaryDto> dailySummaries;
    
    // inner class: daily summary data
    public static class DailySummaryDto {
        private String date;
        
        @JsonProperty("totalIntakeMg")
        private Double totalIntakeMg;
        
        @JsonProperty("dailyGoalMg")
        private Double dailyGoalMg;
        
        @JsonProperty("progressPercentage")
        private Double progressPercentage;
        
        private String status;
        
        @JsonProperty("recordCount")
        private Integer recordCount;
        
        // constructor
        public DailySummaryDto() {}
        
        public DailySummaryDto(String date, Double totalIntakeMg, Double dailyGoalMg, 
                              Double progressPercentage, String status, Integer recordCount) {
            this.date = date;
            this.totalIntakeMg = totalIntakeMg;
            this.dailyGoalMg = dailyGoalMg;
            this.progressPercentage = progressPercentage;
            this.status = status;
            this.recordCount = recordCount;
        }
        
        // Getters and Setters
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        
        public Double getTotalIntakeMg() { return totalIntakeMg; }
        public void setTotalIntakeMg(Double totalIntakeMg) { this.totalIntakeMg = totalIntakeMg; }
        
        public Double getDailyGoalMg() { return dailyGoalMg; }
        public void setDailyGoalMg(Double dailyGoalMg) { this.dailyGoalMg = dailyGoalMg; }
        
        public Double getProgressPercentage() { return progressPercentage; }
        public void setProgressPercentage(Double progressPercentage) { this.progressPercentage = progressPercentage; }
        
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        
        public Integer getRecordCount() { return recordCount; }
        public void setRecordCount(Integer recordCount) { this.recordCount = recordCount; }
    }
    
    // constructor
    public MonthlyCalendarDto() {}
    
    public MonthlyCalendarDto(Integer year, Integer month, Double monthlyAverageIntake, 
                             Integer daysTracked, Integer daysOverGoal, Double overallAchievementRate,
                             List<DailySummaryDto> dailySummaries) {
        this.year = year;
        this.month = month;
        this.monthlyAverageIntake = monthlyAverageIntake;
        this.daysTracked = daysTracked;
        this.daysOverGoal = daysOverGoal;
        this.overallAchievementRate = overallAchievementRate;
        this.dailySummaries = dailySummaries;
    }
    
    // Getters and Setters
    public Integer getYear() { return year; }
    public void setYear(Integer year) { this.year = year; }
    
    public Integer getMonth() { return month; }
    public void setMonth(Integer month) { this.month = month; }
    
    public Double getMonthlyAverageIntake() { return monthlyAverageIntake; }
    public void setMonthlyAverageIntake(Double monthlyAverageIntake) { this.monthlyAverageIntake = monthlyAverageIntake; }
    
    public Integer getDaysTracked() { return daysTracked; }
    public void setDaysTracked(Integer daysTracked) { this.daysTracked = daysTracked; }
    
    public Integer getDaysOverGoal() { return daysOverGoal; }
    public void setDaysOverGoal(Integer daysOverGoal) { this.daysOverGoal = daysOverGoal; }
    
    public Double getOverallAchievementRate() { return overallAchievementRate; }
    public void setOverallAchievementRate(Double overallAchievementRate) { this.overallAchievementRate = overallAchievementRate; }
    
    public List<DailySummaryDto> getDailySummaries() { return dailySummaries; }
    public void setDailySummaries(List<DailySummaryDto> dailySummaries) { this.dailySummaries = dailySummaries; }
    
    @Override
    public String toString() {
        return "MonthlyCalendarDto{" +
                "year=" + year +
                ", month=" + month +
                ", monthlyAverageIntake=" + monthlyAverageIntake +
                ", daysTracked=" + daysTracked +
                ", daysOverGoal=" + daysOverGoal +
                ", overallAchievementRate=" + overallAchievementRate +
                ", dailySummaries=" + dailySummaries +
                '}';
    }
} 