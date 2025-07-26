package org.user.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Table(name = "purchase_item")
@Entity
public class PurchaseItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="item_id")
    private Integer itemId;

    @Column(name="purchase_id", nullable = false)
    private Integer purchaseId;

    @Column(name="barcode", nullable = false)
    private String barcode;

    @Column(name="item_name_ocr")
    private String itemNameOcr;

    @Column(name="match_confidence")
    private Float matchConfidence;
    
    @Column(name="quantity")
    private Integer quantity;

    @Column(name="unit_price")
    private Float unitPrice;

    @Column(name="total_price")
    private Float totalPrice;

    @Column(name="estimated_servings")
    private Float estimatedServings;
    
    @Column(name="total_calories")
    private Float totalCalories;


    @Column(name="total_proteins")
    private Float totalProteins;
    
    @Column(name="total_carbs")
    private Float totalCarbs;

    @Column(name="total_fat")
    private Float totalFat;
    
    @Override
    public String toString() {
        return "PurchaseItem{" +
                "itemId=" + itemId +
                ", purchaseId=" + purchaseId +
                ", barcode='" + barcode + '\'' +
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
