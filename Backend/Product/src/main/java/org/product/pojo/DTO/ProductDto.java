package org.product.pojo.DTO;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class ProductDto {
    @NotBlank(message = "Barcode cannot be empty")
    private String barCode;

    @NotBlank(message = "Product name cannot be empty")
    private String productName;
    
    // @NotBlank(message = "Brand cannot be empty")
    private String brand;

    // @NotBlank(message = "Ingredients cannot be empty")
    private String ingredients;

    // @NotBlank(message = "Allergens cannot be empty")
    private String allergens;

    // @NotNull(message = "Energy cannot be empty")
    private Float energy100g;

    // @NotNull(message = "Energy kcal cannot be empty")
    private Float energyKcal100g;

    // @NotBlank(message = "Fat cannot be empty")
    private Float fat100g;

    // @NotBlank(message = "Saturated fat cannot be empty")
    private Float saturatedFat100g;

    // @NotBlank(message = "Carbohydrates cannot be empty")
    private Float carbohydrates100g;

    // @NotBlank(message = "Sugars cannot be empty")
    private Float sugars100g;

    // @NotBlank(message = "Proteins cannot be empty")
    private Float proteins100g;

    // @NotBlank(message = "Serving size cannot be empty")
    private String servingSize;

    @NotBlank(message = "Category cannot be empty")
    private String category;

    // @NotBlank(message = "Created time cannot be empty")
    private String createdAt;

    // @NotBlank(message = "Updated time cannot be empty")
    private String updatedAt;
    

    @Override
    public String toString() {
        return "ProductDto{" +
                "barCode='" + barCode + '\'' +
                ", productName='" + productName + '\'' +
                ", brand='" + brand + '\'' +
                ", ingredients='" + ingredients + '\'' +
                ", allergens='" + allergens + '\'' +
                ", energy100g='" + energy100g + '\'' +
                ", energyKcal100g='" + energyKcal100g + '\'' +
                ", fat100g='" + fat100g + '\'' +
                ", saturatedFat100g='" + saturatedFat100g + '\'' +
                ", carbohydrates100g='" + carbohydrates100g + '\'' +
                ", sugars100g='" + sugars100g + '\'' +
                ", proteins100g='" + proteins100g + '\'' +
                ", servingSize='" + servingSize + '\'' +
                ", category='" + category + '\'' +
                ", createdAt='" + createdAt + '\'' +
                ", updatedAt='" + updatedAt + '\'' +
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

    /**
     * @return String return the updatedAt
     */
    public String getUpdatedAt() {
        return updatedAt;
    }

    /**
     * @param updatedAt the updatedAt to set
     */
    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }

}
