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
}
