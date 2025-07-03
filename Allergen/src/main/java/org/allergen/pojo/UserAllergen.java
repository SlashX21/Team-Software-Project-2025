package org.allergen.pojo;

import org.allergen.enums.SeverityLevel;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "user_allergen")
public class UserAllergen {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="user_allergen_id")
    private Integer userAllergenId;

    @Column(name="user_id", nullable = false)
    private Integer userId;

    @Column(name = "allergen_id")
    private Integer allergenId;

    @Column(name = "severity_level")
    private SeverityLevel severityLevel;

    @Column(name = "confirmed")
    private boolean confirmed;

    @Column(name = "notes", columnDefinition = "LONGTEXT")
    private String notes;

    @Override
    public String toString() {
        return "UserAllergen{" +
                "userAllergenId=" + userAllergenId +
                ", userId=" + userId +
                ", allergenId=" + allergenId +
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
     * @return Integer return the severityLevel
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
