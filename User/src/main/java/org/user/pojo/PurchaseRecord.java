package org.user.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Table(name = "purchase_record")
@Entity
public class PurchaseRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="purchase_id")
    private Integer purchaseId;

    @Column(name="user_id", nullable = false)
    private Integer userId;

    @Column(name="receipt_date", columnDefinition = "DATE")
    private String receiptDate;

    @Column(name="store_name")
    private String storeName;

    @Column(name="total_amount")
    private Float totalAmount;
    
    @Column(name="ocr_confidence")
    private Float ocrConfidence;

    @Column(name="raw_ocr_data", columnDefinition = "LONGTEXT")
    private String rawOcrData;

    @Column(name="scan_id")
    private Integer scanId;

    @Override
    public String toString() {
        return "PurchaseRecord{" +
                "purchaseId=" + purchaseId +
                ", userId=" + userId +
                ", receiptDate='" + receiptDate + '\'' +
                ", storeName='" + storeName + '\'' +
                ", totalAmount=" + totalAmount +
                ", ocrConfidence=" + ocrConfidence +
                ", rawOcrData='" + rawOcrData + '\'' +
                ", scanId=" + scanId +
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

}
