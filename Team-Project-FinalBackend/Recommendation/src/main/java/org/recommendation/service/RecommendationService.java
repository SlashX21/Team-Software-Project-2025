package org.recommendation.service;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.recommendation.pojo.RecommendationLog;
import org.recommendation.repository.RecommendationLogRepository;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.List;
import java.util.HashMap;

@Service
public class RecommendationService {
    
    @Value("${recommendation.service.base-url:http://localhost:8001}")
    private String recommendationServiceBaseUrl;
    
    @Value("${recommendation.service.api-token:123456}")
    private String apiToken;

    @Value("${product.service.base-url:http://localhost:8080/product}")
    private String productServiceBaseUrl;
    
    @Value("${loyalty.service.base-url:http://localhost:8005}")
    private String loyaltyServiceBaseUrl;
    
    private final RestTemplate restTemplate;
    private final RecommendationLogRepository recommendationLogRepository;
    private final ObjectMapper objectMapper;
    
    @Autowired
    public RecommendationService(RestTemplate restTemplate, 
                               RecommendationLogRepository recommendationLogRepository) {
        this.restTemplate = restTemplate;
        this.recommendationLogRepository = recommendationLogRepository;
        this.objectMapper = new ObjectMapper();
    }
    
    /**
     * obtain barcode recommendation
     * 
     * @param userId user id
     * @param productBarcode product barcode
     * @return recommendation response
     */
    public ResponseMessage<Object> getBarcodeRecommendation(Integer userId, String productBarcode) {
        long startTime = System.currentTimeMillis();
        RecommendationLog log = new RecommendationLog(userId, "barcode_scan");
        log.setRequestBarcode(productBarcode);
        
        try {
            // prepare request headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            if (apiToken != null && !apiToken.isEmpty()) {
                headers.setBearerAuth(apiToken);
            }
            
            // construct request body
            Map<String, Object> requestBody = Map.of(
                "userId", userId,
                "productBarcode", productBarcode
            );
            
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
            
            // call the Python recommendation service
            ResponseEntity<Map> response = restTemplate.postForEntity(
                recommendationServiceBaseUrl + "/recommendations/barcode", 
                requestEntity, 
                Map.class
            );
            
            // calculate processing time
            long processingTime = System.currentTimeMillis() - startTime;
            log.setProcessingTimeMs((int) processingTime);
            
            // process response data
            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null && responseBody.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) responseBody.get("data");
                
                // record recommendation results
                if (data.containsKey("recommendations")) {
                    try {
                        log.setRecommendedProducts(objectMapper.writeValueAsString(data.get("recommendations")));
                    } catch (JsonProcessingException e) {
                        log.setRecommendedProducts("{}");
                    }
                }
                
                // 记录LLM分析
                Object llm = data.get("llmInsights");
                if (llm == null && data.get("llmAnalysis") != null) {
                    llm = data.get("llmAnalysis");
                }
                if (llm != null) {
                    try {
                        log.setLlmAnalysis(objectMapper.writeValueAsString(llm));
                    } catch (JsonProcessingException e) {
                        log.setLlmAnalysis("{}");
                    }
                }
                
                // 记录处理元数据
                if (data.containsKey("processingMetadata")) {
                    Map<String, Object> metadata = (Map<String, Object>) data.get("processingMetadata");
                    if (metadata.containsKey("totalCandidates")) {
                        log.setTotalCandidates((Integer) metadata.get("totalCandidates"));
                    }
                    if (metadata.containsKey("filteredCandidates")) {
                        log.setFilteredCandidates((Integer) metadata.get("filteredCandidates"));
                    }
                }
                
                // 构造符合要求的响应格式
                Map<String, Object> formattedResponse = formatBarcodeRecommendationResponse(data);
                
                // 保存日志
                recommendationLogRepository.save(log);
                
                return ResponseMessage.success(formattedResponse);
            }
            
            return new ResponseMessage<Object>(500, "推荐服务返回数据格式错误", Map.of(
                "code", "RECOMMENDATION_ERROR",
                "message", "推荐服务返回数据格式错误",
                "details", Map.of(
                    "userId", userId,
                    "productBarcode", productBarcode,
                    "timestamp", LocalDateTime.now().toString()
                )
            ));
            
        } catch (Exception e) {
            log.setProcessingTimeMs((int) (System.currentTimeMillis() - startTime));
            log.setLlmAnalysis("Error: " + e.getMessage());
            recommendationLogRepository.save(log);
            
            return new ResponseMessage<Object>(500, "调用条码推荐服务失败: " + e.getMessage(), Map.of(
                "code", "RECOMMENDATION_ERROR",
                "message", e.getMessage(),
                "details", Map.of(
                    "userId", userId,
                    "productBarcode", productBarcode,
                    "timestamp", LocalDateTime.now().toString()
                )
            ));
        }
    }
    
    /**
     * 格式化条码推荐响应数据
     */
    private Map<String, Object> formatBarcodeRecommendationResponse(Map<String, Object> data) {
        Map<String, Object> response = new HashMap<>();
        
        response.put("success", true);
        response.put("message", "推荐成功");
        response.put("timestamp", LocalDateTime.now().toString());
        
        // 构造data部分
        Map<String, Object> responseData = new HashMap<>();
        responseData.put("recommendationId", data.getOrDefault("recommendationId", "rec_" + System.currentTimeMillis()));
        responseData.put("scanType", data.getOrDefault("scanType", "barcode_scan"));
        responseData.put("userProfileSummary", data.getOrDefault("userProfileSummary", new HashMap<>()));
        responseData.put("recommendations", data.getOrDefault("recommendations", List.of()));
        // Use llmInsights instead of llmAnalysis
        Object llm = data.get("llmInsights");
        if (llm == null && data.get("llmAnalysis") != null) {
            llm = data.get("llmAnalysis");
        }
        responseData.put("llmInsights", llm != null ? llm : new HashMap<>());
        responseData.put("processingMetadata", data.getOrDefault("processingMetadata", new HashMap<>()));
        
        response.put("data", responseData);
        
        return response;
    }
    
    /**
     * 获取小票分析推荐
     * This method now takes product names, looks up their barcodes, and then sends the barcodes to the Python service.
     */
    public ResponseMessage<Object> getReceiptAnalysis(Integer userId, List<Map<String, Object>> purchasedItems) {
        long startTime = System.currentTimeMillis();
        RecommendationLog log = new RecommendationLog(userId, "receipt_scan");
    
        LocalDateTime scanTime = LocalDateTime.now();

        try {
            // Step 1: Collect all product names
            List<String> productNames = purchasedItems.stream()
                .filter(item -> item.get("productName") != null && !((String)item.get("productName")).isEmpty())
                .map(item -> (String) item.get("productName"))
                .toList();

            // Step 1.5: Trigger fire-and-forget loyalty points awarding
            awardLoyaltyPointsForSustainableProducts(userId, productNames);

            // Step 2: Batch lookup barcodes
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            if (apiToken != null && !apiToken.isEmpty()) {
                headers.setBearerAuth(apiToken);
            }
            Map<String, Object> batchRequest = Map.of("names", productNames);
            HttpEntity<Map<String, Object>> batchEntity = new HttpEntity<>(batchRequest, headers);

            ResponseEntity<Map> batchResponse = restTemplate.postForEntity(
                productServiceBaseUrl + "/batch-lookup", batchEntity, Map.class);

            Map<String, String> nameToBarcode = new HashMap<>();
            if (batchResponse.getStatusCode() == HttpStatus.OK && batchResponse.getBody() != null) {
                Object resultsObj = batchResponse.getBody().get("results");
                if (resultsObj instanceof List<?> results) {
                    for (Object resultObj : results) {
                        if (resultObj instanceof Map<?,?> result) {
                            String name = (String) result.get("productName");
                            String barcode = (String) result.get("barcode");
                            if (name != null && barcode != null && !barcode.isEmpty()) {
                                nameToBarcode.put(name, barcode);
                            }
                        }
                    }
                }
            }

            // Step 3: Build itemsWithBarcodes (only include items with valid barcode)
            List<Map<String, Object>> itemsWithBarcodes = new java.util.ArrayList<>();
            for (Map<String, Object> item : purchasedItems) {
                Object barcodeObj = item.get("barcode");
                String barcode = barcodeObj != null ? String.valueOf(barcodeObj) : null;
                String productName = (String) item.get("productName");
                Integer quantity = (Integer) item.get("quantity");

                if (barcode != null && !barcode.isEmpty()) {
                    Map<String, Object> newItem = new HashMap<>();
                    newItem.put("barcode", barcode); // always string
                    newItem.put("quantity", quantity);
                    itemsWithBarcodes.add(newItem);
                } else if (productName != null && !productName.isEmpty()) {
                    String lookedUpBarcode = nameToBarcode.get(productName);
                    if (lookedUpBarcode != null && !lookedUpBarcode.isEmpty()) {
                        Map<String, Object> newItem = new HashMap<>();
                        newItem.put("barcode", lookedUpBarcode);
                        newItem.put("quantity", quantity);
                        itemsWithBarcodes.add(newItem);
                    }
                    // else: skip this item (do not send to Python)
                }
            }

            if (itemsWithBarcodes.isEmpty()) {
                return new ResponseMessage<Object>(404, "无法从小票商品中识别出任何有效产品", Map.of(
                    "code", "RECOMMENDATION_ERROR",
                    "message", "No valid products found in receipt",
                    "details", Map.of(
                        "userId", userId,
                        "timestamp", LocalDateTime.now().toString()
                    )
                ));
            }

            // Step 4: Call Python recommendation service with barcodes
            Map<String, Object> requestBody = Map.of(
                "userId", userId,
                "purchasedItems", itemsWithBarcodes
            );

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);

            ResponseEntity<Map> response = restTemplate.postForEntity(
                recommendationServiceBaseUrl + "/recommendations/receipt",
                requestEntity,
                Map.class
            );

            long processingTime = System.currentTimeMillis() - startTime;
            log.setProcessingTimeMs((int) processingTime);

            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null) {
                try {
                    System.out.println("objectMapper.writeValueAsString(responseBody): " + objectMapper.writeValueAsString(responseBody));
                    log.setRecommendedProducts(objectMapper.writeValueAsString(responseBody));
                } catch (JsonProcessingException e) {
                    log.setRecommendedProducts("{}");
                }
                recommendationLogRepository.save(log);
                
                // call User module to save receipt history
                try {
                    Map<String, Object> receiptHistoryRequest = new HashMap<>();
                    receiptHistoryRequest.put("userId", userId);
                    receiptHistoryRequest.put("scanTime", scanTime.toString());
                    
                    // save purchasedItems as JSON string
                    try {
                        receiptHistoryRequest.put("purchasedItems", objectMapper.writeValueAsString(purchasedItems));
                    } catch (JsonProcessingException e) {
                        receiptHistoryRequest.put("purchasedItems", "[]");
                    }
                    
                    // extract data from responseBody
                    if (responseBody.containsKey("data")) {
                        Map<String, Object> data = (Map<String, Object>) responseBody.get("data");
                        
                        // extract recommendationId
                        Object recommendationIdObj = data.get("recommendationId");
                        if (recommendationIdObj != null) {
                            receiptHistoryRequest.put("recommendationId", String.valueOf(recommendationIdObj));
                        }
                        
                        // extract llmInsights and save to llmSummary
                        Object llmInsightsObj = data.get("llmInsights");
                        if (llmInsightsObj != null) {
                            try {
                                receiptHistoryRequest.put("llmSummary", objectMapper.writeValueAsString(llmInsightsObj));
                            } catch (JsonProcessingException e) {
                                receiptHistoryRequest.put("llmSummary", String.valueOf(llmInsightsObj));
                            }
                        }
                        
                        // extract itemAnalyses and save to recommendationsList
                        Object itemAnalysesObj = data.get("itemAnalyses");
                        if (itemAnalysesObj != null) {
                            try {
                                receiptHistoryRequest.put("recommendationsList", objectMapper.writeValueAsString(itemAnalysesObj));
                            } catch (JsonProcessingException e) {
                                receiptHistoryRequest.put("recommendationsList", String.valueOf(itemAnalysesObj));
                            }
                        }
                    }
                    
                    // call User module's saveReceiptHistory interface
                    HttpHeaders historyHeaders = new HttpHeaders();
                    historyHeaders.setContentType(MediaType.APPLICATION_JSON);
                    HttpEntity<Map<String, Object>> historyEntity = new HttpEntity<>(receiptHistoryRequest, historyHeaders);
                    
                    ResponseEntity<Map> historyResponse = restTemplate.postForEntity(
                        "http://localhost:8080/user/receipt-history",
                        historyEntity,
                        Map.class
                    );
                    
                    if (historyResponse.getStatusCode() == HttpStatus.OK) {
                        System.out.println("Receipt history saved successfully");
                    } else {
                        System.err.println("Failed to save receipt history: " + historyResponse.getStatusCode());
                    }
                    
                } catch (Exception historyException) {
                    // record error but not affect main response
                    System.err.println("Error saving receipt history: " + historyException.getMessage());
                }
                
                // Ensure llmInsights field in response
                if (responseBody.containsKey("data")) {
                    Map<String, Object> data = (Map<String, Object>) responseBody.get("data");
                    Object llm = data.get("llmInsights");
                    if (llm == null && data.get("llmAnalysis") != null) {
                        data.put("llmInsights", data.get("llmAnalysis"));
                        data.remove("llmAnalysis");
                    }
                }
                return ResponseMessage.success(responseBody);
            }

            return new ResponseMessage<Object>(500, "推荐服务返回数据格式错误", Map.of(
                "code", "RECOMMENDATION_ERROR",
                "message", "推荐服务返回数据格式错误",
                "details", Map.of(
                    "userId", userId,
                    "timestamp", LocalDateTime.now().toString()
                )
            ));

        } catch (Exception e) {
            log.setProcessingTimeMs((int) (System.currentTimeMillis() - startTime));
            log.setLlmAnalysis("Error: " + e.getMessage());
            recommendationLogRepository.save(log);
            return new ResponseMessage<Object>(500, "调用小票分析服务失败: " + e.getMessage(),Map.of(
                "code", "RECOMMENDATION_ERROR",
                "message", e.getMessage(),
                "details", Map.of(
                    "userId", userId,
                    "timestamp", LocalDateTime.now().toString()
                )
            ));
        }
    }
    
    /**
     * 健康检查
     */
    public ResponseMessage<Object> checkHealth() {
        try {
            ResponseEntity<Map> response = restTemplate.getForEntity(
                recommendationServiceBaseUrl + "/health", 
                Map.class
            );
            
            return ResponseMessage.success((Map<String, Object>) response.getBody());
            
        } catch (Exception e) {
            return new ResponseMessage<Object>(503, "推荐服务不可用: " + e.getMessage(), null);
        }
    }
    
    /**
     * Fire-and-forget method to award loyalty points for sustainable products
     * This method runs asynchronously and doesn't affect the main response
     * 
     * @param userId user id
     * @param productNames list of product names from receipt
     */
    private void awardLoyaltyPointsForSustainableProducts(Integer userId, List<String> productNames) {
        // Run in a separate thread to avoid blocking the main response
        new Thread(() -> {
            try {
                System.out.println("🔄 Starting fire-and-forget loyalty points awarding for user " + userId);
                System.out.println("📦 Product names: " + productNames);
                
                // Step 1: Count sustainable products
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                
                Map<String, Object> countRequest = Map.of("names", productNames);
                HttpEntity<Map<String, Object>> countEntity = new HttpEntity<>(countRequest, headers);
                
                System.out.println("📊 Calling product service to count sustainable products...");
                ResponseEntity<Map> countResponse = restTemplate.postForEntity(
                    productServiceBaseUrl + "/count-sustainable",
                    countEntity,
                    Map.class
                );
                
                if (countResponse.getStatusCode() == HttpStatus.OK && countResponse.getBody() != null) {
                    Map<String, Object> countResult = countResponse.getBody();
                    Object sustainableCountObj = countResult.get("sustainableCount");
                    
                    System.out.println("📊 Count response: " + countResult);
                    
                    // Handle both Integer and Long types
                    Long sustainableCount = null;
                    if (sustainableCountObj instanceof Integer) {
                        sustainableCount = ((Integer) sustainableCountObj).longValue();
                    } else if (sustainableCountObj instanceof Long) {
                        sustainableCount = (Long) sustainableCountObj;
                    }
                    
                    System.out.println("🌱 Sustainable count: " + sustainableCount);
                    
                    // Step 2: Award loyalty points if there are sustainable products
                    if (sustainableCount != null && sustainableCount > 0) {
                        Map<String, Object> awardRequest = Map.of(
                            "user_id", userId.toString(),
                            "amount", sustainableCount.intValue()
                        );
                        HttpEntity<Map<String, Object>> awardEntity = new HttpEntity<>(awardRequest, headers);
                        
                        System.out.println("🎯 Calling loyalty service to award " + sustainableCount + " points...");
                        ResponseEntity<Map> awardResponse = restTemplate.postForEntity(
                            loyaltyServiceBaseUrl + "/award-points",
                            awardEntity,
                            Map.class
                        );
                        
                        if (awardResponse.getStatusCode() == HttpStatus.OK) {
                            System.out.println("✅ Loyalty points awarded successfully for " + sustainableCount + " sustainable products");
                            System.out.println("📋 Award response: " + awardResponse.getBody());
                        } else {
                            System.err.println("❌ Failed to award loyalty points: " + awardResponse.getStatusCode());
                            System.err.println("📋 Award response: " + awardResponse.getBody());
                        }
                    } else {
                        System.out.println("ℹ️ No sustainable products found, no points awarded");
                    }
                } else {
                    System.err.println("❌ Failed to count sustainable products: " + countResponse.getStatusCode());
                    System.err.println("📋 Count response: " + countResponse.getBody());
                }
                
            } catch (Exception e) {
                System.err.println("❌ Error in loyalty points awarding: " + e.getMessage());
            }
        }).start();
    }
} 