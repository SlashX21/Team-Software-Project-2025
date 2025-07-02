package org.ocr.pojo.response;

public class BarcodeResponse {
    private String barcode;
    private String message;
    
    public BarcodeResponse() {}
    
    public BarcodeResponse(String barcode, String message) {
        this.barcode = barcode;
        this.message = message;
    }
    
    public String getBarcode() {
        return barcode;
    }
    
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
} 