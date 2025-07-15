package org.user.service;

import org.user.pojo.DTO.DailySugarSummaryDto;
import org.user.pojo.DTO.ResponseMessage;

import java.time.LocalDate;
import java.util.List;

public interface IDailySugarSummaryService {
    
    /**
     * update or create daily sugar summary (replace the core logic of the SQL trigger)
     * @param userId user id
     * @param date date
     * @return response message
     */
    ResponseMessage<DailySugarSummaryDto> updateDailySugarSummary(Integer userId, LocalDate date);
    
    /**
     * get daily summary by date
     * @param userId user id
     * @param date date
     * @return daily summary data
     */
    ResponseMessage<DailySugarSummaryDto> getDailySummaryByDate(Integer userId, LocalDate date);
    
    /**
     * get daily summaries by date range
     * @param userId user id
     * @param startDate start date
     * @param endDate end date
     * @return daily summaries
     */
    ResponseMessage<List<DailySugarSummaryDto>> getDailySummariesByDateRange(
            Integer userId, LocalDate startDate, LocalDate endDate);
    
    /**
     * recalculate daily summaries for a user (replace the core logic of the SQL procedure)
     * @param userId user id
     * @param startDate start date
     * @param endDate end date
     * @return response message
     */
    ResponseMessage<String> recalculateUserSugarSummaries(Integer userId, LocalDate startDate, LocalDate endDate);
    
    /**
     * delete daily summary by date
     * @param userId user id
     * @param date date
     * @return response message
     */
    ResponseMessage<String> deleteDailySummary(Integer userId, LocalDate date);
    
    /**
     * get recent daily summaries for a user
     * @param userId user id
     * @param limit limit
     * @return recent daily summaries
     */
    ResponseMessage<List<DailySugarSummaryDto>> getRecentDailySummaries(Integer userId, Integer limit);
} 