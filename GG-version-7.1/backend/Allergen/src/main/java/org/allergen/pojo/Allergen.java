package org.allergen.pojo;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "allergen")
public class Allergen {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="allergen_id")
    private Integer allergenId;

    @Column(name="name")
    private String name;

    @Column(name = "category")
    private String category;

    @Column(name = "is_common")
    private boolean isCommon;

    @Column(name="description")
    private String description;

    @Column(name="created_time")
    private String createdTime;

    // @Column(name="updated_time")
    // private String updatedTime;


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
     * @return String return the name
     */
    public String getName() {
        return name;
    }

    /**
     * @param name the name to set
     */
    public void setName(String name) {
        this.name = name;
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
     * @return boolean return the isCommon
     */
    public boolean isIsCommon() {
        return isCommon;
    }

    /**
     * @param isCommon the isCommon to set
     */
    public void setIsCommon(boolean isCommon) {
        this.isCommon = isCommon;
    }

    /**
     * @return String return the description
     */
    public String getDescription() {
        return description;
    }

    /**
     * @param description the description to set
     */
    public void setDescription(String description) {
        this.description = description;
    }

    /**
     * @return String return the createdTime
     */
    public String getCreatedTime() {
        return createdTime;
    }

    /**
     * @param createdTime the createdTime to set
     */
    public void setCreatedTime(String createdTime) {
        this.createdTime = createdTime;
    }

}
