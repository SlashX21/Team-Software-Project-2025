package org.user.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.user.pojo.DTO.SugarIntakeHistoryDto;
import org.user.pojo.DTO.ResponseMessage;
import org.user.pojo.DTO.SugarGoalRequestDto;
import org.user.pojo.DTO.SugarGoalResponseDto;
import org.user.pojo.DTO.MonthlyStatsDto;
import org.user.service.ISugarIntakeHistoryService;
import org.user.service.ISugarTrackingService;
import org.user.enums.SourceType;

import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/sugar-tracking/{userId}")
public class SugarIntakeHistoryController {
    
    @Autowired
    private ISugarIntakeHistoryService sugarIntakeHistoryService;
    
    @Autowired
    private ISugarTrackingService sugarTrackingService;
    
    /**
     * 添加糖分摄入记录
     * POST /user/{userId}/sugar-intake
     */
    @PostMapping
    public ResponseEntity<ResponseMessage<SugarIntakeHistoryDto>> addSugarIntakeRecord(
            @PathVariable Integer userId,
            @Valid @RequestBody SugarIntakeHistoryDto sugarIntakeHistoryDto) {
        
        // 设置用户ID
        sugarIntakeHistoryDto.setUserId(userId);
        
        ResponseMessage<SugarIntakeHistoryDto> response = sugarIntakeHistoryService.addSugarIntakeRecord(sugarIntakeHistoryDto);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 获取用户所有糖分摄入记录
     * GET /user/{userId}/sugar-intake
     */
    @GetMapping()
    public ResponseEntity<ResponseMessage<List<SugarIntakeHistoryDto>>> getSugarIntakeRecords(
            @PathVariable Integer userId) {
        
        ResponseMessage<List<SugarIntakeHistoryDto>> response = sugarIntakeHistoryService.getSugarIntakeRecordsByUserId(userId);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 根据ID获取糖分摄入记录
     * GET /user/{userId}/sugar-intake/{intakeId}
     */
    @GetMapping("/{intakeId}")
    public ResponseEntity<ResponseMessage<SugarIntakeHistoryDto>> getSugarIntakeRecord(
            @PathVariable Integer userId,
            @PathVariable Integer intakeId) {
        
        ResponseMessage<SugarIntakeHistoryDto> response = sugarIntakeHistoryService.getSugarIntakeRecordById(intakeId);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 更新糖分摄入记录
     * PUT /user/{userId}/sugar-intake/{intakeId}
     */
    @PutMapping("/{intakeId}")
    public ResponseEntity<ResponseMessage<SugarIntakeHistoryDto>> updateSugarIntakeRecord(
            @PathVariable Integer userId,
            @PathVariable Integer intakeId,
            @Valid @RequestBody SugarIntakeHistoryDto sugarIntakeHistoryDto) {
        
        ResponseMessage<SugarIntakeHistoryDto> response = sugarIntakeHistoryService.updateSugarIntakeRecord(intakeId, sugarIntakeHistoryDto);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 根据食物名称搜索记录
     * GET /user/{userId}/sugar-intake/search?foodName=apple
     */
    @GetMapping("/search")
    public ResponseEntity<ResponseMessage<List<SugarIntakeHistoryDto>>> searchSugarIntakeRecords(
            @PathVariable Integer userId,
            @RequestParam String foodName) {
        
        ResponseMessage<List<SugarIntakeHistoryDto>> response = sugarIntakeHistoryService.searchSugarIntakeRecordsByFoodName(userId, foodName);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * obtain the daily sugar tracking data of the user
     * GET /sugar-tracking/{userId}/daily?date={date}
     */
    @GetMapping("/daily")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getDailySugarTrackingData(
            @PathVariable Integer userId,
            @RequestParam(required = false) String date) {
        
        ResponseMessage<Map<String, Object>> response = sugarIntakeHistoryService.getDailySugarTrackingData(userId, date);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * add sugar intake record
     * POST /sugar-tracking/{userId}/records
     */
    @PostMapping("/records")
    public ResponseEntity<ResponseMessage<SugarIntakeHistoryDto>> addSugarRecord(
            @PathVariable Integer userId,
            @RequestBody Map<String, Object> requestBody) {
        
        try {
            // create DTO object
            SugarIntakeHistoryDto dto = new SugarIntakeHistoryDto();
            dto.setUserId(userId);
            
            // map the fields
            if (requestBody.containsKey("foodName")) {
                dto.setFoodName((String) requestBody.get("foodName"));
            }
            if (requestBody.containsKey("sugarAmount")) {
                Object sugarAmount = requestBody.get("sugarAmount");
                if (sugarAmount instanceof Number) {
                    dto.setSugarAmountMg(((Number) sugarAmount).floatValue());
                }
            }
            if (requestBody.containsKey("intakeTime")) {
                String timeStr = (String) requestBody.get("intakeTime");
                timeStr = convertIsoToDateTime(timeStr);
                dto.setIntakeTime(java.time.LocalDateTime.parse(timeStr, 
                    java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
            }
            if (requestBody.containsKey("sourceType")) {
                String sourceType = (String) requestBody.get("sourceType");
                dto.setSourceType(org.user.enums.SourceType.valueOf(sourceType.toUpperCase()));
            }
            if (requestBody.containsKey("barcode")) {
                dto.setBarcode((String) requestBody.get("barcode"));
            }
            if (requestBody.containsKey("servingSize")) {
                dto.setServingSize((String) requestBody.get("servingSize"));
            }
            
            ResponseMessage<SugarIntakeHistoryDto> response = sugarIntakeHistoryService.addSugarIntakeRecord(dto);
            
            if (response.getCode() == 200) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(response.getCode()).body(response);
            }
            
        } catch (Exception e) {
            ResponseMessage<SugarIntakeHistoryDto> errorResponse = 
                new ResponseMessage<>(400, "Invalid request data: " + e.getMessage(), null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }
    /**
     * convert datetime string to ISO 8601 format
     */
    private String convertToIsoDateTime(String dateTimeStr) {
        if (dateTimeStr == null || dateTimeStr.isEmpty()) {
            return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        }
        
        try {
            // assume input format is "yyyy-MM-dd HH:mm:ss"
            LocalDateTime dateTime = LocalDateTime.parse(dateTimeStr, DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            return dateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        } catch (Exception e) {
            // if parsing fails, return current time
            return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        }
    }
    
    /**
     * convert ISO 8601 format to MySQL DATETIME format
     */
    private String convertIsoToDateTime(String isoDateTime) {
        try {
            // try to parse ISO 8601 format (e.g. 2024-01-15T16:30:00Z)
            ZonedDateTime zonedDateTime = ZonedDateTime.parse(isoDateTime);
            LocalDateTime localDateTime = zonedDateTime.toLocalDateTime();
            return localDateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        } catch (DateTimeParseException e) {
            try {
                // try to parse simple ISO format (e.g. 2024-01-15T16:30:00)
                LocalDateTime localDateTime = LocalDateTime.parse(isoDateTime);
                return localDateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            } catch (DateTimeParseException e2) {
                // if both parsing fail, return current time
                return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            }
        }
    }

    /**
     * set the user's sugar goal
     * POST /sugar-tracking/{userId}/goals
     */
    @PostMapping("/goals")
    public ResponseEntity<ResponseMessage<SugarGoalResponseDto>> setSugarGoal(
            @PathVariable Integer userId,
            @Valid @RequestBody SugarGoalRequestDto sugarGoalRequestDto) {
        
        try {
            SugarGoalResponseDto response = sugarTrackingService.setUserSugarGoal(userId, sugarGoalRequestDto);
            return ResponseEntity.ok(ResponseMessage.success(response));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to set sugar goal: " + e.getMessage(), null));
        }
    }
    
    /**
     * get the monthly sugar statistics
     * GET /sugar-tracking/{userId}/monthly?month={yyyy-MM}
     */
    @GetMapping("/monthly")
    public ResponseEntity<ResponseMessage<MonthlyStatsDto>> getMonthlySugarStats(
            @PathVariable Integer userId,
            @RequestParam String month) {
        
        try {
            ResponseMessage<MonthlyStatsDto> response = sugarIntakeHistoryService.getMonthlySugarStats(userId, month);
            
            if (response.getCode() == 200) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(response.getCode()).body(response);
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to get monthly sugar statistics: " + e.getMessage(), null));
        }
    }
    
    /**
     * delete the sugar intake record
     * DELETE /sugar-tracking/{userId}/records/{intakeId}
     */
    @DeleteMapping("/records/{intakeId}")
    public ResponseEntity<ResponseMessage<String>> deleteSugarIntakeRecord(
            @PathVariable Integer userId,
            @PathVariable Integer intakeId) {
        
        try {
            ResponseMessage<String> response = sugarIntakeHistoryService.deleteSugarIntakeRecord(intakeId);
            
            if (response.getCode() == 200) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(response.getCode()).body(response);
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to delete sugar intake record: " + e.getMessage(), null));
        }
    }
} 