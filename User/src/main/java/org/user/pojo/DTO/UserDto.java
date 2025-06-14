package org.user.pojo.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import org.hibernate.validator.constraints.Length;

import org.user.enums.Gender;


public class UserDto {
    private Integer userId;

    @NotBlank(message = "用户名不能为空") //可以去除空格
    private String userName;

    @NotBlank(message = "密码不能为空") //可以去除空格
    @Length(min = 6, max = 12)
    private String passwordHash;

    @Email(message = "邮箱格式不正确")
    private String email;
    
    @NotNull(message = "性别不能为空")
    private Gender gender;

    @NotNull(message = "身高不能为空")
    private Integer heightCm;

    @NotNull(message = "体重不能为空")
    private Float weightKg;

    private String createdTime;
    

    @Override
    public String toString() {
        return "UserDto{" +
                "username='" + userName + '\'' +
                ", password='" + passwordHash + '\'' +
                ", email='" + email + '\'' +
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
     * @return Float return the heightCm
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

}
