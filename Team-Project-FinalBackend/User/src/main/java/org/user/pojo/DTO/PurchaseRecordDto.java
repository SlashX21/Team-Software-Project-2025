package org.user.pojo.DTO;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;
import java.util.List;

public class PurchaseRecordDto {
    private Integer purchaseId;

    @NotNull(message = "user_id can not be null")
    private Integer userId;

    private String receiptDate;

    private String storeName;

    @Min(value = 0, message = "total_amount must be greater than or equal to 0")
    private Float totalAmount;
    
    @Min(value = 0, message = "ocr_confidence must be between 0 and 1")
    private Float ocrConfidence;

    // Raw OCR data from receipt scanning
    private String rawOcrData;

    private Integer scanId;

    // List of purchase items associated with this record
    private List<PurchaseItemDto> purchaseItems;

    @Override
    public String toString() {
        return "PurchaseRecordDto{" +
                "purchaseId=" + purchaseId +
                ", userId=" + userId +
                ", receiptDate='" + receiptDate + '\'' +
                ", storeName='" + storeName + '\'' +
                ", totalAmount=" + totalAmount +
                ", ocrConfidence=" + ocrConfidence +
                ", rawOcrData='" + rawOcrData + '\'' +
                ", scanId=" + scanId +
                ", purchaseItems=" + purchaseItems +
                '}';
    }

    /**
     * @return Integer return the purchaseId
     */
    public Integer getPurchaseId() {
        return purchaseId;
    }

    /**
     * @param purchaseId the purchaseId to set
     */
    public void setPurchaseId(Integer purchaseId) {
        this.purchaseId = purchaseId;
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
     * @return String return the receiptDate
     */
    public String getReceiptDate() {
        return receiptDate;
    }

    /**
     * @param receiptDate the receiptDate to set
     */
    public void setReceiptDate(String receiptDate) {
        this.receiptDate = receiptDate;
    }

    /**
     * @return String return the storeName
     */
    public String getStoreName() {
        return storeName;
    }

    /**
     * @param storeName the storeName to set
     */
    public void setStoreName(String storeName) {
        this.storeName = storeName;
    }

    /**
     * @return Float return the totalAmount
     */
    public Float getTotalAmount() {
        return totalAmount;
    }

    /**
     * @param totalAmount the totalAmount to set
     */
    public void setTotalAmount(Float totalAmount) {
        this.totalAmount = totalAmount;
    }

    /**
     * @return Float return the ocrConfidence
     */
    public Float getOcrConfidence() {
        return ocrConfidence;
    }

    /**
     * @param ocrConfidence the ocrConfidence to set
     */
    public void setOcrConfidence(Float ocrConfidence) {
        this.ocrConfidence = ocrConfidence;
    }

    /**
     * @return String return the rawOcrData
     */
    public String getRawOcrData() {
        return rawOcrData;
    }

    /**
     * @param rawOcrData the rawOcrData to set
     */
    public void setRawOcrData(String rawOcrData) {
        this.rawOcrData = rawOcrData;
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
     * @return List<PurchaseItemDto> return the purchaseItems
     */
    public List<PurchaseItemDto> getPurchaseItems() {
        return purchaseItems;
    }

    /**
     * @param purchaseItems the purchaseItems to set
     */
    public void setPurchaseItems(List<PurchaseItemDto> purchaseItems) {
        this.purchaseItems = purchaseItems;
    }
} 