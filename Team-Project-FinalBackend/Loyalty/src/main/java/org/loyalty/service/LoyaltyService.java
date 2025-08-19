package org.loyalty.service;

import org.loyalty.pojo.DTO.LoyaltyPointsRequest;
import org.loyalty.pojo.DTO.CheckPointsRequest;
import org.loyalty.pojo.response.LoyaltyPointsResponse;
import org.loyalty.pojo.response.ContractInfoResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Service
public class LoyaltyService implements ILoyaltyService {
    
    @Value("${loyalty.service.base-url:http://localhost:8005}")
    private String loyaltyServiceBaseUrl;
    
    private final RestTemplate restTemplate = new RestTemplate();
    
    /**
     * Helper method to convert CheckPointsRequest to FastAPI format
     */
    private Map<String, Object> convertCheckPointsRequest(CheckPointsRequest request) {
        Map<String, Object> fastApiRequest = new HashMap<>();
        fastApiRequest.put("user_id", request.getUserId());
        return fastApiRequest;
    }
    
    /**
     * Helper method to convert LoyaltyPointsRequest to FastAPI format
     */
    private Map<String, Object> convertLoyaltyPointsRequest(LoyaltyPointsRequest request) {
        Map<String, Object> fastApiRequest = new HashMap<>();
        fastApiRequest.put("user_id", request.getUserId());
        fastApiRequest.put("amount", request.getAmount());
        return fastApiRequest;
    }
    
    @Override
    public LoyaltyPointsResponse awardPoints(LoyaltyPointsRequest request) {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            // Convert to FastAPI format
            Map<String, Object> fastApiRequest = convertLoyaltyPointsRequest(request);
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(fastApiRequest, headers);
            
            // 调用Python忠诚度服务的/award-points接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                loyaltyServiceBaseUrl + "/award-points", 
                requestEntity, 
                Map.class
            );
            
            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null) {
                // Safe casting with null checks
                Boolean success = responseBody.get("success") != null ? (Boolean) responseBody.get("success") : false;
                String message = responseBody.get("message") != null ? (String) responseBody.get("message") : "";
                String transactionHash = responseBody.get("transaction_hash") != null ? (String) responseBody.get("transaction_hash") : "";
                
                return new LoyaltyPointsResponse(success, message, transactionHash);
            }
            
            return new LoyaltyPointsResponse(false, "响应数据为空");
            
        } catch (Exception e) {
            return new LoyaltyPointsResponse(false, "调用积分奖励服务失败: " + e.getMessage());
        }
    }
    
    @Override
    public LoyaltyPointsResponse checkPoints(CheckPointsRequest request) {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            // Convert to FastAPI format - Flutter sends user_id, FastAPI expects user_id
            Map<String, Object> fastApiRequest = new HashMap<>();
            fastApiRequest.put("user_id", request.getUserId());
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(fastApiRequest, headers);
            
            // 调用Python忠诚度服务的/check-points接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                loyaltyServiceBaseUrl + "/check-points", 
                requestEntity, 
                Map.class
            );
            
            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null) {
                // FastAPI returns {"points": 0} - return exactly as FastAPI does
                Integer points = responseBody.get("points") != null ? (Integer) responseBody.get("points") : 0;
                
                // Return FastAPI format response, not Java wrapped format
                return new LoyaltyPointsResponse(true, "Points retrieved successfully", points);
            }
            
            return new LoyaltyPointsResponse(false, "响应数据为空");
            
        } catch (Exception e) {
            return new LoyaltyPointsResponse(false, "调用积分查询服务失败: " + e.getMessage());
        }
    }
    
    @Override
    public LoyaltyPointsResponse redeemPoints(CheckPointsRequest request) {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            // Convert to FastAPI format - Flutter sends user_id, FastAPI expects user_id
            Map<String, Object> fastApiRequest = new HashMap<>();
            fastApiRequest.put("user_id", request.getUserId());
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(fastApiRequest, headers);
            
            // 调用Python忠诚度服务的/redeem-points接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                loyaltyServiceBaseUrl + "/redeem-points", 
                requestEntity, 
                Map.class
            );
            
            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null) {
                // FastAPI returns {"barcode": "...", "points_redeemed": 0} - return exactly as FastAPI does
                String barcode = responseBody.get("barcode") != null ? (String) responseBody.get("barcode") : "";
                Integer pointsRedeemed = responseBody.get("points_redeemed") != null ? (Integer) responseBody.get("points_redeemed") : 0;
                
                // Return FastAPI format response, not Java wrapped format
                return new LoyaltyPointsResponse(true, "Points redeemed successfully", barcode, pointsRedeemed);
            }
            
            return new LoyaltyPointsResponse(false, "响应数据为空");
            
        } catch (Exception e) {
            return new LoyaltyPointsResponse(false, "调用积分兑换服务失败: " + e.getMessage());
        }
    }
    
    @Override
    public LoyaltyPointsResponse checkUserExists(CheckPointsRequest request) {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            // Convert to FastAPI format - Flutter sends user_id, FastAPI expects user_id
            Map<String, Object> fastApiRequest = new HashMap<>();
            fastApiRequest.put("user_id", request.getUserId());
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(fastApiRequest, headers);
            
            // 调用Python忠诚度服务的/user-exists接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                loyaltyServiceBaseUrl + "/user-exists", 
                requestEntity, 
                Map.class
            );
            
            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null) {
                // FastAPI returns {"user_id": "1001", "exists": false} - return exactly as FastAPI does
                Boolean exists = responseBody.get("exists") != null ? (Boolean) responseBody.get("exists") : false;
                
                // Return FastAPI format response, not Java wrapped format
                return new LoyaltyPointsResponse(exists, exists ? "User exists" : "User does not exist");
            }
            
            return new LoyaltyPointsResponse(false, "响应数据为空");
            
        } catch (Exception e) {
            return new LoyaltyPointsResponse(false, "调用用户检查服务失败: " + e.getMessage());
        }
    }
    
    @Override
    public ContractInfoResponse getContractInfo() {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            
            HttpEntity<String> requestEntity = new HttpEntity<>(headers);
            
            // 调用Python忠诚度服务的/contract-info接口
            ResponseEntity<Map> response = restTemplate.getForEntity(
                loyaltyServiceBaseUrl + "/contract-info", 
                Map.class
            );
            
            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null) {
                return new ContractInfoResponse(
                    (String) responseBody.get("contract_address"),
                    (String) responseBody.get("owner_address"),
                    (String) responseBody.get("network")
                );
            }
            
            return new ContractInfoResponse("", "", "");
            
        } catch (Exception e) {
            throw new RuntimeException("调用合约信息服务失败: " + e.getMessage(), e);
        }
    }
} 