package org.loyalty.pojo.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Min;
import com.fasterxml.jackson.annotation.JsonProperty;

public class LoyaltyPointsRequest {
    @NotBlank(message = "用户ID不能为空")
    @JsonProperty("user_id")
    private String user_id;
    
    @Min(value = 1, message = "积分数量必须大于0")
    private Integer amount;
    
    public LoyaltyPointsRequest() {}
    
    public LoyaltyPointsRequest(String user_id, Integer amount) {
        this.user_id = user_id;
        this.amount = amount;
    }
    
    public String getUserId() {
        return user_id;
    }
    
    public void setUserId(String user_id) {
        this.user_id = user_id;
    }
    
    public Integer getAmount() {
        return amount;
    }
    
    public void setAmount(Integer amount) {
        this.amount = amount;
    }
} 