package org.recommendation.controller;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.recommendation.service.RecommendationService;

import java.util.Map;
import java.util.List;
import java.util.HashMap;

@RestController
@RequestMapping("/recommendations")
public class RecommendationController {
    
    private final RecommendationService recommendationService;
    
    @Autowired
    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }
    
    /**
     * 条码推荐接口 - 根据用户扫描的商品条码提供个性化推荐
     */
    @PostMapping("/barcode")
    public ResponseMessage<Map<String, Object>> getBarcodeRecommendation(@RequestBody BarcodeRecommendationRequest request) {
        return recommendationService.getBarcodeRecommendation(request.getUserId(), request.getProductBarcode());
    }
    
    /**
     * 小票分析推荐接口 - 分析用户购买的商品清单，提供营养分析和推荐建议
     */
    @PostMapping("/receipt")
    public ResponseMessage<Map<String, Object>> getReceiptAnalysis(@RequestBody ReceiptRecommendationRequest request) {
        // 转换 PurchasedItem 列表为 Map 列表
        List<Map<String, Object>> purchasedItems = request.getPurchasedItems().stream()
                .map(item -> {
                    Map<String, Object> itemMap = new HashMap<>();
                    itemMap.put("productName", item.getProductName());
                    itemMap.put("quantity", item.getQuantity());
                    return itemMap;
                })
                .toList();
        
        return recommendationService.getReceiptAnalysis(request.getUserId(), purchasedItems);
    }
    
    /**
     * 推荐系统健康检查接口
     */
    @GetMapping("/health")
    public ResponseMessage<Map<String, Object>> health() {
        return recommendationService.checkHealth();
    }
    
    /**
     * 测试条码推荐接口 - 用于验证功能
     */
    @PostMapping("/barcode/test")
    public ResponseMessage<Map<String, Object>> testBarcodeRecommendation() {
        // 创建测试响应数据
        Map<String, Object> testResponse = createTestRecommendationResponse();
        return ResponseMessage.success(testResponse);
    }
    
    /**
     * 创建测试推荐响应数据
     */
    private Map<String, Object> createTestRecommendationResponse() {
        Map<String, Object> response = new HashMap<>();
        
        response.put("recommendationId", "rec_20240628_0001");
        response.put("scanType", "barcode_scan");
        
        // 用户档案摘要
        Map<String, Object> userProfile = new HashMap<>();
        userProfile.put("userId", 1);
        userProfile.put("nutritionGoal", "lose_weight");
        userProfile.put("age", 25);
        userProfile.put("gender", "male");
        userProfile.put("allergensCount", 2);
        userProfile.put("dailyCaloriesTarget", 2000);
        userProfile.put("preferenceConfidence", 0.75);
        response.put("userProfileSummary", userProfile);
        
        // 推荐产品
        Map<String, Object> product = new HashMap<>();
        product.put("barCode", "1234567890");
        product.put("productName", "Healthier Alternative");
        product.put("brand", "Health Brand");
        product.put("category", "Beverages");
        product.put("energyKcal100g", 180);
        product.put("proteins100g", 8.5);
        product.put("fat100g", 2.1);
        product.put("sugars100g", 5.2);
        
        Map<String, Object> recommendation = new HashMap<>();
        recommendation.put("rank", 1);
        recommendation.put("product", product);
        recommendation.put("recommendationScore", 0.95);
        recommendation.put("reasoning", "Lower sugar content and higher protein make this a better choice for your weight loss goal.");
        
        response.put("recommendations", List.of(recommendation));
        
        // LLM 分析
        Map<String, Object> llmAnalysis = new HashMap<>();
        llmAnalysis.put("summary", "Found 3 healthier alternatives with lower sugar content");
        llmAnalysis.put("detailedAnalysis", "The original product contains 10.6g sugar per 100g...");
        llmAnalysis.put("actionSuggestions", List.of("Consider the top-ranked alternative", "Check nutrition labels"));
        response.put("llmAnalysis", llmAnalysis);
        
        // 处理元数据
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("algorithmVersion", "v1.0");
        metadata.put("processingTimeMs", 850);
        metadata.put("llmTokensUsed", 420);
        metadata.put("confidenceScore", 0.8);
        metadata.put("totalCandidates", 45);
        metadata.put("filteredCandidates", 5);
        response.put("processingMetadata", metadata);
        
        return response;
    }
    
    /**
     * 条码推荐请求 DTO
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
     * 小票分析推荐请求 DTO
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
     * 购买商品 DTO
     */
    public static class PurchasedItem {
        private String productName;
        private Integer quantity;

        public String getProductName() {
            return productName;
        }

        public void setProductName(String productName) {
            this.productName = productName;
        }

        public Integer getQuantity() {
            return quantity;
        }

        public void setQuantity(Integer quantity) {
            this.quantity = quantity;
        }
    }
}
