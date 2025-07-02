package org.recommendation.controller;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.List;

@RestController
@RequestMapping("/recommendations")
public class RecommendationController {
    
    @Value("${recommendation.service.base-url:http://localhost:8001}")
    private String recommendationServiceBaseUrl;
    
    @Value("${recommendation.service.api-token:123456}")
    private String apiToken;
    
    private final RestTemplate restTemplate;
    
    public RecommendationController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }
    
    /**
     * 条码推荐接口 - 对应Python服务的POST /recommendations/barcode
     * 根据用户扫描的商品条码提供个性化推荐
     */
    @PostMapping("/barcode")
    public ResponseMessage<Map<String, Object>> getBarcodeRecommendation(@RequestBody BarcodeRecommendationRequest request) {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            if (apiToken != null && !apiToken.isEmpty()) {
                headers.setBearerAuth(apiToken);
            }
            
            // 构造请求体
            Map<String, Object> requestBody = Map.of(
                "userId", request.getUserId(),
                "productBarcode", request.getProductBarcode()
            );
            
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
            
            // 调用Python推荐服务的/recommendations/barcode接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                recommendationServiceBaseUrl + "/recommendations/barcode", 
                requestEntity, 
                Map.class
            );
            
            return ResponseMessage.success((Map<String, Object>) response.getBody());
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "调用条码推荐服务失败: " + e.getMessage(), null);
        }
    }
    
    /**
     * 小票分析推荐接口 - 对应Python服务的POST /recommendations/receipt
     * 分析用户购买的商品清单，提供营养分析和推荐建议
     */
    @PostMapping("/receipt")
    public ResponseMessage<Map<String, Object>> getReceiptAnalysis(@RequestBody ReceiptRecommendationRequest request) {
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            if (apiToken != null && !apiToken.isEmpty()) {
                headers.setBearerAuth(apiToken);
            }
            
            // 构造请求体
            Map<String, Object> requestBody = Map.of(
                "userId", request.getUserId(),
                "purchasedItems", request.getPurchasedItems()
            );
            
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
            
            // 调用Python推荐服务的/recommendations/receipt接口
            ResponseEntity<Map> response = restTemplate.postForEntity(
                recommendationServiceBaseUrl + "/recommendations/receipt", 
                requestEntity, 
                Map.class
            );
            
            return ResponseMessage.success((Map<String, Object>) response.getBody());
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "调用小票分析服务失败: " + e.getMessage(), null);
        }
    }
    
    /**
     * 推荐系统健康检查接口
     */
    @GetMapping("/health")
    public ResponseMessage<Map<String, Object>> health() {
        try {
            // 调用Python推荐服务的健康检查接口
            ResponseEntity<Map> response = restTemplate.getForEntity(
                recommendationServiceBaseUrl + "/health", 
                Map.class
            );
            
            return ResponseMessage.success((Map<String, Object>) response.getBody());
            
        } catch (Exception e) {
            return new ResponseMessage<>(503, "推荐服务不可用: " + e.getMessage(), null);
        }
    }
    
    /**
     * 条码推荐请求DTO
     */
    public static class BarcodeRecommendationRequest {
        private Integer userId;
        private String productBarcode;
        
        public Integer getUserId() {
            return userId;
        }
        
        public void setUserId(Integer userId) {
            this.userId = userId;
        }
        
        public String getProductBarcode() {
            return productBarcode;
        }
        
        public void setProductBarcode(String productBarcode) {
            this.productBarcode = productBarcode;
        }
    }
    
    /**
     * 小票分析请求DTO
     */
    public static class ReceiptRecommendationRequest {
        private Integer userId;
        private List<PurchasedItem> purchasedItems;
        
        public Integer getUserId() {
            return userId;
        }
        
        public void setUserId(Integer userId) {
            this.userId = userId;
        }
        
        public List<PurchasedItem> getPurchasedItems() {
            return purchasedItems;
        }
        
        public void setPurchasedItems(List<PurchasedItem> purchasedItems) {
            this.purchasedItems = purchasedItems;
        }
    }
    
    /**
     * 购买商品DTO
     */
    public static class PurchasedItem {
        private String barcode;
        private Integer quantity;
        
        public String getBarcode() {
            return barcode;
        }
        
        public void setBarcode(String barcode) {
            this.barcode = barcode;
        }
        
        public Integer getQuantity() {
            return quantity;
        }
        
        public void setQuantity(Integer quantity) {
            this.quantity = quantity;
        }
    }
}
