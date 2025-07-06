package org.user.pojo;

import org.user.enums.ActionTaken;
import org.user.enums.ScanType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Enumerated;
import jakarta.persistence.EnumType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Table(name = "scan_history")
@Entity
public class ScanHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="scan_id")
    private Integer scanId;

    @Column(name="user_id", nullable = false)
    private Integer userId;

    @Column(name="barcode", nullable = false)
    private String barcode;

    @Column(name="scan_time", columnDefinition = "DATETIME")
    private String scanTime;

    @Column(name="location")
    private String location;
    
    @Column(name="allergen_detected")
    private boolean allergenDetected;

    @Column(name="scan_result", columnDefinition = "LONGTEXT")
    private String scanResult;

    @Column(name="action_taken")
    @Enumerated(EnumType.STRING)
    private ActionTaken actionTaken;

    @Column(name="scan_type")
    @Enumerated(EnumType.STRING)
    private ScanType scanType;

    // store whole JSON response from recommendation service
    @Column(name="recommendation_response", columnDefinition = "LONGTEXT")
    private String recommendationResponse;

    @Column(name="created_at", columnDefinition = "TIMESTAMP")
    private LocalDateTime createdAt;

    @Override
    public String toString() {
        return "ScanHistory{" +
                "scanId=" + scanId +
                ", userId=" + userId +
                ", barcode='" + barcode + '\'' +
                ", scanTime='" + scanTime + '\'' +
                ", location='" + location + '\'' +
                ", allergenDetected=" + allergenDetected +
                ", scanResult='" + scanResult + '\'' +
                ", actionTaken=" + actionTaken +
                ", scanType=" + scanType +
                ", recommendationResponse='" + recommendationResponse + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }

    /**
     * @return Integer return the scanId
     */
    public Integer getScanId() {
        return scanId;
    }

    /**
     * @param scanId the scanId to set
     */
    public void setScanId(Integer scanId) {
        this.scanId = scanId;
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
     * @return String return the barcode
     */
    public String getBarcode() {
        return barcode;
    }

    /**
     * @param barcode the barcode to set
     */
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }

    /**
     * @return String return the scanTime
     */
    public String getScanTime() {
        return scanTime;
    }

    /**
     * @param scanTime the scanTime to set
     */
    public void setScanTime(String scanTime) {
        this.scanTime = scanTime;
    }

    /**
     * @return String return the location
     */
    public String getLocation() {
        return location;
    }

    /**
     * @param location the location to set
     */
    public void setLocation(String location) {
        this.location = location;
    }

    /**
     * @return boolean return the allergenDetected
     */
    public boolean isAllergenDetected() {
        return allergenDetected;
    }

    /**
     * @param allergenDetected the allergenDetected to set
     */
    public void setAllergenDetected(boolean allergenDetected) {
        this.allergenDetected = allergenDetected;
    }

    /**
     * @return String return the scanResult
     */
    public String getScanResult() {
        return scanResult;
    }

    /**
     * @param scanResult the scanResult to set
     */
    public void setScanResult(String scanResult) {
        this.scanResult = scanResult;
    }

    /**
     * @return ActionTaken return the actionTaken
     */
    public ActionTaken getActionTaken() {
        return actionTaken;
    }

    /**
     * @param actionTaken the actionTaken to set
     */
    public void setActionTaken(ActionTaken actionTaken) {
        this.actionTaken = actionTaken;
    }

    /**
     * @return ScanType return the scanType
     */
    public ScanType getScanType() {
        return scanType;
    }

    /**
     * @param scanType the scanType to set
     */
    public void setScanType(ScanType scanType) {
        this.scanType = scanType;
    }

    /**
     * @return String return the recommendationResponse
     */
    public String getRecommendationResponse() {
        return recommendationResponse;
    }

    /**
     * @param recommendationResponse the recommendationResponse to set
     */
    public void setRecommendationResponse(String recommendationResponse) {
        this.recommendationResponse = recommendationResponse;
    }

    /**
     * @return LocalDateTime return the createdAt
     */
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt the createdAt to set
     */
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

}
