package org.ocr.pojo.response;

import java.util.List;

public class ScanResponse {
    private List<Object> products;
    
    public ScanResponse() {}
    
    public ScanResponse(List<Object> products) {
        this.products = products;
    }
    
    public List<Object> getProducts() {
        return products;
    }
    
    public void setProducts(List<Object> products) {
        this.products = products;
    }
} 