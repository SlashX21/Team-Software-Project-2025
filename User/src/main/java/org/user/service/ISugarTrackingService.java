package org.user.service;

import java.sql.Date;

import org.user.pojo.DTO.SugarTrackingDto;
import org.user.pojo.DTO.SugarRecordsDto;
import org.user.pojo.DTO.SugarHistoryStatsDto;
import org.user.pojo.DTO.SugarGoalResponseDto;
import org.user.pojo.DTO.SugarGoalRequestDto;
import org.user.pojo.SugarRecords;

public interface ISugarTrackingService {
    
    /**
     * get user's daily sugar intake statistics
     * @param userId user id
     * @param date date, format: YYYY-MM-DD
     * @return sugar tracking statistics
     */
    SugarTrackingDto getDailySugarTracking(Integer userId, Date date);
    
    /**
     * add sugar intake record
     * @param sugarRecordDto sugar record DTO
     * @return saved sugar record
     */
    SugarRecords addSugarRecord(SugarRecordsDto sugarRecordDto);
    
    /**
     * get user's sugar intake history statistics
     * @param userId user id
     * @param period statistics period ('week', 'month', 'year')
     * @return sugar history statistics
     */
    SugarHistoryStatsDto getSugarHistoryStats(Integer userId, String period);
    
    /**
     * get user's current sugar goal
     * @param userId user id
     * @return sugar goal information
     */
    SugarGoalResponseDto getUserSugarGoal(Integer userId);
    
    /**
     * set or update user's sugar goal
     * @param userId user id
     * @param goalRequestDto sugar goal request data
     * @return updated sugar goal information
     */
    SugarGoalResponseDto setUserSugarGoal(Integer userId, SugarGoalRequestDto goalRequestDto);
    
    /**
     * delete sugar intake record
     * @param userId user id
     * @param recordId record id
     * @return true if deleted successfully
     */
    boolean deleteSugarRecord(Integer userId, Integer recordId);
} 