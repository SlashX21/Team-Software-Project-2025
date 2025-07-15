package org.user.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.user.pojo.DTO.DailySugarSummaryDto;
import org.user.pojo.DTO.ResponseMessage;
import org.user.service.IDailySugarSummaryService;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

@RestController
@RequestMapping("/sugar-tracking/{userId}/daily-summary")
public class DailySugarSummaryController {
    
    @Autowired
    private IDailySugarSummaryService dailySugarSummaryService;
    
    /**
     * 获取用户指定日期的每日汇总
     * GET /sugar-tracking/{userId}/daily-summary?date=2024-01-15
     */
    @GetMapping
    public ResponseEntity<ResponseMessage<DailySugarSummaryDto>> getDailySummary(
            @PathVariable Integer userId,
            @RequestParam(required = false) String date) {
        
        LocalDate targetDate;
        if (date != null && !date.isEmpty()) {
            try {
                targetDate = LocalDate.parse(date, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            } catch (DateTimeParseException e) {
                ResponseMessage<DailySugarSummaryDto> errorResponse = 
                        new ResponseMessage<>(400, "Invalid date format. Use yyyy-MM-dd", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
        } else {
            targetDate = LocalDate.now();
        }
        
        ResponseMessage<DailySugarSummaryDto> response = 
                dailySugarSummaryService.getDailySummaryByDate(userId, targetDate);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 获取用户指定日期范围的每日汇总列表
     * GET /sugar-tracking/{userId}/daily-summary/range?start_date=2024-01-01&end_date=2024-01-31
     */
    @GetMapping("/range")
    public ResponseEntity<ResponseMessage<List<DailySugarSummaryDto>>> getDailySummariesByRange(
            @PathVariable Integer userId,
            @RequestParam("start_date") String startDate,
            @RequestParam("end_date") String endDate) {
        
        LocalDate start, end;
        try {
            start = LocalDate.parse(startDate, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            end = LocalDate.parse(endDate, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        } catch (DateTimeParseException e) {
            ResponseMessage<List<DailySugarSummaryDto>> errorResponse = 
                    new ResponseMessage<>(400, "Invalid date format. Use yyyy-MM-dd", null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
        
        if (start.isAfter(end)) {
            ResponseMessage<List<DailySugarSummaryDto>> errorResponse = 
                    new ResponseMessage<>(400, "Start date must be before end date", null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
        
        ResponseMessage<List<DailySugarSummaryDto>> response = 
                dailySugarSummaryService.getDailySummariesByDateRange(userId, start, end);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 获取用户最近的每日汇总记录
     * GET /sugar-tracking/{userId}/daily-summary/recent?limit=7
     */
    @GetMapping("/recent")
    public ResponseEntity<ResponseMessage<List<DailySugarSummaryDto>>> getRecentDailySummaries(
            @PathVariable Integer userId,
            @RequestParam(defaultValue = "7") Integer limit) {
        
        if (limit <= 0 || limit > 365) {
            ResponseMessage<List<DailySugarSummaryDto>> errorResponse = 
                    new ResponseMessage<>(400, "Limit must be between 1 and 365", null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
        
        ResponseMessage<List<DailySugarSummaryDto>> response = 
                dailySugarSummaryService.getRecentDailySummaries(userId, limit);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 手动更新指定日期的每日汇总
     * PUT /sugar-tracking/{userId}/daily-summary/update?date=2024-01-15
     */
    @PutMapping("/update")
    public ResponseEntity<ResponseMessage<DailySugarSummaryDto>> updateDailySummary(
            @PathVariable Integer userId,
            @RequestParam(required = false) String date) {
        
        LocalDate targetDate;
        if (date != null && !date.isEmpty()) {
            try {
                targetDate = LocalDate.parse(date, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            } catch (DateTimeParseException e) {
                ResponseMessage<DailySugarSummaryDto> errorResponse = 
                        new ResponseMessage<>(400, "Invalid date format. Use yyyy-MM-dd", null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
        } else {
            targetDate = LocalDate.now();
        }
        
        ResponseMessage<DailySugarSummaryDto> response = 
                dailySugarSummaryService.updateDailySugarSummary(userId, targetDate);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 批量重新计算用户的每日汇总
     * POST /sugar-tracking/{userId}/daily-summary/recalculate
     */
    @PostMapping("/recalculate")
    public ResponseEntity<ResponseMessage<String>> recalculateUserSummaries(
            @PathVariable Integer userId,
            @RequestParam("start_date") String startDate,
            @RequestParam("end_date") String endDate) {
        
        LocalDate start, end;
        try {
            start = LocalDate.parse(startDate, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            end = LocalDate.parse(endDate, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        } catch (DateTimeParseException e) {
            ResponseMessage<String> errorResponse = 
                    new ResponseMessage<>(400, "Invalid date format. Use yyyy-MM-dd", null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
        
        if (start.isAfter(end)) {
            ResponseMessage<String> errorResponse = 
                    new ResponseMessage<>(400, "Start date must be before end date", null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
        
        ResponseMessage<String> response = 
                dailySugarSummaryService.recalculateUserSugarSummaries(userId, start, end);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
    
    /**
     * 删除用户指定日期的汇总记录
     * DELETE /sugar-tracking/{userId}/daily-summary?date=2024-01-15
     */
    @DeleteMapping
    public ResponseEntity<ResponseMessage<String>> deleteDailySummary(
            @PathVariable Integer userId,
            @RequestParam String date) {
        
        LocalDate targetDate;
        try {
            targetDate = LocalDate.parse(date, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        } catch (DateTimeParseException e) {
            ResponseMessage<String> errorResponse = 
                    new ResponseMessage<>(400, "Invalid date format. Use yyyy-MM-dd", null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
        
        ResponseMessage<String> response = 
                dailySugarSummaryService.deleteDailySummary(userId, targetDate);
        
        if (response.getCode() == 200) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(response.getCode()).body(response);
        }
    }
} 