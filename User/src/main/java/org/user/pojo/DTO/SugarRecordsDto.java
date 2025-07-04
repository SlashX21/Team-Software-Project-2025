package org.user.pojo.DTO;

import org.user.enums.Source;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;

public class SugarRecordsDto {
    private Integer recordId;

    // @NotNull(message = "user_id can not be null")
    private Integer userId; 

    private String foodName;

    @JsonProperty("sugarAmount")
    @Min(value = 0, message = "sugar_amount_mg must be greater than or equal to 0")
    private Double sugarAmountMg;

    @Min(value = 0, message = "quantity must be greater than 0")
    private Double quantity;
    
    private String consumedAt;

    // @NotBlank(message = "product_barcode can not be null")
    private String productBarcode;

    // obtain from Product table
    private String productName;

    // obtain from Product table
    private String productBrand;

    private Source source; 
    
    private String notes; 

    private String createdAt; 

    @Override
    public String toString() {
        return "SugarRecordsDto{" +
                "recordId=" + recordId +
                ", userId=" + userId +
                ", foodName='" + foodName + '\'' +
                ", sugarAmountMg=" + sugarAmountMg +
                ", quantity=" + quantity +
                ", consumedAt='" + consumedAt + '\'' +
                ", productBarcode='" + productBarcode + '\'' +
                ", productName='" + productName + '\'' +
                ", productBrand='" + productBrand + '\'' +
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