package org.user.controller;

// import org.demo.springboot_demo.pojo.DTO.ResponseMessage;
// import com.demo.springboot_demo.pojo.DTO.UserDto;
// import com.demo.springboot_demo.pojo.User;
// import com.demo.springboot_demo.service.IUserService;


import org.user.pojo.DTO.ResponseMessage;
import org.user.pojo.DTO.UserDto;
import org.user.pojo.User;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.user.service.IUserService;
import org.user.service.IUserHistoryService;
import org.user.service.ISugarTrackingService;
import org.user.pojo.DTO.UserHistoryResponseDto;
import org.user.pojo.DTO.UserHistoryListDto;
import org.user.pojo.DTO.SugarGoalResponseDto;
import org.user.pojo.DTO.SugarGoalRequestDto;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.user.service.IUserPreferenceService;
import org.user.pojo.DTO.UserPreferenceDto;
import org.user.enums.PreferenceSource;
import org.user.service.ISugarIntakeHistoryService;
import org.user.pojo.DTO.SugarIntakeHistoryDto;
import org.user.enums.SourceType;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.ZonedDateTime;
import java.time.format.DateTimeParseException;

import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;


@RestController //允许接口方法返回对象, 并且对象可以直接转换为json文本
@RequestMapping("/user") // 这样子前端就可以使用 localhost:8080/user/**来访问
public class UserController {
    @Autowired IUserService userService;
    @Autowired IUserHistoryService userHistoryService;
    @Autowired ISugarTrackingService sugarTrackingService;
    @Autowired IUserPreferenceService userPreferenceService;
    @Autowired ISugarIntakeHistoryService sugarIntakeHistoryService;

    // Register user
    @PostMapping // URL: localhost:8080/user/ method: post
    public ResponseMessage<User> add(@Validated @RequestBody UserDto user){
        System.out.println("Register user success");
        User userNew = userService.add(user);
        return ResponseMessage.success(userNew);
    }

    // Login user
    @PostMapping("/login") // URL: localhost:8080/user/login method: post
    public ResponseMessage<User> login(@Validated @RequestBody UserDto user){
        System.out.println("User login attempt for: " + user.getUserName());
        User userNew = userService.logIn(user);
        System.out.println("User login success for: " + user.getUserName());
        return ResponseMessage.success(userNew);
    }

    // query user
    @GetMapping("/{userId}") // URL: localhost:8080/user/1 method: get
    public ResponseMessage<User> get(@PathVariable Integer userId){
        User userNew = userService.getUser(userId);
        return ResponseMessage.success(userNew);
    }
    
    // edit user
    // put mapping
    @PutMapping // URL: localhost:8080/user/ method: put
    public ResponseMessage<User> edit(@Validated @RequestBody UserDto user){
        User userNew = userService.edit(user);
        return ResponseMessage.success(userNew);
    }

    // delete user
    @DeleteMapping("/{userId}") // URL: localhost:8080/user/1 method: delete
    public ResponseMessage<User> delete(@PathVariable Integer userId){
        userService.delete(userId);
        return ResponseMessage.success();
    }
    
    /**
     * Obtain specific user's all history records
     */
    @GetMapping("/{userId}/history")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getUserHistory(
            @PathVariable Integer userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String range) {
        
        try {
            // parameter validation
            if (page < 1) page = 1;
            if (limit < 1 || limit > 100) limit = 20;
            
            // get history records
            Page<UserHistoryListDto> historyPage = userHistoryService.getUserHistory(
                    userId, page, limit, search, type, range);
            
            // build response data
            Map<String, Object> data = new HashMap<>();
            data.put("items", historyPage.getContent());
            data.put("totalCount", historyPage.getTotalElements());
            data.put("currentPage", page);
            data.put("totalPages", historyPage.getTotalPages());
            data.put("hasMore", historyPage.hasNext());
            
            // build response
            ResponseMessage<Map<String, Object>> response = new ResponseMessage<>(200, "Success", data);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Obtain specific user's history record by historyId
     */
    @GetMapping("/{userId}/history/{historyId}")
    public ResponseEntity<ResponseMessage<UserHistoryResponseDto>> getUserHistoryById(
            @PathVariable Integer userId,
            @PathVariable String historyId) {
                UserHistoryResponseDto history;
        try{
            history = userHistoryService.getUserHistoryById(userId, historyId);
        }
        catch (Exception e){
            ResponseMessage<UserHistoryResponseDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
        return ResponseEntity.ok(ResponseMessage.success(history));
    }
    
    @DeleteMapping("/{userId}/history/{historyId}")
    public ResponseEntity<ResponseMessage<String>> deleteUserHistoryById(
            @PathVariable Integer userId,
            @PathVariable String historyId) {
        userHistoryService.deleteUserHistoryById(userId, historyId);
        return ResponseEntity.ok(ResponseMessage.success("History record deleted successfully!"));
    }

    /**
     * Get user history statistics
     */
    @GetMapping("/{userId}/history/statistics")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getUserHistoryStats(
            @PathVariable Integer userId,
            @RequestParam(defaultValue = "month") String period) {
        
        try {
            Map<String, Object> stats = userHistoryService.getUserHistoryStats(userId, period);
            ResponseMessage<Map<String, Object>> response = new ResponseMessage<>(200, "Success", stats);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * obtain scan history - new interface
     * GET /history?userId={userId}&page={page}&size={size}
     */
    @GetMapping("/history")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getScanHistory(
            @RequestParam Integer userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        try {
            // parameter validation
            if (page < 0) page = 1;
            if (size < 1 || size > 100) size = 20;
            
            // call service layer to get scan history
            Page<UserHistoryListDto> historyPage = userHistoryService.getUserHistory(
                    userId, page, size, null, null, null);
            
            // build response data structure, match the API specification provided
            Map<String, Object> responseData = new HashMap<>();
            
            // build content array
            java.util.List<Map<String, Object>> content = new java.util.ArrayList<>();
            for (UserHistoryListDto item : historyPage.getContent()) {
                Map<String, Object> historyItem = new HashMap<>();
                historyItem.put("scanId", item.getId().replace("hist_", "")); // remove hist_ prefix, only keep numbers
                historyItem.put("productName", item.getProductName());
                historyItem.put("brand", getBrandFromBarcode(item.getBarcode())); // extract brand from product name
                historyItem.put("barcode", item.getBarcode());
                historyItem.put("scanTime", item.getCreatedAt());
                historyItem.put("allergenDetected", item.getAllergenDetected() != null ? item.getAllergenDetected() : false);
                historyItem.put("actionTaken", item.getActionTaken() != null ? item.getActionTaken().name().toLowerCase() : "none");
                
                // build analysis object
                Map<String, Object> analysis = new HashMap<>();
                analysis.put("isHealthy", item.getHealthScore() != null && item.getHealthScore() > 60);
                analysis.put("sugarContent", item.getSummary() != null ? item.getSummary().getSugar() : "N/A");
                analysis.put("warnings", java.util.Arrays.asList("High sugar content")); // 根据实际分析结果设置
                
                historyItem.put("analysis", analysis);
                content.add(historyItem);
            }
            
            responseData.put("content", content);
            responseData.put("totalElements", historyPage.getTotalElements());
            responseData.put("totalPages", historyPage.getTotalPages());
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * save scan history record
     * POST /history
     */
    @PostMapping("/history")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> saveScanHistory(
            @RequestBody Map<String, Object> request) {
        
        try {
            // extract parameters from request body
            Integer userId = (Integer) request.get("userId");
            String barcode = (String) request.get("barcode");
            String scanTime = (String) request.get("scanTime");
            String location = (String) request.get("location");
            Boolean allergenDetected = (Boolean) request.get("allergenDetected");
            String actionTaken = (String) request.get("actionTaken");
            
            // parameter validation
            if (userId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "userId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (barcode == null || barcode.isEmpty()) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "barcode is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (scanTime == null || scanTime.isEmpty()) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "scanTime is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // save scan history record
            Integer scanId = userHistoryService.saveScanHistory(
                    userId, barcode, scanTime, location, allergenDetected, actionTaken);
            
            // build response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("scanId", scanId);
            responseData.put("message", "Scan history saved successfully");
            
            return ResponseEntity.ok(ResponseMessage.success(responseData));
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * get brand from barcode
     */
    private String getBrandFromBarcode(String barcode) {
        if (barcode == null || barcode.isEmpty()) {
            return "Unknown";
        }
        String brand = userHistoryService.getBrandFromBarcode(barcode);
        return brand!=null? brand: "Unknown";
    }

    /**
     * Get user allergens list
     * GET /user/{userId}/allergens
     */
    @GetMapping("/{userId}/allergens")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getUserAllergens(
            @PathVariable Integer userId) {
        
        try {
            // obtain user allergens list
            Map<String, Object> allergens = userService.getUserAllergens(userId);
            
            return ResponseEntity.ok(ResponseMessage.success(allergens));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    404, "User not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Add user allergen
     * POST /user/{userId}/allergens
     * If allergen already exists, returns existing allergen information
     */
    @PostMapping("/{userId}/allergens")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> addUserAllergen(
            @PathVariable Integer userId,
            @RequestBody Map<String, Object> request) {
        
        try {
            // extract request parameters
            Integer allergenId = (Integer) request.get("allergenId");
            String severityLevel = (String) request.get("severityLevel");
            String notes = (String) request.get("notes");
            
            // parameter validation
            if (allergenId == null) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "allergenId is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            if (severityLevel == null || severityLevel.isEmpty()) {
                ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                        400, "severityLevel is required", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            // add user allergen (or return existing if already exists)
            Map<String, Object> result = userService.addUserAllergen(userId, allergenId, severityLevel, notes);
            
            return ResponseEntity.ok(ResponseMessage.success(result));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    400, "Invalid request: " + e.getMessage(), null);
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Delete user allergen
     * DELETE /user/{userId}/allergens/{userAllergenId}
     */
    @DeleteMapping("/{userId}/allergens/{userAllergenId}")
    public ResponseEntity<ResponseMessage<String>> deleteUserAllergen(
            @PathVariable Integer userId,
            @PathVariable Integer userAllergenId) {
        
        try {
            // delete user allergen
            userService.deleteUserAllergen(userId, userAllergenId);
            
            return ResponseEntity.ok(ResponseMessage.success("User allergen deleted successfully"));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<String> errorResponse = new ResponseMessage<>(
                    404, "Not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<String> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * obtain user's sugar intake goal
     * GET /user/{userId}/sugar-tracking/goal
     */
    @GetMapping("/{userId}/sugar-tracking/goal")
    public ResponseEntity<ResponseMessage<SugarGoalResponseDto>> getUserSugarGoal(
            @PathVariable Integer userId) {
        
        try {
            SugarGoalResponseDto sugarGoal = sugarTrackingService.getUserSugarGoal(userId);
            ResponseMessage<SugarGoalResponseDto> response = new ResponseMessage<>(200, "Success", sugarGoal);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<SugarGoalResponseDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * set or update user's sugar intake goal
     * PUT /user/{userId}/sugar-tracking/goal
     */
    @PutMapping("/{userId}/sugar-tracking/goal")
    public ResponseEntity<ResponseMessage<SugarGoalResponseDto>> setUserSugarGoal(
            @PathVariable Integer userId,
            @Validated @RequestBody SugarGoalRequestDto goalRequestDto) {
        
        try {
            SugarGoalResponseDto updatedGoal = sugarTrackingService.setUserSugarGoal(userId, goalRequestDto);
            ResponseMessage<SugarGoalResponseDto> response = new ResponseMessage<>(200, "Sugar goal updated successfully", updatedGoal);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<SugarGoalResponseDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get user preferences
     * GET /user/{userId}/preferences
     */
    @GetMapping("/{userId}/preferences")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getUserPreferences(
            @PathVariable Integer userId) {
        
        try {
            Map<String, Object> preferences = userPreferenceService.getUserPreference(userId);
            return ResponseEntity.ok(ResponseMessage.success(preferences));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    404, "Not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Create or update user preferences
     * POST /user/{userId}/preferences
     */
    @PostMapping("/{userId}/preferences")
    public ResponseEntity<ResponseMessage<UserPreferenceDto>> saveUserPreferences(
            @PathVariable Integer userId,
            @RequestBody Map<String, Object> request) {
        
        try {
            UserPreferenceDto userPreferenceDto = new UserPreferenceDto();
            userPreferenceDto.setUserId(userId);
            
            // handle underscore and camel case
            userPreferenceDto.setPreferLowSugar(getBooleanValue(request, "prefer_low_sugar", "preferLowSugar"));
            userPreferenceDto.setPreferLowFat(getBooleanValue(request, "prefer_low_fat", "preferLowFat"));
            userPreferenceDto.setPreferHighProtein(getBooleanValue(request, "prefer_high_protein", "preferHighProtein"));
            userPreferenceDto.setPreferLowSodium(getBooleanValue(request, "prefer_low_sodium", "preferLowSodium"));
            userPreferenceDto.setPreferOrganic(getBooleanValue(request, "prefer_organic", "preferOrganic"));
            userPreferenceDto.setPreferLowCalorie(getBooleanValue(request, "prefer_low_calorie", "preferLowCalorie"));
            
            // handle preference source
            String sourceStr = getStringValue(request, "preference_source", "preferenceSource");
            if (sourceStr != null) {
                userPreferenceDto.setPreferenceSource(PreferenceSource.fromString(sourceStr));
            }
            
            UserPreferenceDto savedPreferences = userPreferenceService.saveOrUpdateUserPreference(userPreferenceDto);
            return ResponseEntity.ok(ResponseMessage.success(savedPreferences));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    400, "Invalid request: " + e.getMessage(), null);
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Update user preferences
     * PUT /user/{userId}/preferences
     */
    @PutMapping("/{userId}/preferences")
    public ResponseEntity<ResponseMessage<UserPreferenceDto>> updateUserPreferences(
            @PathVariable Integer userId,
            @RequestBody Map<String, Object> request) {
        
        try {
            UserPreferenceDto userPreferenceDto = new UserPreferenceDto();
            userPreferenceDto.setUserId(userId);
            
            // handle underscore and camel case
            userPreferenceDto.setPreferLowSugar(getBooleanValue(request, "prefer_low_sugar", "preferLowSugar"));
            userPreferenceDto.setPreferLowFat(getBooleanValue(request, "prefer_low_fat", "preferLowFat"));
            userPreferenceDto.setPreferHighProtein(getBooleanValue(request, "prefer_high_protein", "preferHighProtein"));
            userPreferenceDto.setPreferLowSodium(getBooleanValue(request, "prefer_low_sodium", "preferLowSodium"));
            userPreferenceDto.setPreferOrganic(getBooleanValue(request, "prefer_organic", "preferOrganic"));
            userPreferenceDto.setPreferLowCalorie(getBooleanValue(request, "prefer_low_calorie", "preferLowCalorie"));
            
            // handle preference source
            String sourceStr = getStringValue(request, "preference_source", "preferenceSource");
            if (sourceStr != null) {
                userPreferenceDto.setPreferenceSource(PreferenceSource.fromString(sourceStr));
            }
            
            UserPreferenceDto updatedPreferences = userPreferenceService.saveOrUpdateUserPreference(userPreferenceDto);
            return ResponseEntity.ok(ResponseMessage.success(updatedPreferences));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    400, "Invalid request: " + e.getMessage(), null);
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Delete user preferences
     * DELETE /user/{userId}/preferences
     */
    @DeleteMapping("/{userId}/preferences")
    public ResponseEntity<ResponseMessage<String>> deleteUserPreferences(
            @PathVariable Integer userId) {
        
        try {
            userPreferenceService.deleteUserPreference(userId);
            return ResponseEntity.ok(ResponseMessage.success("User preferences deleted successfully"));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<String> errorResponse = new ResponseMessage<>(
                    404, "Not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<String> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Update single preference field
     * PATCH /user/{userId}/preferences/{preferenceType}
     */
    @PatchMapping("/{userId}/preferences/{preferenceType}")
    public ResponseEntity<ResponseMessage<UserPreferenceDto>> updatePreferenceField(
            @PathVariable Integer userId,
            @PathVariable String preferenceType,
            @RequestBody Map<String, Boolean> request) {
        
        try {
            Boolean value = request.get("value");
            if (value == null) {
                ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                        400, "Missing 'value' field in request body", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            
            UserPreferenceDto updatedPreferences = userPreferenceService.updatePreferenceField(userId, preferenceType, value);
            return ResponseEntity.ok(ResponseMessage.success(updatedPreferences));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    400, "Invalid request: " + e.getMessage(), null);
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get user preference statistics
     * GET /user/{userId}/preferences/stats
     */
    @GetMapping("/{userId}/preferences/stats")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getUserPreferenceStats(
            @PathVariable Integer userId) {
        
        try {
            Map<String, Object> stats = userPreferenceService.getUserPreferenceStats(userId);
            return ResponseEntity.ok(ResponseMessage.success(stats));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    404, "Not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Generate preferences from user behavior
     * POST /user/{userId}/preferences/generate
     */
    @PostMapping("/{userId}/preferences/generate")
    public ResponseEntity<ResponseMessage<UserPreferenceDto>> generateUserPreferences(
            @PathVariable Integer userId) {
        
        try {
            UserPreferenceDto generatedPreferences = userPreferenceService.generatePreferenceFromBehavior(userId);
            return ResponseEntity.ok(ResponseMessage.success(generatedPreferences));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    404, "Not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Reset user preferences to default
     * POST /user/{userId}/preferences/reset
     */
    @PostMapping("/{userId}/preferences/reset")
    public ResponseEntity<ResponseMessage<UserPreferenceDto>> resetUserPreferences(
            @PathVariable Integer userId) {
        
        try {
            UserPreferenceDto resetPreferences = userPreferenceService.resetUserPreference(userId);
            return ResponseEntity.ok(ResponseMessage.success(resetPreferences));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    404, "Not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Export user preference data
     * GET /user/{userId}/preferences/export
     */
    @GetMapping("/{userId}/preferences/export")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> exportUserPreferenceData(
            @PathVariable Integer userId) {
        
        try {
            Map<String, Object> exportData = userPreferenceService.exportUserPreferenceData(userId);
            return ResponseEntity.ok(ResponseMessage.success(exportData));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    404, "Not found: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Import user preference data
     * POST /user/{userId}/preferences/import
     */
    @PostMapping("/{userId}/preferences/import")
    public ResponseEntity<ResponseMessage<UserPreferenceDto>> importUserPreferenceData(
            @PathVariable Integer userId,
            @RequestBody Map<String, Object> preferenceData) {
        
        try {
            UserPreferenceDto importedPreferences = userPreferenceService.importUserPreferenceData(userId, preferenceData);
            return ResponseEntity.ok(ResponseMessage.success(importedPreferences));
            
        } catch (IllegalArgumentException e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    400, "Invalid request: " + e.getMessage(), null);
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            ResponseMessage<UserPreferenceDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    /**
     * helper method: get boolean value from map, support underscore and camel case
     */
    private Boolean getBooleanValue(Map<String, Object> request, String underscoreKey, String camelKey) {
        Object value = request.get(underscoreKey);
        if (value == null) {
            value = request.get(camelKey);
        }
        return value != null ? (Boolean) value : false;
    }
    
    /**
     * helper method: get string value from map, support underscore and camel case
     */
    private String getStringValue(Map<String, Object> request, String underscoreKey, String camelKey) {
        Object value = request.get(underscoreKey);
        if (value == null) {
            value = request.get(camelKey);
        }
        return value != null ? (String) value : null;
    }

    /**
     * add sugar intake record
     * POST /user/{userId}/sugar-tracking/record
     */
    @PostMapping("/{userId}/sugar-tracking/record")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> addSugarRecord(
            @PathVariable Integer userId,
            @RequestBody Map<String, Object> requestBody) {
        
        try {
            // create dto object
            SugarIntakeHistoryDto dto = new SugarIntakeHistoryDto();
            dto.setUserId(userId);
            
            // map fields
            if (requestBody.containsKey("foodName")) {
                dto.setFoodName((String) requestBody.get("foodName"));
            } else {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "foodName is required", null));
            }
            
            if (requestBody.containsKey("sugarAmountMg")) {
                Object sugarAmount = requestBody.get("sugarAmountMg");
                if (sugarAmount instanceof Number) {
                    dto.setSugarAmountMg(((Number) sugarAmount).floatValue());
                } else {
                    return ResponseEntity.badRequest().body(
                        new ResponseMessage<>(400, "sugarAmountMg must be a number", null));
                }
            } else {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "sugarAmountMg is required", null));
            }
            
            if (requestBody.containsKey("quantity")) {
                Object quantity = requestBody.get("quantity");
                if (quantity instanceof Number) {
                    // quantity field is stored in the entity, but here we handle it by calculating the total sugar intake
                    Float quantityValue = ((Number) quantity).floatValue();
                    // total sugar intake = sugar amount per food * quantity
                    Float totalSugarMg = dto.getSugarAmountMg() * quantityValue;
                    dto.setSugarAmountMg(totalSugarMg);
                } else {
                    return ResponseEntity.badRequest().body(
                        new ResponseMessage<>(400, "quantity must be a number", null));
                }
            } else {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "quantity is required", null));
            }
            
            // set intake time
            if (requestBody.containsKey("consumedAt")) {
                String timeStr = (String) requestBody.get("consumedAt");
                try {
                    // support ISO format time
                    if (timeStr.contains("T")) {
                        timeStr = convertIsoToDateTime(timeStr);
                    }
                    dto.setIntakeTime(LocalDateTime.parse(timeStr, 
                        DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
                } catch (DateTimeParseException e) {
                    return ResponseEntity.badRequest().body(
                        new ResponseMessage<>(400, "Invalid consumedAt format. Use yyyy-MM-dd HH:mm:ss", null));
                }
            } else {
                // default current time
                dto.setIntakeTime(LocalDateTime.now());
            }
            
            // set default to manual input
            dto.setSourceType(SourceType.MANUAL);
            
            // call service to add record
            ResponseMessage<SugarIntakeHistoryDto> serviceResponse = sugarIntakeHistoryService.addSugarIntakeRecord(dto);
            
            if (serviceResponse.getCode() == 200) {
                // build response data
                SugarIntakeHistoryDto savedRecord = serviceResponse.getData();
                Map<String, Object> responseData = new HashMap<>();
                responseData.put("id", savedRecord.getIntakeId().toString());
                responseData.put("foodName", savedRecord.getFoodName());
                responseData.put("sugarAmountMg", ((Number) requestBody.get("sugarAmountMg")).floatValue());
                responseData.put("quantity", requestBody.get("quantity"));
                responseData.put("totalSugarMg", savedRecord.getSugarAmountMg());
                responseData.put("consumedAt", savedRecord.getIntakeTime().format(
                    DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")));
                responseData.put("createdAt", savedRecord.getCreatedAt().format(
                    DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")));
                
                ResponseMessage<Map<String, Object>> response = new ResponseMessage<>(
                    200, "Sugar record added successfully", responseData);
                
                return ResponseEntity.status(200).body(response);
            } else {
                return ResponseEntity.status(serviceResponse.getCode()).body(
                    new ResponseMessage<>(serviceResponse.getCode(), serviceResponse.getMessage(), null));
            }
            
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to add sugar record: " + e.getMessage(), null));
        }
    }

    /**
     * convert ISO 8601 format to MySQL DATETIME format
     */
    private String convertIsoToDateTime(String isoDateTime) {
        try {
            // try to parse ISO 8601 format (e.g. 2025-01-06T15:30:00Z)
            ZonedDateTime zonedDateTime = ZonedDateTime.parse(isoDateTime);
            LocalDateTime localDateTime = zonedDateTime.toLocalDateTime();
            return localDateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        } catch (DateTimeParseException e) {
            try {
                // try to parse simple ISO format (e.g. 2025-01-06T15:30:00)
                LocalDateTime localDateTime = LocalDateTime.parse(isoDateTime);
                return localDateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            } catch (DateTimeParseException e2) {
                // if both parsing fail, return current time
                return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            }
        }
    }

    /**
     * get daily sugar data
     * GET /user/{userId}/sugar-tracking/daily/{date}
     */
    @GetMapping("/{userId}/sugar-tracking/daily/{date}")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getDailySugarData(
            @PathVariable Integer userId,
            @PathVariable String date) {
        
        try {
            ResponseMessage<Map<String, Object>> response = sugarIntakeHistoryService.getDailySugarTrackingData(userId, date);
            
            if (response.getCode() == 200) {
                Map<String, Object> originalData = response.getData();
                
                // rebuild response data to match API specification
                Map<String, Object> responseData = new HashMap<>();
                
                // basic statistics
                responseData.put("currentIntakeMg", originalData.get("currentIntakeMg"));
                responseData.put("dailyGoalMg", originalData.get("dailyGoalMg"));
                responseData.put("progressPercentage", originalData.get("progressPercentage"));
                
                // status mapping
                String originalStatus = (String) originalData.get("status");
                String status;
                switch (originalStatus) {
                    case "on_track":
                        status = "good";
                        break;
                    case "warning":
                        status = "warning";
                        break;
                    case "over_limit":
                        status = "over_limit";
                        break;
                    default:
                        status = "good";
                }
                responseData.put("status", status);
                
                responseData.put("date", originalData.get("date") + "T00:00:00Z");
                
                // topContributors data processing - get actual sugar intake records
                List<Map<String, Object>> topContributors = new ArrayList<>();
                
                // get actual sugar intake records of the day
                ResponseMessage<List<SugarIntakeHistoryDto>> dailyRecords = 
                    sugarIntakeHistoryService.getSugarIntakeRecordsByUserIdAndDate(userId, date);
                
                if (dailyRecords.getCode() == 200 && dailyRecords.getData() != null) {
                    List<SugarIntakeHistoryDto> records = dailyRecords.getData();
                    
                    // sort by sugar amount, get top 5
                    records.stream()
                            .sorted((a, b) -> Float.compare(b.getSugarAmountMg(), a.getSugarAmountMg()))
                            .limit(5)
                            .forEach(record -> {
                                Map<String, Object> contributor = new HashMap<>();
                                contributor.put("id", record.getIntakeId().toString());
                                contributor.put("foodName", record.getFoodName());
                                contributor.put("sugarAmountMg", Math.round(record.getSugarAmountMg()));
                                contributor.put("quantity", 1.0); // 因为前端已将总糖分计算好
                                contributor.put("consumedAt", record.getIntakeTime().format(
                                    DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")));
                                topContributors.add(contributor);
                            });
                }
                
                responseData.put("topContributors", topContributors);
                
                ResponseMessage<Map<String, Object>> finalResponse = new ResponseMessage<>(200, "success", responseData);
                return ResponseEntity.ok(finalResponse);
                
            } else {
                return ResponseEntity.status(response.getCode()).body(response);
            }
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    /**
     * delete sugar record
     * DELETE /user/{userId}/sugar-tracking/record/{recordId}
     */
    @DeleteMapping("/{userId}/sugar-tracking/record/{recordId}")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> deleteSugarRecord(
            @PathVariable Integer userId,
            @PathVariable String recordId) {
        
        try {
            // convert recordId from string to integer
            Integer intakeId;
            try {
                intakeId = Integer.parseInt(recordId);
            } catch (NumberFormatException e) {
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("code", 400);
                errorData.put("message", "Invalid record ID format");
                errorData.put("data", null);
                return ResponseEntity.badRequest().body(new ResponseMessage<>(400, "Invalid record ID format", errorData));
            }
            
            // verify that the record belongs to the specified user
            ResponseMessage<SugarIntakeHistoryDto> recordResponse = sugarIntakeHistoryService.getSugarIntakeRecordById(intakeId);
            if (recordResponse.getCode() != 200 || recordResponse.getData() == null) {
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("code", 404);
                errorData.put("message", "Sugar record not found");
                errorData.put("data", null);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new ResponseMessage<>(404, "Sugar record not found", errorData));
            }
            
            // check if the record belongs to the specified user
            SugarIntakeHistoryDto record = recordResponse.getData();
            if (!record.getUserId().equals(userId)) {
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("code", 403);
                errorData.put("message", "Access denied - record does not belong to this user");
                errorData.put("data", null);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(new ResponseMessage<>(403, "Access denied", errorData));
            }
            
            // delete the record
            ResponseMessage<String> deleteResponse = sugarIntakeHistoryService.deleteSugarIntakeRecord(intakeId);
            if (deleteResponse.getCode() == 200) {
                Map<String, Object> responseData = new HashMap<>();
                responseData.put("code", 200);
                responseData.put("message", "Sugar record deleted successfully");
                responseData.put("data", null);
                
                return ResponseEntity.ok(new ResponseMessage<>(200, "Sugar record deleted successfully", responseData));
            } else {
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("code", deleteResponse.getCode());
                errorData.put("message", deleteResponse.getMessage());
                errorData.put("data", null);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ResponseMessage<>(deleteResponse.getCode(), deleteResponse.getMessage(), errorData));
            }
            
        } catch (Exception e) {
            Map<String, Object> errorData = new HashMap<>();
            errorData.put("code", 500);
            errorData.put("message", "Internal server error: " + e.getMessage());
            errorData.put("data", null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ResponseMessage<>(500, "Internal server error", errorData));
        }
    }

    /**
     * get user sugar intake history statistics
     * GET /user/{userId}/sugar-tracking/history
     */
    @GetMapping("/{userId}/sugar-tracking/history")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getSugarIntakeHistoryStats(
            @PathVariable Integer userId,
            @RequestParam(defaultValue = "week") String period) {
        
        try {
            // parameter validation
            if (!period.matches("^(week|month|year)$")) {
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("code", 400);
                errorData.put("message", "Invalid period parameter. Must be 'week', 'month', or 'year'");
                errorData.put("data", null);
                return ResponseEntity.badRequest().body(new ResponseMessage<>(400, "Invalid period parameter", errorData));
            }
            
            // get statistics data
            ResponseMessage<Map<String, Object>> statsResponse = sugarIntakeHistoryService.getSugarIntakeHistoryStats(userId, period);
            
            if (statsResponse.getCode() == 200) {
                return ResponseEntity.ok(new ResponseMessage<>(200, "success", statsResponse.getData()));
            } else {
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("code", statsResponse.getCode());
                errorData.put("message", statsResponse.getMessage());
                errorData.put("data", null);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ResponseMessage<>(statsResponse.getCode(), statsResponse.getMessage(), errorData));
            }
            
        } catch (Exception e) {
            Map<String, Object> errorData = new HashMap<>();
            errorData.put("code", 500);
            errorData.put("message", "Internal server error: " + e.getMessage());
            errorData.put("data", null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ResponseMessage<>(500, "Internal server error", errorData));
        }
    }

    /**
     * generate random time for demo
     */
    private String getRandomTime() {
        int hour = (int) (Math.random() * 24);
        int minute = (int) (Math.random() * 60);
        return String.format("%02d:%02d", hour, minute);
    }
}
