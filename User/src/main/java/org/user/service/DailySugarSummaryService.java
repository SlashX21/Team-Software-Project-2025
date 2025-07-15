package org.user.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.user.pojo.DailySugarSummary;
import org.user.pojo.SugarGoals;
import org.user.pojo.SugarIntakeHistory;
import org.user.pojo.DTO.DailySugarSummaryDto;
import org.user.pojo.DTO.ResponseMessage;
import org.user.repository.DailySugarSummaryRepository;
import org.user.repository.SugarGoalsRepository;
import org.user.repository.SugarIntakeHistoryRepository;
import org.user.enums.SugarSummaryStatus;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class DailySugarSummaryService implements IDailySugarSummaryService {
    
    @Autowired
    private DailySugarSummaryRepository dailySugarSummaryRepository;
    
    @Autowired
    private SugarIntakeHistoryRepository sugarIntakeHistoryRepository;
    
    @Autowired
    private SugarGoalsRepository sugarGoalsRepository;
    
    /**
     * update or create daily sugar summary (replace the core logic of the SQL trigger)
     * this method replaces the functionality of three SQL triggers
     */
    @Override
    public ResponseMessage<DailySugarSummaryDto> updateDailySugarSummary(Integer userId, LocalDate date) {
        try {
            // get the time range of the day
            LocalDateTime startOfDay = date.atStartOfDay();
            LocalDateTime endOfDay = date.atTime(LocalTime.MAX);
            // query all sugar intake records of the day
            List<SugarIntakeHistory> dailyRecords = sugarIntakeHistoryRepository
                    .findByUserIdAndConsumedAtBetween(userId, startOfDay, endOfDay);
            // calculate the total intake and record count
            BigDecimal totalIntake = dailyRecords.stream()
                    .map(record -> BigDecimal.valueOf(record.getSugarAmountMg() * record.getQuantity()))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            int recordCount = dailyRecords.size();
            
            // get the user's daily goal
            SugarGoals userGoal = sugarGoalsRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
            BigDecimal dailyGoalMg = (userGoal != null && userGoal.getDailyGoalMg() != null) 
                    ? BigDecimal.valueOf(userGoal.getDailyGoalMg()) 
                    : BigDecimal.valueOf(50000.0); // default 50g
            
            // calculate the progress percentage
            BigDecimal progressPercentage = BigDecimal.ZERO;
            if (dailyGoalMg.compareTo(BigDecimal.ZERO) > 0) {
                progressPercentage = totalIntake.divide(dailyGoalMg, 4, BigDecimal.ROUND_HALF_UP)
                        .multiply(BigDecimal.valueOf(100))
                        .setScale(2, BigDecimal.ROUND_HALF_UP);
            }
            
            // determine the status
            SugarSummaryStatus status = determineStatus(progressPercentage);

            // check if there is a summary record for the day
            Optional<DailySugarSummary> existingSummaryOpt = 
                    dailySugarSummaryRepository.findByUserIdAndDate(userId, date);
            
            DailySugarSummary summary;
            if (existingSummaryOpt.isPresent()) {
                // update the existing record
                summary = existingSummaryOpt.get();
                summary.setTotalIntakeMg(totalIntake);
                summary.setDailyGoalMg(dailyGoalMg);
                summary.setProgressPercentage(progressPercentage);
                summary.setStatus(status);
                summary.setRecordCount(recordCount);
            } else {
                // create a new record
                summary = new DailySugarSummary();
                summary.setUserId(userId);
                summary.setDate(date);
                summary.setTotalIntakeMg(totalIntake);
                summary.setDailyGoalMg(dailyGoalMg);
                summary.setProgressPercentage(progressPercentage);
                summary.setStatus(status);
                summary.setRecordCount(recordCount);
            }
            
            // save or update the record
            DailySugarSummary savedSummary = dailySugarSummaryRepository.save(summary);
            DailySugarSummaryDto resultDto = convertEntityToDto(savedSummary);
            
            return ResponseMessage.success(resultDto);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to update daily sugar summary: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<DailySugarSummaryDto> getDailySummaryByDate(Integer userId, LocalDate date) {
        try {
            Optional<DailySugarSummary> summaryOpt = dailySugarSummaryRepository.findByUserIdAndDate(userId, date);
            
            if (summaryOpt.isPresent()) {
                DailySugarSummaryDto dto = convertEntityToDto(summaryOpt.get());
                return ResponseMessage.success(dto);
            } else {
                // if there is no summary record, try to create one
                ResponseMessage<DailySugarSummaryDto> updateResult = updateDailySugarSummary(userId, date);
                if (updateResult.getCode() == 200) {
                    return updateResult;
                } else {
                    return new ResponseMessage<>(404, "No daily summary found for the specified date", null);
                }
            }
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve daily summary: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<DailySugarSummaryDto>> getDailySummariesByDateRange(
            Integer userId, LocalDate startDate, LocalDate endDate) {
        try {
            List<DailySugarSummary> summaries = dailySugarSummaryRepository
                    .findByUserIdAndDateBetween(userId, startDate, endDate);
            
            List<DailySugarSummaryDto> dtos = summaries.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            
            return ResponseMessage.success(dtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve daily summaries: " + e.getMessage(), null);
        }
    }
    
    /**
     * recalculate daily summaries for a user (replace the core logic of the SQL procedure)
     */
    @Override
    public ResponseMessage<String> recalculateUserSugarSummaries(Integer userId, LocalDate startDate, LocalDate endDate) {
        try {
            LocalDate currentDate = startDate;
            int updatedCount = 0;
            
            while (!currentDate.isAfter(endDate)) {
                ResponseMessage<DailySugarSummaryDto> result = updateDailySugarSummary(userId, currentDate);
                if (result.getCode() == 200) {
                    updatedCount++;
                }
                currentDate = currentDate.plusDays(1);
            }
            
            return ResponseMessage.success("Successfully recalculated " + updatedCount + " daily summaries");
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to recalculate daily summaries: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<String> deleteDailySummary(Integer userId, LocalDate date) {
        try {
            dailySugarSummaryRepository.deleteByUserIdAndDate(userId, date);
            return ResponseMessage.success("Daily summary deleted successfully");
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to delete daily summary: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<DailySugarSummaryDto>> getRecentDailySummaries(Integer userId, Integer limit) {
        try {
            List<DailySugarSummary> summaries = dailySugarSummaryRepository.findRecentByUserId(userId, limit);
            List<DailySugarSummaryDto> dtos = summaries.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            
            return ResponseMessage.success(dtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve recent summaries: " + e.getMessage(), null);
        }
    }
    
    /**
     * determine the sugar intake status
     */
    private SugarSummaryStatus determineStatus(BigDecimal progressPercentage) {
        if (progressPercentage.compareTo(BigDecimal.valueOf(100)) > 0) {
            return SugarSummaryStatus.OVER_LIMIT;
        } else if (progressPercentage.compareTo(BigDecimal.valueOf(70)) >= 0) {
            return SugarSummaryStatus.WARNING;
        } else {
            return SugarSummaryStatus.GOOD;
        }
    }
    
    /**
     * convert the entity to DTO
     */
    private DailySugarSummaryDto convertEntityToDto(DailySugarSummary entity) {
        DailySugarSummaryDto dto = new DailySugarSummaryDto();
        dto.setId(entity.getId());
        dto.setUserId(entity.getUserId());
        dto.setDate(entity.getDate());
        dto.setTotalIntakeMg(entity.getTotalIntakeMg());
        dto.setDailyGoalMg(entity.getDailyGoalMg());
        dto.setProgressPercentage(entity.getProgressPercentage());
        dto.setStatus(entity.getStatus());
        dto.setRecordCount(entity.getRecordCount());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }
    
    /**
     * convert the DTO to entity
     */
    private DailySugarSummary convertDtoToEntity(DailySugarSummaryDto dto) {
        DailySugarSummary entity = new DailySugarSummary();
        entity.setId(dto.getId());
        entity.setUserId(dto.getUserId());
        entity.setDate(dto.getDate());
        entity.setTotalIntakeMg(dto.getTotalIntakeMg());
        entity.setDailyGoalMg(dto.getDailyGoalMg());
        entity.setProgressPercentage(dto.getProgressPercentage());
        entity.setStatus(dto.getStatus());
        entity.setRecordCount(dto.getRecordCount());
        entity.setCreatedAt(dto.getCreatedAt());
        entity.setUpdatedAt(dto.getUpdatedAt());
        return entity;
    }
} 