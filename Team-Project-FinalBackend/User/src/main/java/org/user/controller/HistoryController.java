package org.user.controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.user.pojo.BarcodeHistory;
import org.user.pojo.DTO.ResponseMessage;
import org.user.pojo.ReceiptHistory;
import org.user.repository.BarcodeHistoryRepository;
import org.user.repository.ReceiptHistoryRepository;

@RestController
@RequestMapping("/api")
public class HistoryController {

    @Autowired
    BarcodeHistoryRepository barcodeHistoryRepository;
    @Autowired
    ReceiptHistoryRepository receiptHistoryRepository;
    @Autowired
    JdbcTemplate jdbcTemplate;
    
    /**
     * 获取扫描历史列表
     * GET /api/barcode-history
     */
    @GetMapping("/barcode-history")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getBarcodeHistory(
            @RequestParam Integer userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(required = false) String month) {
        
        try {
            // parameter validation
            if (userId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "userId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (page < 1) page = 1;
            if (limit < 1 || limit > 100) limit = 10;
            
            // create pageable
            Pageable pageable = PageRequest.of(page - 1, limit);
            
            // query barcode history
            Page<BarcodeHistory> historyPage;
            if (month != null && !month.isEmpty()) {
                // validate month format
                if (!month.matches("\\d{4}-\\d{2}")) {
                    ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                            400, "month format should be YYYY-MM", null);
                    return ResponseEntity.badRequest().body(errorResponse);
                }
                historyPage = barcodeHistoryRepository.findByUserIdAndMonthOrderByScanTimeDesc(userId, month, pageable);
            } else {
                historyPage = barcodeHistoryRepository.findByUserIdOrderByScanTimeDesc(userId, pageable);
            }
            
            // build response data
            List<Map<String, Object>> items = new ArrayList<>();
            for (BarcodeHistory history : historyPage.getContent()) {
                Map<String, Object> item = new HashMap<>();
                item.put("barcodeId", history.getBarcodeId());
                
                // query product information
                String productName = getProductNameByBarcode(history.getBarcode());
                item.put("productName", productName != null ? productName : "Unknown Product");
                item.put("scannedAt", history.getScanTime().toString());
                
                items.add(item);
            }
            
            // build pagination information
            Map<String, Object> pagination = new HashMap<>();
            pagination.put("currentPage", page);
            pagination.put("totalPages", historyPage.getTotalPages());
            pagination.put("totalItems", historyPage.getTotalElements());
            pagination.put("itemsPerPage", limit);
            pagination.put("hasNext", historyPage.hasNext());
            pagination.put("hasPrevious", historyPage.hasPrevious());
            
            // build complete response data, match API document format
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("items", items);
            responseData.put("pagination", pagination);
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    /**
     * query product name by barcode
     */
    private String getProductNameByBarcode(String barcode) {
        try {
            String sql = "SELECT name FROM product WHERE barcode = ?";
            return jdbcTemplate.queryForObject(sql, String.class, barcode);
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * get monthly barcode scan count
     * GET /api/barcode-history/monthly-count
     */
    @GetMapping("/barcode-history/monthly-count")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getMonthlyBarcodeCount(
            @RequestParam Integer userId,
            @RequestParam String month) {
        
        try {
            // parameter validation
            if (userId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "userId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (month == null || month.isEmpty()) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "month is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // validate month format (YYYY-MM)
            if (!month.matches("\\d{4}-\\d{2}")) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "month format should be YYYY-MM", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // query monthly scan count
            Long count = barcodeHistoryRepository.countBarcodeScansForUserAndMonth(userId, month);
            
            // build response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("count", count != null ? count.intValue() : 0);
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    /**
     * get monthly receipt upload count
     * GET /api/receipt-history/monthly-count
     */
    @GetMapping("/receipt-history/monthly-count")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getMonthlyReceiptCount(
            @RequestParam Integer userId,
            @RequestParam String month) {
        
        try {
            // parameter validation
            if (userId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "userId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (month == null || month.isEmpty()) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "month is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // validate month format (YYYY-MM)
            if (!month.matches("\\d{4}-\\d{2}")) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "month format should be YYYY-MM", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // query monthly receipt upload count
            Long count = receiptHistoryRepository.countReceiptUploadsForUserAndMonth(userId, month);
            
            // build response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("count", count != null ? count.intValue() : 0);
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * obtain product details by barcode id
     * GET /api/barcode-history/{barcodeId}/details
     */
    @GetMapping("/barcode-history/{barcodeId}/details")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getBarcodeHistoryDetails(
            @PathVariable Integer barcodeId,
            @RequestParam Integer userId) {
        
        try {
            // parameter validation
            if (barcodeId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "barcodeId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (userId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "userId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // query barcode history record
            BarcodeHistory barcodeHistory = barcodeHistoryRepository.findById(barcodeId).orElse(null);
            if (barcodeHistory == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        404, "Barcode history record not found", null);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            }
            
            // verify that the record belongs to the specified user
            if (!barcodeHistory.getUserId().equals(userId)) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        403, "Access denied: record does not belong to user", null);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
            }
            
            // query product detailed information
            Map<String, Object> productInfo = getProductDetailsByBarcode(barcodeHistory.getBarcode());
            
            // build response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("barcodeId", barcodeHistory.getBarcodeId());
            responseData.put("recommendationId", barcodeHistory.getRecommendationId() != null ? 
                    barcodeHistory.getRecommendationId() : "rec_" + System.currentTimeMillis() + "_001");
            responseData.put("productInfo", productInfo);
            responseData.put("aiAnalysis", parseAiAnalysis(barcodeHistory.getLlmAnalysis()));
            responseData.put("recommendations", parseRecommendations(barcodeHistory.getRecommendedProducts()));
            responseData.put("scannedAt", barcodeHistory.getScanTime().toString().replace(" ", "T") + "Z");
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    /**
     * query product details by barcode
     */
    private Map<String, Object> getProductDetailsByBarcode(String barcode) {
        try {
            String sql = "SELECT name, allergens, ingredients FROM product WHERE barcode = ?";
            Map<String, Object> productInfo = new HashMap<>();
            
            jdbcTemplate.query(sql, rs -> {
                productInfo.put("name", rs.getString("name") != null ? rs.getString("name") : "Unknown Product");
                
                // parse allergens
                String allergensStr = rs.getString("allergens");
                List<String> allergensList = new ArrayList<>();
                if (allergensStr != null && !allergensStr.trim().isEmpty() && !"None".equalsIgnoreCase(allergensStr)) {
                    // assume allergens are separated by commas
                    String[] allergens = allergensStr.split(",");
                    for (String allergen : allergens) {
                        allergensList.add(allergen.trim());
                    }
                }
                if (allergensList.isEmpty()) {
                    allergensList.add("None");
                }
                productInfo.put("allergens", allergensList);
                
                // parse ingredients
                String ingredients = rs.getString("ingredients");
                productInfo.put("ingredients", ingredients != null ? ingredients : "Information not available");
            }, barcode);
            
            // if no product found, return default information
            if (productInfo.isEmpty()) {
                productInfo.put("name", "Unknown Product");
                productInfo.put("allergens", List.of("None"));
                productInfo.put("ingredients", "Information not available");
            }
            
            return productInfo;
        } catch (Exception e) {
            // return default information if query fails
            Map<String, Object> defaultInfo = new HashMap<>();
            defaultInfo.put("name", "Unknown Product");
            defaultInfo.put("allergens", List.of("None"));
            defaultInfo.put("ingredients", "Information not available");
            return defaultInfo;
        }
    }
    
    /**
     * parse AI analysis data
     */
    private Map<String, Object> parseAiAnalysis(String llmAnalysis) {
        Map<String, Object> aiAnalysis = new HashMap<>();
        
        if (llmAnalysis != null && !llmAnalysis.trim().isEmpty()) {
            try {
                // try to parse JSON format
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                Map<String, Object> analysisData = mapper.readValue(llmAnalysis, Map.class);
                
                aiAnalysis.put("summary", analysisData.getOrDefault("summary", "Low-calorie carbonated beverage with artificial sweeteners"));
                aiAnalysis.put("detailedAnalysis", analysisData.getOrDefault("detailedAnalysis", "This product contains artificial sweeteners including aspartame..."));
                
                List<String> actionSuggestions = (List<String>) analysisData.get("actionSuggestions");
                if (actionSuggestions != null) {
                    aiAnalysis.put("actionSuggestions", actionSuggestions);
                } else {
                    aiAnalysis.put("actionSuggestions", List.of("Consider natural alternatives", "Limit daily consumption"));
                }
                
            } catch (Exception e) {
                // if parsing fails, use default analysis
                setDefaultAiAnalysis(aiAnalysis);
            }
        } else {
            setDefaultAiAnalysis(aiAnalysis);
        }
        
        return aiAnalysis;
    }
    
    /**
     * set default AI analysis
     */
    private void setDefaultAiAnalysis(Map<String, Object> aiAnalysis) {
        aiAnalysis.put("summary", "Low-calorie carbonated beverage with artificial sweeteners");
        aiAnalysis.put("detailedAnalysis", "This product contains artificial sweeteners including aspartame...");
        aiAnalysis.put("actionSuggestions", List.of("Consider natural alternatives", "Limit daily consumption"));
    }
    
    /**
     * parse recommendations data
     */
    private List<Map<String, Object>> parseRecommendations(String recommendedProducts) {
        List<Map<String, Object>> recommendations = new ArrayList<>();
        
        if (recommendedProducts != null && !recommendedProducts.trim().isEmpty()) {
            try {
                // try to parse JSON format
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                List<Map<String, Object>> productsList = mapper.readValue(recommendedProducts, List.class);
                
                for (int i = 0; i < productsList.size() && i < 3; i++) {
                    Map<String, Object> product = productsList.get(i);
                    Map<String, Object> recommendation = new HashMap<>();
                    recommendation.put("rank", i + 1);
                    
                    Map<String, Object> productData = new HashMap<>();
                    // productData.put("barCode", product.getOrDefault("barCode", "123456789" + String.format("%03d", i + 1)));
                    productData.put("productName", product.getOrDefault("productName", "Alternative Product " + (i + 1)));
                    // productData.put("brand", product.getOrDefault("brand", "Health Brand"));
                    // productData.put("category", product.getOrDefault("category", "Beverages"));
                    recommendation.put("product", productData);
                    
                    recommendation.put("recommendationScore", product.getOrDefault("recommendationScore", 0.9 - i * 0.05));
                    // recommendation.put("reasoning", product.getOrDefault("reasoning", "Natural alternative with no artificial sweeteners"));
                    // recommendation.put("productId", product.getOrDefault("productId", "123456789" + String.format("%03d", i + 1)));

                    productData.put("barCode", product.getOrDefault("barcode", "123456789" + String.format("%03d", i + 1)));
                    recommendation.put("reasoning", product.getOrDefault("summary", "Natural alternative with no artificial sweeteners"));

                    recommendations.add(recommendation);
                }
                
            } catch (Exception e) {
                // if parsing fails, use default recommendations
                setDefaultRecommendations(recommendations);
            }
        } else {
            setDefaultRecommendations(recommendations);
        }
        
        return recommendations;
    }
    
    /**
     * set default recommendations
     */
    private void setDefaultRecommendations(List<Map<String, Object>> recommendations) {
        Map<String, Object> defaultRecommendation = new HashMap<>();
        defaultRecommendation.put("rank", 1);
        
        Map<String, Object> product = new HashMap<>();
        product.put("barCode", "123456789123");
        product.put("productName", "Sparkling Water with Natural Flavors");
        product.put("brand", "San Pellegrino");
        product.put("category", "Beverages");
        defaultRecommendation.put("product", product);
        
        defaultRecommendation.put("recommendationScore", 0.92);
        defaultRecommendation.put("reasoning", "Natural alternative with no artificial sweeteners");
        
        recommendations.add(defaultRecommendation);
    }

    /**
     * obtain receipt history list
     * GET /api/receipt-history
     */
    @GetMapping("/receipt-history")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getReceiptHistory(
            @RequestParam Integer userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {
        
        try {
            // parameter validation
            if (userId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "userId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (page < 1) page = 1;
            if (limit < 1 || limit > 100) limit = 10;
            
            // create pageable
            Pageable pageable = PageRequest.of(page - 1, limit);
            
            // query receipt history
            Page<ReceiptHistory> historyPage = receiptHistoryRepository.findByUserIdOrderByScanTimeDesc(userId, pageable);
            
            // build response data
            List<Map<String, Object>> items = new ArrayList<>();
            for (ReceiptHistory history : historyPage.getContent()) {
                Map<String, Object> item = new HashMap<>();
                item.put("receiptId", history.getReceiptId());
                item.put("scanTime", history.getScanTime().toString().replace(" ", "T") + "Z");
                
                // parse purchased items to get display title and item count
                Map<String, Object> parsedItems = parsePurchasedItems(history.getPurchasedItems());
                item.put("displayTitle", parsedItems.get("displayTitle"));
                item.put("itemCount", parsedItems.get("itemCount"));
                
                // check if has recommendations
                boolean hasRecommendations = history.getRecommendationId() != null && 
                                           !history.getRecommendationId().trim().isEmpty();
                item.put("hasRecommendations", hasRecommendations);
                
                items.add(item);
            }
            
            // build pagination information
            Map<String, Object> pagination = new HashMap<>();
            pagination.put("currentPage", page);
            pagination.put("totalPages", historyPage.getTotalPages());
            pagination.put("totalItems", historyPage.getTotalElements());
            pagination.put("itemsPerPage", limit);
            pagination.put("hasNext", historyPage.hasNext());
            pagination.put("hasPrevious", historyPage.hasPrevious());
            
            // build complete response data, match API document format
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("data", items);
            responseData.put("pagination", pagination);
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    /**
     * parse purchased items JSON to extract display title and item count
     */
    private Map<String, Object> parsePurchasedItems(String purchasedItems) {
        Map<String, Object> result = new HashMap<>();
        result.put("displayTitle", "Unknown Receipt");
        result.put("itemCount", 0);
        
        if (purchasedItems == null || purchasedItems.trim().isEmpty()) {
            return result;
        }
        
        try {
            // try to parse JSON format
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            
            // assume purchased_items is an array of product objects
            List<Map<String, Object>> itemsList = mapper.readValue(purchasedItems, List.class);
            
            if (!itemsList.isEmpty()) {
                result.put("itemCount", itemsList.size());
                
                // extract first 3 product names for display title
                List<String> productNames = new ArrayList<>();
                for (int i = 0; i < Math.min(3, itemsList.size()); i++) {
                    Map<String, Object> item = itemsList.get(i);
                    String productName = (String) item.get("productName");
                    if (productName == null) {
                        productName = (String) item.get("name");
                    }
                    if (productName != null && !productName.trim().isEmpty()) {
                        productNames.add(productName.trim());
                    }
                }
                
                if (!productNames.isEmpty()) {
                    result.put("displayTitle", String.join(", ", productNames));
                } else {
                    result.put("displayTitle", "Receipt with " + itemsList.size() + " items");
                }
            }
            
        } catch (Exception e) {
            // if JSON parsing fails, try to extract simple text
            result.put("displayTitle", "Receipt uploaded");
            result.put("itemCount", 1);
        }
        
        return result;
    }

    /**
     * obtain receipt details
     * GET /api/receipt-history/{receiptId}/details
     */
    @GetMapping("/receipt-history/{receiptId}/details")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getReceiptHistoryDetails(
            @PathVariable Integer receiptId) {
        
        try {
            // parameter validation
            if (receiptId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "receiptId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // query receipt history record
            ReceiptHistory receiptHistory = receiptHistoryRepository.findById(receiptId).orElse(null);
            if (receiptHistory == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        404, "Receipt history record not found", null);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            }
            
            // build response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("success", true);
            
            Map<String, Object> data = new HashMap<>();
            data.put("receiptId", receiptHistory.getReceiptId());
            data.put("scanTime", receiptHistory.getScanTime().toString().replace(" ", "T") + "Z");
            data.put("recommendationId", receiptHistory.getRecommendationId() != null ? 
                    receiptHistory.getRecommendationId() : "rec_receipt_" + System.currentTimeMillis() + "_001");
            
            // parse purchased items
            data.put("purchasedItems", receiptHistory.getPurchasedItems());
            // data.put("purchasedItems", parsePurchasedItemsForDetails(receiptHistory.getPurchasedItems()));
            
            // parse LLM summary
            String llmSummary = receiptHistory.getLlmSummary();
            data.put("llmSummary", llmSummary != null && !llmSummary.trim().isEmpty() ? 
                    llmSummary : "This shopping trip focused on organic and healthy food choices...");
            
            // parse recommendations list
            data.put("recommendationsList", receiptHistory.getRecommendationsList());
            // data.put("recommendationsList", parseRecommendationsListForDetails(receiptHistory.getRecommendationsList()));
            
            // set analysis and recommendation flags
            data.put("hasLLMAnalysis", llmSummary != null && !llmSummary.trim().isEmpty());
            data.put("hasRecommendations", receiptHistory.getRecommendationId() != null && 
                    !receiptHistory.getRecommendationId().trim().isEmpty());
            
            responseData.put("data", data);
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    /**
     * parse purchased items for details view
     */
    private List<Map<String, Object>> parsePurchasedItemsForDetails(String purchasedItems) {
        List<Map<String, Object>> result = new ArrayList<>();
        
        if (purchasedItems == null || purchasedItems.trim().isEmpty()) {
            // return default item if no data
            Map<String, Object> defaultItem = new HashMap<>();
            defaultItem.put("productName", "Unknown Product");
            defaultItem.put("quantity", 1);
            result.add(defaultItem);
            return result;
        }
        
        try {
            // try to parse JSON format
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            List<Map<String, Object>> itemsList = mapper.readValue(purchasedItems, List.class);
            
            for (Map<String, Object> item : itemsList) {
                Map<String, Object> purchasedItem = new HashMap<>();
                
                // extract product name
                String productName = (String) item.get("productName");
                if (productName == null) {
                    productName = (String) item.get("name");
                }
                purchasedItem.put("productName", productName != null ? productName : "Unknown Product");
                
                // extract quantity
                Object quantityObj = item.get("quantity");
                Integer quantity = 1;
                if (quantityObj instanceof Number) {
                    quantity = ((Number) quantityObj).intValue();
                } else if (quantityObj instanceof String) {
                    try {
                        quantity = Integer.parseInt((String) quantityObj);
                    } catch (NumberFormatException e) {
                        quantity = 1;
                    }
                }
                purchasedItem.put("quantity", quantity);
                
                result.add(purchasedItem);
            }
            
        } catch (Exception e) {
            // if JSON parsing fails, return default item
            Map<String, Object> defaultItem = new HashMap<>();
            defaultItem.put("productName", "Receipt Items");
            defaultItem.put("quantity", 1);
            result.add(defaultItem);
        }
        
        return result;
    }
    
    /**
     * parse recommendations list for details view
     */
    private List<Map<String, Object>> parseRecommendationsListForDetails(String recommendationsList) {
        List<Map<String, Object>> result = new ArrayList<>();
        
        if (recommendationsList == null || recommendationsList.trim().isEmpty()) {
            return result;
        }
        
        try {
            // try to parse JSON format
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            List<Map<String, Object>> recsList = mapper.readValue(recommendationsList, List.class);
            
            for (Map<String, Object> rec : recsList) {
                Map<String, Object> recommendation = new HashMap<>();
                
                // parse original item
                Map<String, Object> originalItemData = (Map<String, Object>) rec.get("originalItem");
                if (originalItemData != null) {
                    Map<String, Object> originalItem = new HashMap<>();
                    originalItem.put("productName", originalItemData.getOrDefault("productName", "Unknown Product"));
                    originalItem.put("quantity", originalItemData.getOrDefault("quantity", 1));
                    recommendation.put("originalItem", originalItem);
                } else {
                    Map<String, Object> defaultOriginalItem = new HashMap<>();
                    defaultOriginalItem.put("productName", "originalItemData == null");
                    defaultOriginalItem.put("quantity", -1);
                    recommendation.put("originalItem", defaultOriginalItem);
                }
                
                // parse alternatives
                List<Map<String, Object>> alternativesData = (List<Map<String, Object>>) rec.get("alternatives");
                List<Map<String, Object>> alternatives = new ArrayList<>();
                
                if (alternativesData != null && !alternativesData.isEmpty()) {
                    for (Map<String, Object> altData : alternativesData) {
                        Map<String, Object> alternative = new HashMap<>();
                        alternative.put("rank", altData.getOrDefault("rank", 1));
                        
                        Map<String, Object> productData = (Map<String, Object>) altData.get("product");
                        if (productData != null) {
                            alternative.put("product", productData);
                        } else {
                            Map<String, Object> defaultProduct = new HashMap<>();
                            defaultProduct.put("barCode", "-1");
                            defaultProduct.put("productName", "none");
                            defaultProduct.put("brand", "none");
                            defaultProduct.put("category", "none");
                            alternative.put("product", defaultProduct);
                        }
                        
                        alternative.put("recommendationScore", altData.getOrDefault("recommendationScore", 0.9));
                        alternative.put("reasoning", altData.getOrDefault("reasoning", "Better alternative option"));
                        
                        alternatives.add(alternative);
                    }
                } else {
                    // add default alternative
                    Map<String, Object> defaultAlternative = new HashMap<>();
                    defaultAlternative.put("rank", 1);
                    
                    Map<String, Object> defaultProduct = new HashMap<>();
                    defaultProduct.put("barCode", "-1");
                    defaultProduct.put("productName", "alternativesData != null && !alternativesData.isEmpty()");
                    defaultProduct.put("brand", "alternativesData != null && !alternativesData.isEmpty()");
                    defaultProduct.put("category", "alternativesData != null && !alternativesData.isEmpty()");
                    defaultAlternative.put("product", defaultProduct);
                    
                    defaultAlternative.put("recommendationScore", -1);
                    defaultAlternative.put("reasoning", "alternativesData != null && !alternativesData.isEmpty()");
                    
                    alternatives.add(defaultAlternative);
                }
                
                recommendation.put("alternatives", alternatives);
                result.add(recommendation);
            }
            
        } catch (Exception e) {
            // if JSON parsing fails, return default recommendation
            Map<String, Object> defaultRecommendation = new HashMap<>();
            
            Map<String, Object> originalItem = new HashMap<>();
            originalItem.put("productName", "catch");
            originalItem.put("quantity", -1);
            defaultRecommendation.put("originalItem", originalItem);
            
            List<Map<String, Object>> alternatives = new ArrayList<>();
            Map<String, Object> alternative = new HashMap<>();
            alternative.put("rank", 1);
            
            Map<String, Object> product = new HashMap<>();
            product.put("barCode", "-1");
            product.put("productName", "catch");
            product.put("brand", "catch");
            product.put("category", "catch");
            alternative.put("product", product);
            
            alternative.put("recommendationScore", -1);
            alternative.put("reasoning", "catch");
            alternatives.add(alternative);
            
            defaultRecommendation.put("alternatives", alternatives);
            result.add(defaultRecommendation);
        }
        
        return result;
    }
} 