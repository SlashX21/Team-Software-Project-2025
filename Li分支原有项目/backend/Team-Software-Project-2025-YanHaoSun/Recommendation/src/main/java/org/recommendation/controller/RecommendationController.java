package org.recommendation.controller;

import org.common.dto.ApiResponse;
import org.common.exception.BusinessException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotBlank;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.List;

@RestController
@RequestMapping("/api/v1/recommendations")
@Tag(name = "推荐系统", description = "商品推荐和营养分析API")
@CrossOrigin(origins = "*")
public class RecommendationController {
    
    private static final Logger logger = LoggerFactory.getLogger(RecommendationController.class);
    
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
    @Operation(summary = "条码推荐", description = "根据用户扫描的商品条码提供个性化推荐")
    @ApiResponses(value = {
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "推荐成功"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "请求参数错误"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "503", description = "推荐服务不可用")
    })
    @PostMapping("/barcode")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getBarcodeRecommendation(
            @Parameter(description = "条码推荐请求") @Valid @RequestBody BarcodeRecommendationRequest request) {
        try {
            logger.info("Processing barcode recommendation for user: {} and barcode: {}", 
                request.getUserId(), request.getProductBarcode());
            
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
            
            ApiResponse<Map<String, Object>> apiResponse = ApiResponse.success(
                (Map<String, Object>) response.getBody(),
                "推荐生成成功"
            );
            
            return ResponseEntity.ok(apiResponse);
            
        } catch (Exception e) {
            logger.error("Failed to get barcode recommendation for user: {} and barcode: {}", 
                request.getUserId(), request.getProductBarcode(), e);
            
            throw new BusinessException(
                "RECOMMENDATION_SERVICE_ERROR",
                "调用条码推荐服务失败",
                e.getMessage(),
                HttpStatus.SERVICE_UNAVAILABLE
            );
        }
    }
    
    /**
     * 小票分析推荐接口 - 对应Python服务的POST /recommendations/receipt
     * 分析用户购买的商品清单，提供营养分析和推荐建议
     */
    @PostMapping("/receipt")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReceiptAnalysis(@RequestBody ReceiptRecommendationRequest request) {
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
            
            ApiResponse<Map<String, Object>> apiResponse = ApiResponse.success(
                (Map<String, Object>) response.getBody(),
                "小票分析成功"
            );
            
            return ResponseEntity.ok(apiResponse);
            
        } catch (Exception e) {
            throw new BusinessException(
                "RECEIPT_ANALYSIS_ERROR",
                "调用小票分析服务失败",
                e.getMessage(),
                HttpStatus.SERVICE_UNAVAILABLE
            );
        }
    }
    
    /**
     * 推荐系统健康检查接口
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> health() {
        try {
            // 调用Python推荐服务的健康检查接口
            ResponseEntity<Map> response = restTemplate.getForEntity(
                recommendationServiceBaseUrl + "/health", 
                Map.class
            );
            
            ApiResponse<Map<String, Object>> apiResponse = ApiResponse.success(
                (Map<String, Object>) response.getBody(),
                "推荐服务健康检查成功"
            );
            
            return ResponseEntity.ok(apiResponse);
            
        } catch (Exception e) {
            throw new BusinessException(
                "RECOMMENDATION_SERVICE_UNAVAILABLE",
                "推荐服务不可用",
                e.getMessage(),
                HttpStatus.SERVICE_UNAVAILABLE
            );
        }
    }
    
    /**
     * 条码推荐请求DTO
     */
    public static class BarcodeRecommendationRequest {
        @NotNull(message = "用户ID不能为空")
        @Parameter(description = "用户ID", example = "1", required = true)
        private Integer userId;
        
        @NotBlank(message = "商品条码不能为空")
        @Parameter(description = "商品条码", example = "1234567890", required = true)
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
