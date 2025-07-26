package org.product.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Table(name = "product")
@Entity
public class Product {
    // @Id
    // @GeneratedValue(strategy = GenerationType.IDENTITY)
    // @Column(name="product_id")
    // private Integer productId;

    // "商品条码，全局唯一标识"
    @Id
    @Column(name="barcode")
    private String barCode;
    // "商品名称, OCR匹配用"
    @Column(name="name")
    private String productName;
    // "品牌"
    @Column(name="brand")
    private String brand;
    // "成分列表，过敏原检测源"
    @Column(name="ingredients", columnDefinition = "LONGTEXT")
    private String ingredients;
    // "过敏原信息，解析生成字典"
    @Column(name="allergens", columnDefinition = "LONGTEXT")
    private String allergens;
    // "能量值(焦耳)"
    @Column(name="energy_100g")
    private Float energy100g;
    // "热量(卡路里)，减脂目标核心"
    @Column(name="energy_kcal_100g")
    private Float energyKcal100g;

    @Column(name="fat_100g")
    private Float fat100g;
    // "饱和脂肪"
    @Column(name="saturated_fat_100g")
    private Float saturatedFat100g;
    // "碳水化合物"
    @Column(name="carbohydrates_100g")
    private Float carbohydrates100g;
    // "糖分含量"
    @Column(name="sugars_100g")
    private Float sugars100g;
    // "蛋白质含量，增肌目标优先"
    @Column(name="proteins_100g")
    private Float proteins100g;
    // "建议食用份量"
    @Column(name="serving_size")
    private String servingSize;

    // "商品类别，同类推荐关键"
    @Column(name="category")
    private String category ;

    
    @Override
    public String toString() {
        return "Product{" +
                "barCode='" + barCode + '\'' +
                ", productName='" + productName + '\'' +
                ", brand='" + brand + '\'' +
                ", ingredients='" + ingredients + '\'' +
                ", allergens='" + allergens + '\'' +
                ", energy100g=" + energy100g +
                ", energyKcal100g=" + energyKcal100g +
                ", fat100g=" + fat100g +
                ", saturatedFat100g=" + saturatedFat100g +
                ", carbohydrates100g=" + carbohydrates100g +
                ", sugars100g=" + sugars100g +
                ", proteins100g=" + proteins100g +
                ", servingSize='" + servingSize + '\'' +
                ", category='" + category + '\'' +
                '}';
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
     * @return String return the brand
     */
    public String getBrand() {
        return brand;
    }

    /**
     * @param brand the brand to set
     */
    public void setBrand(String brand) {
        this.brand = brand;
    }

    /**
     * @return String return the ingredients
     */
    public String getIngredients() {
        return ingredients;
    }

    /**
     * @param ingredients the ingredients to set
     */
    public void setIngredients(String ingredients) {
        this.ingredients = ingredients;
    }

    /**
     * @return String return the allergens
     */
    public String getAllergens() {
        return allergens;
    }

    /**
     * @param allergens the allergens to set
     */
    public void setAllergens(String allergens) {
        this.allergens = allergens;
    }

    /**
     * @return Float return the energy100g
     */
    public Float getEnergy100g() {
        return energy100g;
    }

    /**
     * @param energy100g the energy100g to set
     */
    public void setEnergy100g(Float energy100g) {
        this.energy100g = energy100g;
    }

    /**
     * @return Float return the energyKcal100g
     */
    public Float getEnergyKcal100g() {
        return energyKcal100g;
    }

    /**
     * @param energyKcal100g the energyKcal100g to set
     */
    public void setEnergyKcal100g(Float energyKcal100g) {
        this.energyKcal100g = energyKcal100g;
    }

    /**
     * @return Float return the fat100g
     */
    public Float getFat100g() {
        return fat100g;
    }

    /**
     * @param fat100g the fat100g to set
     */
    public void setFat100g(Float fat100g) {
        this.fat100g = fat100g;
    }

    /**
     * @return Float return the saturatedFat100g
     */
    public Float getSaturatedFat100g() {
        return saturatedFat100g;
    }

    /**
     * @param saturatedFat100g the saturatedFat100g to set
     */
    public void setSaturatedFat100g(Float saturatedFat100g) {
        this.saturatedFat100g = saturatedFat100g;
    }

    /**
     * @return Float return the carbohydrates100g
     */
    public Float getCarbohydrates100g() {
        return carbohydrates100g;
    }

    /**
     * @param carbohydrates100g the carbohydrates100g to set
     */
    public void setCarbohydrates100g(Float carbohydrates100g) {
        this.carbohydrates100g = carbohydrates100g;
    }

    /**
     * @return Float return the sugars100g
     */
    public Float getSugars100g() {
        return sugars100g;
    }

    /**
     * @param sugars100g the sugars100g to set
     */
    public void setSugars100g(Float sugars100g) {
        this.sugars100g = sugars100g;
    }

    /**
     * @return Float return the proteins100g
     */
    public Float getProteins100g() {
        return proteins100g;
    }

    /**
     * @param proteins100g the proteins100g to set
     */
    public void setProteins100g(Float proteins100g) {
        this.proteins100g = proteins100g;
    }

    /**
     * @return String return the servingSize
     */
    public String getServingSize() {
        return servingSize;
    }

    /**
     * @param servingSize the servingSize to set
     */
    public void setServingSize(String servingSize) {
        this.servingSize = servingSize;
    }

    /**
     * @return String return the category
     */
    public String getCategory() {
        return category;
    }

    /**
     * @param category the category to set
     */
    public void setCategory(String category) {
        this.category = category;
    }

}