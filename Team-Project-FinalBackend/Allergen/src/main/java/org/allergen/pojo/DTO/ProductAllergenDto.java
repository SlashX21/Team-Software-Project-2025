package org.allergen.pojo.DTO;

import org.allergen.enums.PresenceType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class ProductAllergenDto {
    private Integer productAllergenId;

    @NotBlank(message = "barcode can not be null")
    private String barcode;

    @NotNull(message = "allergen_id can not be null")
    private Integer allergenId;

    // obtain from Allergen table
    private String allergenName;

    // obtain from Allergen table
    private String allergenCategory;

    // obtain from Product table
    private String productName;

    @NotNull(message = "presence_type can not be null")
    private PresenceType presenceType;

    private Float confidenceScore;

    @Override
    public String toString() {
        return "ProductAllergenDto{" +
                "productAllergenId=" + productAllergenId +
                ", barcode='" + barcode + '\'' +
                ", allergenId=" + allergenId +
                ", allergenName='" + allergenName + '\'' +
                ", allergenCategory='" + allergenCategory + '\'' +
                ", productName='" + productName + '\'' +
                ", presenceType=" + presenceType +
                ", confidenceScore=" + confidenceScore +
                '}';
    }

    /**
     * @return Integer return the productAllergenId
     */
    public Integer getProductAllergenId() {
        return productAllergenId;
    }

    /**
     * @param productAllergenId the productAllergenId to set
     */
    public void setProductAllergenId(Integer productAllergenId) {
        this.productAllergenId = productAllergenId;
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
     * @return PresenceType return the presenceType
     */
    public PresenceType getPresenceType() {
        return presenceType;
    }

    /**
     * @param presenceType the presenceType to set
     */
    public void setPresenceType(PresenceType presenceType) {
        this.presenceType = presenceType;
    }

    /**
     * @return Float return the confidenceScore
     */
    public Float getConfidenceScore() {
        return confidenceScore;
    }

    /**
     * @param confidenceScore the confidenceScore to set
     */
    public void setConfidenceScore(Float confidenceScore) {
        this.confidenceScore = confidenceScore;
    }
} 