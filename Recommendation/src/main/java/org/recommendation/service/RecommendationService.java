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
    public ResponseMessage<Map<String, Object>> getBarcodeRecommendation(Integer userId, String productBarcode) {
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
                if (data.containsKey("llmAnalysis")) {
                    try {
                        log.setLlmAnalysis(objectMapper.writeValueAsString(data.get("llmAnalysis")));
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
            
            return new ResponseMessage<>(500, "推荐服务返回数据格式错误", null);
            
        } catch (Exception e) {
            log.setProcessingTimeMs((int) (System.currentTimeMillis() - startTime));
            log.setLlmAnalysis("Error: " + e.getMessage());
            recommendationLogRepository.save(log);
            
            return new ResponseMessage<>(500, "调用条码推荐服务失败: " + e.getMessage(), null);
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
        responseData.put("llmAnalysis", data.getOrDefault("llmAnalysis", new HashMap<>()));
        responseData.put("processingMetadata", data.getOrDefault("processingMetadata", new HashMap<>()));
        
        response.put("data", responseData);
        
        return response;
    }
    
    /**
     * 获取小票分析推荐
     */
    public ResponseMessage<Map<String, Object>> getReceiptAnalysis(Integer userId, List<Map<String, Object>> purchasedItems) {
        long startTime = System.currentTimeMillis();
        RecommendationLog log = new RecommendationLog(userId, "receipt_scan");
        
        try {
            // 准备请求头
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            if (apiToken != null && !apiToken.isEmpty()) {
                headers.setBearerAuth(apiToken);
            }
            
            // 构造请求体
            Map<String, Object> requestBody = Map.of(
                "userId", userId,
                "purchasedItems", purchasedItems
            );
            
            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestBody, headers);
            
            // 调用Python推荐服务
            ResponseEntity<Map> response = restTemplate.postForEntity(
                recommendationServiceBaseUrl + "/recommendations/receipt", 
                requestEntity, 
                Map.class
            );
            
            // 计算处理时间
            long processingTime = System.currentTimeMillis() - startTime;
            log.setProcessingTimeMs((int) processingTime);
            
            // 处理响应数据
            Map<String, Object> responseBody = response.getBody();
            if (responseBody != null) {
                // 记录推荐结果
                try {
                    log.setRecommendedProducts(objectMapper.writeValueAsString(responseBody));
                } catch (JsonProcessingException e) {
                    log.setRecommendedProducts("{}");
                }
                
                // 保存日志
                recommendationLogRepository.save(log);
                
                return ResponseMessage.success(responseBody);
            }
            
            return new ResponseMessage<>(500, "推荐服务返回数据格式错误", null);
            
        } catch (Exception e) {
            log.setProcessingTimeMs((int) (System.currentTimeMillis() - startTime));
            log.setLlmAnalysis("Error: " + e.getMessage());
            recommendationLogRepository.save(log);
            
            return new ResponseMessage<>(500, "调用小票分析服务失败: " + e.getMessage(), null);
        }
    }
    
    /**
     * 健康检查
     */
    public ResponseMessage<Map<String, Object>> checkHealth() {
        try {
            ResponseEntity<Map> response = restTemplate.getForEntity(
                recommendationServiceBaseUrl + "/health", 
                Map.class
            );
            
            return ResponseMessage.success((Map<String, Object>) response.getBody());
            
        } catch (Exception e) {
            return new ResponseMessage<>(503, "推荐服务不可用: " + e.getMessage(), null);
        }
    }
} 