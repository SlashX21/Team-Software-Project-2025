package org.allergen.pojo.DTO;

import org.allergen.enums.SeverityLevel;
import jakarta.validation.constraints.NotNull;

public class UserAllergenDto {
    private Integer userAllergenId;

    @NotNull(message = "user_id can not be null")
    private Integer userId;

    @NotNull(message = "allergen_id can not be null")
    private Integer allergenId;

    // obtain from Allergen table
    private String allergenName;

    // obtain from Allergen table
    private String allergenCategory;

    @NotNull(message = "severity_level can not be null")
    private SeverityLevel severityLevel;

    private boolean confirmed;

    private String notes;

    @Override
    public String toString() {
        return "UserAllergenDto{" +
                "userAllergenId=" + userAllergenId +
                ", userId=" + userId +
                ", allergenId=" + allergenId +
                ", allergenName='" + allergenName + '\'' +
                ", allergenCategory='" + allergenCategory + '\'' +
                ", severityLevel=" + severityLevel +
                ", confirmed=" + confirmed +
                ", notes='" + notes + '\'' +
                '}';
    }

    /**
     * @return Integer return the userAllergenId
     */
    public Integer getUserAllergenId() {
        return userAllergenId;
    }

    /**
     * @param userAllergenId the userAllergenId to set
     */
    public void setUserAllergenId(Integer userAllergenId) {
        this.userAllergenId = userAllergenId;
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
     * @return Integer return the allergenId
     */
    public Integer getAllergenId() {
        return allergenId;
    }

    /**
     * @param allergenId the allergenId to set
     */
    public void setAllergenId(Integer allergenId) {
        this.allergenId = allergenId;
    }

    /**
     * @return String return the allergenName
     */
    public String getAllergenName() {
        return allergenName;
    }

    /**
     * @param allergenName the allergenName to set
     */
    public void setAllergenName(String allergenName) {
        this.allergenName = allergenName;
    }

    /**
     * @return String return the allergenCategory
     */
    public String getAllergenCategory() {
        return allergenCategory;
    }

    /**
     * @param allergenCategory the allergenCategory to set
     */
    public void setAllergenCategory(String allergenCategory) {
        this.allergenCategory = allergenCategory;
    }

    /**
     * @return SeverityLevel return the severityLevel
     */
    public SeverityLevel getSeverityLevel() {
        return severityLevel;
    }

    /**
     * @param severityLevel the severityLevel to set
     */
    public void setSeverityLevel(SeverityLevel severityLevel) {
        this.severityLevel = severityLevel;
    }

    /**
     * @return boolean return the confirmed
     */
    public boolean isConfirmed() {
        return confirmed;
    }

    /**
     * @param confirmed the confirmed to set
     */
    public void setConfirmed(boolean confirmed) {
        this.confirmed = confirmed;
    }

    /**
     * @return String return the notes
     */
    public String getNotes() {
        return notes;
    }

    /**
     * @param notes the notes to set
     */
    public void setNotes(String notes) {
        this.notes = notes;
    }
} 