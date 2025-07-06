package org.product.pojo.DTO;

import java.util.List;

public class PagedResponseDto<T> {
    private List<T> products;
    private Integer totalElements;
    
    // constructors
    public PagedResponseDto() {}
    
    public PagedResponseDto(List<T> products, Integer totalElements) {
        this.products = products;
        this.totalElements = totalElements;
    }
    
    // getters and setters
    public List<T> getProducts() {
        return products;
    }
    
    public void setProducts(List<T> products) {
        this.products = products;
    }
    
    public Integer getTotalElements() {
        return totalElements;
    }
    
    public void setTotalElements(Integer totalElements) {
        this.totalElements = totalElements;
    }
    
    @Override
    public String toString() {
        return "PagedResponseDto{" +
                "products=" + products +
                ", totalElements=" + totalElements +
                '}';
    }
} 