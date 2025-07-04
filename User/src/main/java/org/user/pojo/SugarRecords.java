package org.user.pojo;

import org.user.enums.Source;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Table(name = "sugar_records")
@Entity
public class SugarRecords {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="record_id")
    private Integer recordId;

    @Column(name="user_id", nullable = false)
    private Integer userId; 

    @Column(name="food_name")
    private String foodName;

    @Column(name="sugar_amount_mg")
    private Double sugarAmountMg;

    @Column(name="quantity")
    private Double quantity;
    
    @Column(name="consumed_at", columnDefinition = "DATETIME")
    private String consumedAt;

    @Column(name="product_barcode", nullable = false)
    private String productBarcode;

    @Column(name="source")
    @Enumerated(EnumType.STRING)
    private Source source; 
    
    @Column(name="notes", columnDefinition = "LONGTEXT")
    private String notes; 

    @Column(name="created_at", columnDefinition = "DATETIME")
    private String createdAt; 

    @Override
    public String toString() {
        return "SugarRecords{" +
                "recordId=" + recordId +
                ", userId=" + userId +
                ", foodName='" + foodName + '\'' +
                ", sugarAmountMg=" + sugarAmountMg +
                ", quantity=" + quantity +
                ", consumedAt='" + consumedAt + '\'' +
                ", productBarcode='" + productBarcode + '\'' +
                ", source=" + source +
                ", notes='" + notes + '\'' +
                ", createdAt='" + createdAt + '\'' +
                '}';
    }

    

    /**
     * @return Integer return the recordId
     */
    public Integer getRecordId() {
        return recordId;
    }

    /**
     * @param recordId the recordId to set
     */
    public void setRecordId(Integer recordId) {
        this.recordId = recordId;
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
     * @return String return the foodName
     */
    public String getFoodName() {
        return foodName;
    }

    /**
     * @param foodName the foodName to set
     */
    public void setFoodName(String foodName) {
        this.foodName = foodName;
    }

    /**
     * @return Double return the sugarAmountMg
     */
    public Double getSugarAmountMg() {
        return sugarAmountMg;
    }

    /**
     * @param sugarAmountMg the sugarAmountMg to set
     */
    public void setSugarAmountMg(Double sugarAmountMg) {
        this.sugarAmountMg = sugarAmountMg;
    }

    /**
     * @return Double return the quantity
     */
    public Double getQuantity() {
        return quantity;
    }

    /**
     * @param quantity the quantity to set
     */
    public void setQuantity(Double quantity) {
        this.quantity = quantity;
    }

    /**
     * @return String return the consumedAt
     */
    public String getConsumedAt() {
        return consumedAt;
    }

    /**
     * @param consumedAt the consumedAt to set
     */
    public void setConsumedAt(String consumedAt) {
        this.consumedAt = consumedAt;
    }

    /**
     * @return String return the productBarcode
     */
    public String getProductBarcode() {
        return productBarcode;
    }

    /**
     * @param productBarcode the productBarcode to set
     */
    public void setProductBarcode(String productBarcode) {
        this.productBarcode = productBarcode;
    }

    /**
     * @return Source return the source
     */
    public Source getSource() {
        return source;
    }

    /**
     * @param source the source to set
     */
    public void setSource(Source source) {
        this.source = source;
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

    /**
     * @return String return the createdAt
     */
    public String getCreatedAt() {
        return createdAt;
    }

    /**
     * @param createdAt the createdAt to set
     */
    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

}
