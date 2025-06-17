package org.user.pojo;

import org.user.enums.Gender;
import org.user.enums.ActivityLevel;
import org.user.enums.NutritionGoal;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

@Table(name = "user")
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="user_id")
    private Integer userId;

    @Column(name="user_name")
    private String userName;

    @Column(name="email")
    private String email;

    @Column(name="password_hash")
    private String passwordHash;

    @Column(name="age")
    private Integer age;

    @Column(name="gender")
    @Enumerated(EnumType.STRING)
    private Gender gender;

    @Column(name="height_cm")
    private Integer heightCm;

    @Column(name="weight_kg")
    private Float weightKg; 

    @Column(name="activity_level")
    @Enumerated(EnumType.STRING)
    private ActivityLevel activityLevel;

    @Column(name="nutrition_goal")
    @Enumerated(EnumType.STRING)
    private NutritionGoal nutritionGoal;

    @Column(name="daily_calories_target")
    private Float dailyCaloriesTarget;

    @Column(name="daily_protein_target")
    private Float dailyProteinTarget;

    @Column(name="daily_carb_target")
    private Float dailyCarbTarget;

    @Column(name="daily_fat_target")
    private Float dailyFatTarget;

    @Column(name="created_time")
    private String createdTime;

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

       /**
     * @return String return the userName
     */
    public String getUserName() {
        return userName;
    }

    /**
     * @param userName the userName to set
     */
    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getPassword() {
        return passwordHash;
    }

    public void setPassword(String passwordHash) {
        this.passwordHash = passwordHash;
    }


    public String getCreatedTime() {
        return createdTime;
    }

    public void setCreatedTime(String createdTime) {
        this.createdTime = createdTime;
    }

    public Gender getGender() {
        return gender;
    }

    public void setGender(Gender gender) {
        this.gender = gender;
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

    /**
     * @return String return the passwordHash
     */
    public String getPasswordHash() {
        return passwordHash;
    }

    /**
     * @param passwordHash the passwordHash to set
     */
    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    /**
     * @return Integer return the age
     */
    public Integer getAge() {
        return age;
    }

    /**
     * @param age the age to set
     */
    public void setAge(Integer age) {
        this.age = age;
    }

    /**
     * @return Integer return the heightCm
     */
    public Integer getHeightCm() {
        return heightCm;
    }

    /**
     * @param heightCm the heightCm to set
     */
    public void setHeightCm(Integer heightCm) {
        this.heightCm = heightCm;
    }

    /**
     * @return Float return the weightKg
     */
    public Float getWeightKg() {
        return weightKg;
    }

    /**
     * @param weightKg the weightKg to set
     */
    public void setWeightKg(Float weightKg) {
        this.weightKg = weightKg;
    }

    /**
     * @return Float return the dailyCaloriesTarget
     */
    public Float getDailyCaloriesTarget() {
        return dailyCaloriesTarget;
    }

    /**
     * @param dailyCaloriesTarget the dailyCaloriesTarget to set
     */
    public void setDailyCaloriesTarget(Float dailyCaloriesTarget) {
        this.dailyCaloriesTarget = dailyCaloriesTarget;
    }

    /**
     * @return Float return the dailyProteinTarget
     */
    public Float getDailyProteinTarget() {
        return dailyProteinTarget;
    }

    /**
     * @param dailyProteinTarget the dailyProteinTarget to set
     */
    public void setDailyProteinTarget(Float dailyProteinTarget) {
        this.dailyProteinTarget = dailyProteinTarget;
    }

    /**
     * @return Float return the dailyCarbTarget
     */
    public Float getDailyCarbTarget() {
        return dailyCarbTarget;
    }

    /**
     * @param dailyCarbTarget the dailyCarbTarget to set
     */
    public void setDailyCarbTarget(Float dailyCarbTarget) {
        this.dailyCarbTarget = dailyCarbTarget;
    }

    /**
     * @return Float return the dailyFatTarget
     */
    public Float getDailyFatTarget() {
        return dailyFatTarget;
    }

    /**
     * @param dailyFatTarget the dailyFatTarget to set
     */
    public void setDailyFatTarget(Float dailyFatTarget) {
        this.dailyFatTarget = dailyFatTarget;
    }


    @Override
    public String toString() {
        return "User{" +
                "userId=" + userId +
                ", username='" + userName + '\'' +
                ", passwordHash='" + passwordHash + '\'' +
                ", email='" + email + '\'' +
                ", gender=" + gender +
                ", activityLevel=" + activityLevel +
                ", nutritionGoal=" + nutritionGoal +
                ", createdTime='" + createdTime + '\'' +
                '}';
    }
}
