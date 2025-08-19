package org.loyalty.pojo.response;

public class LoyaltyPointsResponse {
    private boolean success;
    private String message;
    private String transactionHash;
    private Integer points;
    private String barcode;
    
    public LoyaltyPointsResponse() {}
    
    public LoyaltyPointsResponse(boolean success, String message) {
        this.success = success;
        this.message = message;
    }
    
    public LoyaltyPointsResponse(boolean success, String message, String transactionHash) {
        this.success = success;
        this.message = message;
        this.transactionHash = transactionHash;
    }
    
    public LoyaltyPointsResponse(boolean success, String message, Integer points) {
        this.success = success;
        this.message = message;
        this.points = points;
    }
    
    public LoyaltyPointsResponse(boolean success, String message, String barcode, Integer pointsRedeemed) {
        this.success = success;
        this.message = message;
        this.barcode = barcode;
        this.points = pointsRedeemed;
    }
    
    public boolean isSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public String getTransactionHash() {
        return transactionHash;
    }
    
    public void setTransactionHash(String transactionHash) {
        this.transactionHash = transactionHash;
    }
    
    public Integer getPoints() {
        return points;
    }
    
    public void setPoints(Integer points) {
        this.points = points;
    }
    
    public String getBarcode() {
        return barcode;
    }
    
    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }
} 