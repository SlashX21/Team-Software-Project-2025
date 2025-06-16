package org.user.pojo.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import org.hibernate.validator.constraints.Length;

import org.user.enums.Gender;
import org.user.enums.ActivityLevel;
import org.user.enums.NutritionGoal;


public class UserDto {
    private Integer userId;

    @NotBlank(message = "用户名不能为空") //可以去除空格
    private String userName;

    @NotBlank(message = "密码不能为空") //可以去除空格
    @Length(min = 6, max = 12)
    private String passwordHash;

    @Email(message = "邮箱格式不正确")
    private String email;
    
    // @NotNull(message = "年龄不能为空")
    private Integer age;
    
    // @NotNull(message = "性别不能为空")   
    private Gender gender;

    // @NotNull(message = "身高不能为空")
    private Integer heightCm;

    // @NotNull(message = "体重不能为空")
    private Float weightKg;

    // @NotNull(message = "活动水平不能为空")
    private ActivityLevel activityLevel;

    // @NotNull(message = "营养目标不能为空")
    private NutritionGoal nutritionGoal;

    private Float dailyCaloriesTarget;
    private Float dailyProteinTarget;
    private Float dailyCarbTarget;
    private Float dailyFatTarget;

    private String createdTime;
    

    @Override
    public String toString() {
        return "UserDto{" +
                "username='" + userName + '\'' +
                ", password='" + passwordHash + '\'' +
                ", email='" + email + '\'' +
                ", age=" + age +
                ", gender=" + gender +
                ", heightCm=" + heightCm +
                ", weightKg=" + weightKg +
                ", activityLevel=" + activityLevel +
                ", nutritionGoal=" + nutritionGoal +
                ", createdTime='" + createdTime + '\'' +
                '}';
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    public String getUserName() {
        return userName;
    }

    public void setUserName(String username) {
        this.userName = username;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String password) {
        this.passwordHash = password;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getCreatedTime() {
        return createdTime;
    }

    public void setCreatedTime(String createdTime) {
        this.createdTime = createdTime;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public Gender getGender() {
        return gender;
    }

    public void setGender(Gender gender) {
        this.gender = gender;
    }

    public Integer getHeightCm() {
        return heightCm;
    }

    public void setHeightCm(Integer heightCm) {
        this.heightCm = heightCm;
    }

    public Float getWeightKg() {
        return weightKg;
    }

    public void setWeightKg(Float weightKg) {
        this.weightKg = weightKg;
    }

    public ActivityLevel getActivityLevel() {
        return activityLevel;
    }

    public void setActivityLevel(ActivityLevel activityLevel) {
        this.activityLevel = activityLevel;
    }

    public NutritionGoal getNutritionGoal() {
        return nutritionGoal;
    }

    public void setNutritionGoal(NutritionGoal nutritionGoal) {
        this.nutritionGoal = nutritionGoal;
    }

    public Float getDailyCaloriesTarget() {
        return dailyCaloriesTarget;
    }

    public void setDailyCaloriesTarget(Float dailyCaloriesTarget) {
        this.dailyCaloriesTarget = dailyCaloriesTarget;
    }

    public Float getDailyProteinTarget() {
        return dailyProteinTarget;
    }

    public void setDailyProteinTarget(Float dailyProteinTarget) {
        this.dailyProteinTarget = dailyProteinTarget;
    }

    public Float getDailyCarbTarget() {
        return dailyCarbTarget;
    }

    public void setDailyCarbTarget(Float dailyCarbTarget) {
        this.dailyCarbTarget = dailyCarbTarget;
    }

    public Float getDailyFatTarget() {
        return dailyFatTarget;
    }

    public void setDailyFatTarget(Float dailyFatTarget) {
        this.dailyFatTarget = dailyFatTarget;
    }
}
