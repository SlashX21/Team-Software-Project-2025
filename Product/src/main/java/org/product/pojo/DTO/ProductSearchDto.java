package org.product.pojo.DTO;

public class ProductSearchDto {
    private String barcode;
    private String productName;
    private String brand;
    private String category;
    private Float energyKcal100g;
    private Float sugars100g;
    private Double matchScore;
    private Float proteins100g;
    
    // constructors
    public ProductSearchDto() {}
    
    public ProductSearchDto(String barcode, String productName, String brand, String category, 
                           Float energyKcal100g, Float sugars100g, Float proteins100g, Double matchScore) {
        this.barcode = barcode;
        this.productName = productName;
        this.brand = brand;
        this.category = category;
        this.energyKcal100g = energyKcal100g;
        this.sugars100g = sugars100g;
        this.matchScore = matchScore;
        this.proteins100g = proteins100g;
    }
    
    // getters and setters
    public String getBarcode() {
        return barcode;
    }
    
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }
    
    public String getProductName() {
        return productName;
    }
    
    public void setProductName(String productName) {
        this.productName = productName;
    }
    
    public String getBrand() {
        return brand;
    }
    
    public void setBrand(String brand) {
        this.brand = brand;
    }
    
    public String getCategory() {
        return category;
    }
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    public Float getEnergyKcal100g() {
        return energyKcal100g;
    }
    
    public void setEnergyKcal100g(Float energyKcal100g) {
        this.energyKcal100g = energyKcal100g;
    }
    
    public Float getSugars100g() {
        return sugars100g;
    }
    
    public void setSugars100g(Float sugars100g) {
        this.sugars100g = sugars100g;
    }

    public Float getProteins100g() {
        return proteins100g;
    }
    
    public void setProteins100g(Float proteins100g) {
        this.proteins100g = proteins100g;
    }
    
    public Double getMatchScore() {
        return matchScore;
    }
    
    public void setMatchScore(Double matchScore) {
        this.matchScore = matchScore;
    }
    
    @Override
    public String toString() {
        return "ProductSearchDto{" +
                "barcode='" + barcode + '\'' +
                ", productName='" + productName + '\'' +
                ", brand='" + brand + '\'' +
                ", category='" + category + '\'' +
                ", energyKcal100g=" + energyKcal100g +
                ", sugars100g=" + sugars100g +
                ", proteins100g=" + proteins100g +
                ", matchScore=" + matchScore +
                '}';
    }
} 