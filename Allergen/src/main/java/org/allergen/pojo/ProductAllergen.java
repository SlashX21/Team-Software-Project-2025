package org.allergen.pojo;

import org.allergen.enums.PresenceType;
import org.allergen.enums.SeverityLevel;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "product_allergen")
public class ProductAllergen {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="product_allergen_id")
    private Integer productAllergenId;

    @Column(name="barcode", nullable = false)
    private String barCode;

    @Column(name = "allergen_id", nullable = false)
    private Integer allergenId;

    @Column(name = "presence_type")
    private PresenceType presenceType;

    @Column(name = "confidence_score")
    private Float confidenceScore;

    @Override
    public String toString() {
        return "ProductAllergen{" +
                "productAllergenId=" + productAllergenId +
                ", barCode='" + barCode + '\'' +
                ", allergenId=" + allergenId +
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
     * @return String return the barCode
     */
    public String getBarCode() {
        return barCode;
    }

    /**
     * @param barCode the barCode to set
     */
    public void setBarCode(String barCode) {
        this.barCode = barCode;
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
