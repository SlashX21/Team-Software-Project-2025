package org.user.pojo.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;

public class PurchaseItemDto {
    private Integer itemId;

    @NotNull(message = "purchase_id can not be null")
    private Integer purchaseId;

    @NotBlank(message = "barcode can not be null")
    private String barcode;

    // obtain from Product table
    private String productName;

    // obtain from Product table
    private String productBrand;

    private String itemNameOcr;

    @Min(value = 0, message = "match_confidence must be between 0 and 1")
    private Float matchConfidence;
    
    @Min(value = 1, message = "quantity must be greater than 0")
    private Integer quantity;

    @Min(value = 0, message = "unit_price must be greater than or equal to 0")
    private Float unitPrice;

    @Min(value = 0, message = "total_price must be greater than or equal to 0")
    private Float totalPrice;

    private Float estimatedServings;
    
    private Float totalCalories;

    private Float totalProteins;
    
    private Float totalCarbs;

    private Float totalFat;

    @Override
    public String toString() {
        return "PurchaseItemDto{" +
                "itemId=" + itemId +
                ", purchaseId=" + purchaseId +
                ", barcode='" + barcode + '\'' +
                ", productName='" + productName + '\'' +
                ", productBrand='" + productBrand + '\'' +
                ", itemNameOcr='" + itemNameOcr + '\'' +
                ", matchConfidence=" + matchConfidence +
                ", quantity=" + quantity +
                ", unitPrice=" + unitPrice +
                ", totalPrice=" + totalPrice +
                ", estimatedServings=" + estimatedServings +
                ", totalCalories=" + totalCalories +
                ", totalProteins=" + totalProteins +
                ", totalCarbs=" + totalCarbs +
                ", totalFat=" + totalFat +
                '}';
    }

    /**
     * @return Integer return the itemId
     */
    public Integer getItemId() {
        return itemId;
    }

    /**
     * @param itemId the itemId to set
     */
    public void setItemId(Integer itemId) {
        this.itemId = itemId;
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
     * @return String return the itemNameOcr
     */
    public String getItemNameOcr() {
        return itemNameOcr;
    }

    /**
     * @param itemNameOcr the itemNameOcr to set
     */
    public void setItemNameOcr(String itemNameOcr) {
        this.itemNameOcr = itemNameOcr;
    }

    /**
     * @return Float return the matchConfidence
     */
    public Float getMatchConfidence() {
        return matchConfidence;
    }

    /**
     * @param matchConfidence the matchConfidence to set
     */
    public void setMatchConfidence(Float matchConfidence) {
        this.matchConfidence = matchConfidence;
    }

    /**
     * @return Integer return the quantity
     */
    public Integer getQuantity() {
        return quantity;
    }

    /**
     * @param quantity the quantity to set
     */
    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    /**
     * @return Float return the unitPrice
     */
    public Float getUnitPrice() {
        return unitPrice;
    }

    /**
     * @param unitPrice the unitPrice to set
     */
    public void setUnitPrice(Float unitPrice) {
        this.unitPrice = unitPrice;
    }

    /**
     * @return Float return the totalPrice
     */
    public Float getTotalPrice() {
        return totalPrice;
    }

    /**
     * @param totalPrice the totalPrice to set
     */
    public void setTotalPrice(Float totalPrice) {
        this.totalPrice = totalPrice;
    }

    /**
     * @return Float return the estimatedServings
     */
    public Float getEstimatedServings() {
        return estimatedServings;
    }

    /**
     * @param estimatedServings the estimatedServings to set
     */
    public void setEstimatedServings(Float estimatedServings) {
        this.estimatedServings = estimatedServings;
    }

    /**
     * @return Float return the totalCalories
     */
    public Float getTotalCalories() {
        return totalCalories;
    }

    /**
     * @param totalCalories the totalCalories to set
     */
    public void setTotalCalories(Float totalCalories) {
        this.totalCalories = totalCalories;
    }

    /**
     * @return Float return the totalProteins
     */
    public Float getTotalProteins() {
        return totalProteins;
    }

    /**
     * @param totalProteins the totalProteins to set
     */
    public void setTotalProteins(Float totalProteins) {
        this.totalProteins = totalProteins;
    }

    /**
     * @return Float return the totalCarbs
     */
    public Float getTotalCarbs() {
        return totalCarbs;
    }

    /**
     * @param totalCarbs the totalCarbs to set
     */
    public void setTotalCarbs(Float totalCarbs) {
        this.totalCarbs = totalCarbs;
    }

    /**
     * @return Float return the totalFat
     */
    public Float getTotalFat() {
        return totalFat;
    }

    /**
     * @param totalFat the totalFat to set
     */
    public void setTotalFat(Float totalFat) {
        this.totalFat = totalFat;
    }
} 