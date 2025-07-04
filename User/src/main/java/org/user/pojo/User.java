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

    @Column(name="username")
    private String userName;

    @Column(name="email", nullable = true)
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

    @Column(name="date_of_birth", columnDefinition = "DATE")
    private String date_of_birth;

    @Column(name="created_at", columnDefinition = "DATETIME")
    private String createdTime;

    @Column(name="updated_at", columnDefinition = "DATETIME")
    private String updatedTime;

    

    @Override
    public String toString() {
        return "User{" +
                "userId=" + userId +
                ", username='" + userName + '\'' +
                ", email='" + email + '\'' +
                ", passwordHash='" + passwordHash + '\'' +
                ", age=" + age +
                ", gender=" + gender +
                ", heightCm=" + heightCm +
                ", weightKg=" + weightKg +
                ", activityLevel=" + activityLevel +
                ", nutritionGoal=" + nutritionGoal +
                ", dailyCaloriesTarget=" + dailyCaloriesTarget +
                ", dailyProteinTarget=" + dailyProteinTarget +
                ", dailyCarbTarget=" + dailyCarbTarget +
                ", dailyFatTarget=" + dailyFatTarget +
                ", date_of_birth='" + date_of_birth + '\'' +
                ", createdTime='" + createdTime + '\'' +
                ", updatedTime='" + updatedTime + '\'' +
                '}';
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

    /**
     * @return String return the email
     */
    public String getEmail() {
        return email;
    }

    /**
     * @param email the email to set
     */
    public void setEmail(String email) {
        this.email = email;
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
     * @return Gender return the gender
     */
    public Gender getGender() {
        return gender;
    }

    /**
     * @param gender the gender to set
     */
    public void setGender(Gender gender) {
        this.gender = gender;
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
     * @return ActivityLevel return the activityLevel
     */
    public ActivityLevel getActivityLevel() {
        return activityLevel;
    }

    /**
     * @param activityLevel the activityLevel to set
     */
    public void setActivityLevel(ActivityLevel activityLevel) {
        this.activityLevel = activityLevel;
    }

    /**
     * @return NutritionGoal return the nutritionGoal
     */
    public NutritionGoal getNutritionGoal() {
        return nutritionGoal;
    }

    /**
     * @param nutritionGoal the nutritionGoal to set
     */
    public void setNutritionGoal(NutritionGoal nutritionGoal) {
        this.nutritionGoal = nutritionGoal;
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

    /**
     * @return String return the date_of_birth
     */
    public String getDate_of_birth() {
        return date_of_birth;
    }

    /**
     * @param date_of_birth the date_of_birth to set
     */
    public void setDate_of_birth(String date_of_birth) {
        this.date_of_birth = date_of_birth;
    }

    /**
     * @return String return the createdTime
     */
    public String getCreatedTime() {
        return createdTime;
    }

    /**
     * @param createdTime the createdTime to set
     */
    public void setCreatedTime(String createdTime) {
        this.createdTime = createdTime;
    }

    /**
     * @return String return the updatedTime
     */
    public String getUpdatedTime() {
        return updatedTime;
    }

    /**
     * @param updatedTime the updatedTime to set
     */
    public void setUpdatedTime(String updatedTime) {
        this.updatedTime = updatedTime;
    }

}
