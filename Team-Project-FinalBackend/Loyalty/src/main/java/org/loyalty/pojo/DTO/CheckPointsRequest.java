package org.loyalty.pojo.DTO;

import jakarta.validation.constraints.NotBlank;
import com.fasterxml.jackson.annotation.JsonProperty;

public class CheckPointsRequest {
    @NotBlank(message = "用户ID不能为空")
    @JsonProperty("user_id")
    private String user_id;
    
    public CheckPointsRequest() {}
    
    public CheckPointsRequest(String user_id) {
        this.user_id = user_id;
    }
    
    public String getUserId() {
        return user_id;
    }
    
    public void setUserId(String user_id) {
        this.user_id = user_id;
    }
} 