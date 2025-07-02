package org.ocr.pojo.DTO;

import jakarta.validation.constraints.NotBlank;

public class BarcodeRequest {
    @NotBlank(message = "条码不能为空")
    private String barcode;
    
    public BarcodeRequest() {}
    
    public BarcodeRequest(String barcode) {
        this.barcode = barcode;
    }
    
    public String getBarcode() {
        return barcode;
    }
    
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }
} 