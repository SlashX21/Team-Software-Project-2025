package org.user.controller;

// import org.demo.springboot_demo.pojo.DTO.ResponseMessage;
// import com.demo.springboot_demo.pojo.DTO.UserDto;
// import com.demo.springboot_demo.pojo.User;
// import com.demo.springboot_demo.service.IUserService;


import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
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
import org.user.pojo.DTO.SugarTrackingDto;
import org.user.pojo.DTO.SugarRecordsDto;
import org.user.pojo.DTO.SugarRecordResponseDto;
import org.user.pojo.DTO.SugarHistoryStatsDto;
import org.user.pojo.DTO.SugarGoalResponseDto;
import org.user.pojo.DTO.SugarGoalRequestDto;
import org.user.pojo.SugarRecords;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.user.service.IUserPreferenceService;
import org.user.pojo.DTO.UserPreferenceDto;
import org.user.enums.PreferenceSource;

import java.sql.Date;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;


@RestController //允许接口方法返回对象, 并且对象可以直接转换为json文本
@RequestMapping("/user") // 这样子前端就可以使用 localhost:8080/user/**来访问
public class UserController {
    @Autowired IUserService userService;
    @Autowired IUserHistoryService userHistoryService;
    @Autowired ISugarTrackingService sugarTrackingService;
    @Autowired IUserPreferenceService userPreferenceService;

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
     * Get user's daily sugar tracking
     */
    @GetMapping("/{userId}/sugar-tracking/daily/{date}")
    public ResponseEntity<ResponseMessage<SugarTrackingDto>> getDailySugarTracking(
            @PathVariable Integer userId,
            @PathVariable String date) {
        
        try {
            // validate date format (YYYY-MM-DD)
            if (!date.matches("\\d{4}-\\d{2}-\\d{2}")) {
                ResponseMessage<SugarTrackingDto> errorResponse = new ResponseMessage<>(
                        400, "Invalid date format. Expected YYYY-MM-DD", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            Date sqlDate = Date.valueOf(LocalDate.parse(date));

            SugarTrackingDto sugarTracking = sugarTrackingService.getDailySugarTracking(userId, sqlDate);
            ResponseMessage<SugarTrackingDto> response = new ResponseMessage<>(200, "Success", sugarTracking);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<SugarTrackingDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * add sugar record
     * POST /user/{userId}/sugar-tracking/record
     */
    @PostMapping("/{userId}/sugar-tracking/record")
    public ResponseEntity<ResponseMessage<SugarRecordResponseDto>> addSugarRecord(
            @PathVariable Integer userId,
            @Validated @RequestBody SugarRecordsDto sugarRecordDto) {
        // TODO: product barcode, source, notes are passed to DTO from frontend
        try {
            // ensure userId in DTO is the same as the path parameter
            sugarRecordDto.setUserId(userId);
            
            SugarRecords savedRecord = sugarTrackingService.addSugarRecord(sugarRecordDto);
            
            // create response DTO
            SugarRecordResponseDto responseDto = new SugarRecordResponseDto(
                    "sugar_new_" + String.format("%03d", savedRecord.getRecordId()),
                    savedRecord.getFoodName(),
                    savedRecord.getSugarAmountMg(),
                    savedRecord.getQuantity(),
                    savedRecord.getConsumedAt(),
                    // TODO: product barcode, source, notes are not in the DTO
                    savedRecord.getProductBarcode(),
                    savedRecord.getCreatedAt()
            );
            
            ResponseMessage<SugarRecordResponseDto> response = new ResponseMessage<>(201, "Sugar record added successfully", responseDto);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
            
        } catch (Exception e) {
            ResponseMessage<SugarRecordResponseDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * obtain user's sugar intake history statistics
     * GET /user/{userId}/sugar-tracking/history
     */
    @GetMapping("/{userId}/sugar-tracking/history")
    public ResponseEntity<ResponseMessage<SugarHistoryStatsDto>> getSugarHistoryStats(
            @PathVariable Integer userId,
            @RequestParam(defaultValue = "week") String period) {
        
        try {
            // validate period parameter
            if (!period.equals("week") && !period.equals("month") && !period.equals("year")) {
                ResponseMessage<SugarHistoryStatsDto> errorResponse = new ResponseMessage<>(
                        400, "Invalid period. Expected 'week', 'month', or 'year'", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
            SugarHistoryStatsDto historyStats = sugarTrackingService.getSugarHistoryStats(userId, period);
            ResponseMessage<SugarHistoryStatsDto> response = new ResponseMessage<>(200, "Success", historyStats);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<SugarHistoryStatsDto> errorResponse = new ResponseMessage<>(
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
     * delete sugar intake record
     * DELETE /user/{userId}/sugar-tracking/record/{recordId}
     */
    @DeleteMapping("/{userId}/sugar-tracking/record/{recordId}")
    public ResponseEntity<ResponseMessage<String>> deleteSugarRecord(
            @PathVariable Integer userId,
            @PathVariable Integer recordId) {
        
        try {
            boolean deleted = sugarTrackingService.deleteSugarRecord(userId, recordId);
            
            if (deleted) {
                ResponseMessage<String> response = new ResponseMessage<>(200, "Sugar record deleted successfully", null);
                return ResponseEntity.ok(response);
            } else {
                ResponseMessage<String> errorResponse = new ResponseMessage<>(
                        404, "Sugar record not found", null);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            }
            
        } catch (RuntimeException e) {
            // handle business exception
            if (e.getMessage().contains("not found")) {
                ResponseMessage<String> errorResponse = new ResponseMessage<>(
                        404, e.getMessage(), null);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            } else if (e.getMessage().contains("does not belong")) {
                ResponseMessage<String> errorResponse = new ResponseMessage<>(
                        403, "Forbidden: " + e.getMessage(), null);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
            } else {
                ResponseMessage<String> errorResponse = new ResponseMessage<>(
                        500, "Internal server error: " + e.getMessage(), null);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
            }
        } catch (Exception e) {
            ResponseMessage<String> errorResponse = new ResponseMessage<>(
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
     * 辅助方法：从Map中获取Boolean值，支持下划线和驼峰命名
     */
    private Boolean getBooleanValue(Map<String, Object> request, String underscoreKey, String camelKey) {
        Object value = request.get(underscoreKey);
        if (value == null) {
            value = request.get(camelKey);
        }
        return value != null ? (Boolean) value : false;
    }
    
    /**
     * 辅助方法：从Map中获取String值，支持下划线和驼峰命名
     */
    private String getStringValue(Map<String, Object> request, String underscoreKey, String camelKey) {
        Object value = request.get(underscoreKey);
        if (value == null) {
            value = request.get(camelKey);
        }
        return value != null ? (String) value : null;
    }
}
