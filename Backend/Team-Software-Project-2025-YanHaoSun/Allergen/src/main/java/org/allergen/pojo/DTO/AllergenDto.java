package org.allergen.pojo.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class AllergenDto {
    private Integer id;

    @NotBlank(message = "过敏原名称不能为空")
    private String name;

    // @NotBlank(message = "过敏原分类不能为空")
    private String category;

    // @NotNull(message = "是否为常见过敏原不能为空")
    private boolean isCommon;

    // @NotBlank(message = "过敏原描述不能为空")
    private String description;

    private String createdTime;

    // private String severity;

    
    @Override
    public String toString() {
        return "UserDto{" +
                "Id ='" + id + '\'' +
                ", allergenname='" + name + '\'' +
                ", isCommon ='" + isCommon + '\'' +
                ", description ='" + description + '\'' +
                ", createdTime='" + createdTime + '\'' +
                '}';
    }

    /**
     * @return Integer return the id
     */
    public Integer getId() {
        return id;
    }

    /**
     * @param id the id to set
     */
    public void setId(Integer id) {
        this.id = id;
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

    // /**
    //  * @return String return the updatedTime
    //  */
    // public String getUpdatedTime() {
    //     return updatedTime;
    // }

    // /**
    //  * @param updatedTime the updatedTime to set
    //  */
    // public void setUpdatedTime(String updatedTime) {
    //     this.updatedTime = updatedTime;
    // }

    // /**
    //  * @return String return the severity
    //  */
    // public String getSeverity() {
    //     return severity;
    // }

    // /**
    //  * @param severity the severity to set
    //  */
    // public void setSeverity(String severity) {
    //     this.severity = severity;
    // }

}
