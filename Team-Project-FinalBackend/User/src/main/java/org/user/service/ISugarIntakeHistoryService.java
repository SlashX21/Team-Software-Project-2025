package org.user.service;

import org.user.pojo.DTO.SugarIntakeHistoryDto;
import org.user.pojo.DTO.ResponseMessage;
import org.user.pojo.DTO.MonthlyStatsDto;
import org.user.pojo.DTO.MonthlyCalendarDto;


import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface ISugarIntakeHistoryService {
    
    /**
     * add sugar intake record
     */
    ResponseMessage<SugarIntakeHistoryDto> addSugarIntakeRecord(SugarIntakeHistoryDto sugarIntakeHistoryDto);
    
    /**
     * update sugar intake record by id
     */
    ResponseMessage<SugarIntakeHistoryDto> updateSugarIntakeRecord(Integer intakeId, SugarIntakeHistoryDto sugarIntakeHistoryDto);
    
    /**
     * delete sugar intake record by id
     */
    ResponseMessage<String> deleteSugarIntakeRecord(Integer intakeId);
    
    /**
     * query sugar intake record by id
     */
    ResponseMessage<SugarIntakeHistoryDto> getSugarIntakeRecordById(Integer intakeId);
    
    /**
     * query all sugar intake records by user id
     */
    ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByUserId(Integer userId);
    
    /**
     * query sugar intake records by user id and time range
     */
    ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByUserIdAndTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime);
    

    
    /**
     * calculate total sugar intake by user id and time range
     */
    ResponseMessage<Float> calculateTotalSugarIntakeByTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime);
    
    /**
     * calculate today total sugar intake by user id
     */
    ResponseMessage<Float> calculateTodayTotalSugarIntake(Integer userId);
    
    /**
     * query recent records by user id
     */
    ResponseMessage<List<SugarIntakeHistoryDto>> getRecentSugarIntakeRecords(Integer userId, Integer limit);
    
    /**
     * search records by user id and food name
     */
    ResponseMessage<List<SugarIntakeHistoryDto>> searchSugarIntakeRecordsByFoodName(Integer userId, String foodName);
    
    /**
     * delete all records by user id
     */
    ResponseMessage<String> deleteAllSugarIntakeRecordsByUserId(Integer userId);
    
    /**
     * delete records by user id and time range
     */
    ResponseMessage<String> deleteSugarIntakeRecordsByUserIdAndTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime);
    
    /**
     * check if user has sugar intake records
     */
    ResponseMessage<Boolean> hasUserSugarIntakeRecords(Integer userId);
    
    /**
     * count records by user id
     */
    ResponseMessage<Long> countSugarIntakeRecordsByUserId(Integer userId);
    
    /**
     * count records by user id and time range
     */
    ResponseMessage<Long> countSugarIntakeRecordsByUserIdAndTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime);
    
    /**
     * query records by user id and date
     */
    ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByUserIdAndDate(Integer userId, String date);
    
    /**
     * get daily sugar intake stats by user id (last 30 days)
     */
    ResponseMessage<List<Map<String, Object>>> getDailySugarIntakeStats(Integer userId);
    
    /**
     * add batch sugar intake records
     */
    ResponseMessage<List<SugarIntakeHistoryDto>> addBatchSugarIntakeRecords(List<SugarIntakeHistoryDto> sugarIntakeHistoryDtos);
    
    /**
     * get daily sugar tracking data with detailed analysis
     */
    ResponseMessage<Map<String, Object>> getDailySugarTrackingData(Integer userId, String date);
    
    /**
     * get monthly sugar intake statistics
     */
    ResponseMessage<MonthlyStatsDto> getMonthlySugarStats(Integer userId, String month);
    
    /**
     * get sugar intake history statistics by period
     * @param userId user id
     * @param period period ("week", "month", "year")
     * @return statistics data
     */
    ResponseMessage<Map<String, Object>> getSugarIntakeHistoryStats(Integer userId, String period);
    
    /**
     * get monthly sugar calendar data
     * @param userId user id
     * @param year year
     * @param month month (1-12)
     * @return monthly calendar data
     */
    ResponseMessage<MonthlyCalendarDto> getMonthlyCalendarData(Integer userId, Integer year, Integer month);
} 