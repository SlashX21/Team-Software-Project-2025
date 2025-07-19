package org.recommendation.pojo;

import java.util.List;

public class ReceiptRecommendationRequest {
    private Integer userId;
    private List<PurchasedItem> purchasedItems;

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }
    public List<PurchasedItem> getPurchasedItems() { return purchasedItems; }
    public void setPurchasedItems(List<PurchasedItem> purchasedItems) { this.purchasedItems = purchasedItems; }
} 