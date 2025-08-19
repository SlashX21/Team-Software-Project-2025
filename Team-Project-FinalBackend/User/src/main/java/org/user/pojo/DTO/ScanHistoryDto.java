package org.user.pojo.DTO;

import org.user.enums.ActionTaken;
import org.user.enums.ScanType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class ScanHistoryDto {
    private Integer scanId;

    @NotNull(message = "user_id can not be null")
    private Integer userId;

    @NotBlank(message = "barcode can not be null")
    private String barcode;

    // obtain from Product table
    private String productName;

    // obtain from Product table
    private String productBrand;

    private String scanTime;

    private String location;
    
    private boolean allergenDetected;

    // JSON string containing scan result data
    private String scanResult;

    private ActionTaken actionTaken;

    private ScanType scanType;

    // JSON response from recommendation service
    private String recommendationResponse;

    @Override
    public String toString() {
        return "ScanHistoryDto{" +
                "scanId=" + scanId +
                ", userId=" + userId +
                ", barcode='" + barcode + '\'' +
                ", productName='" + productName + '\'' +
                ", productBrand='" + productBrand + '\'' +
                ", scanTime='" + scanTime + '\'' +
                ", location='" + location + '\'' +
                ", allergenDetected=" + allergenDetected +
                ", scanResult='" + scanResult + '\'' +
                ", actionTaken=" + actionTaken +
                ", scanType=" + scanType +
                ", recommendationResponse='" + recommendationResponse + '\'' +
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
     * @return String return the productName
     */
    public String getProductName() {
        return productName;
    }

    /**
     * @param productName the productName to set
     */
    public void setProductName(String productName) {
        this.productName = productName;
    }

    /**
     * @return String return the productBrand
     */
    public String getProductBrand() {
        return productBrand;
    }

    /**
     * @param productBrand the productBrand to set
     */
    public void setProductBrand(String productBrand) {
        this.productBrand = productBrand;
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
} 