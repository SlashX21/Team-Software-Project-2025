package org.user.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.user.pojo.SugarIntakeHistory;
import org.user.pojo.DTO.SugarIntakeHistoryDto;
import org.user.pojo.DTO.ResponseMessage;
import org.user.pojo.DTO.MonthlyStatsDto;
import org.user.pojo.DTO.MonthlyCalendarDto;
import org.user.pojo.DTO.DailySugarSummaryDto;
import org.user.pojo.DailySugarSummary;
import org.user.repository.SugarIntakeHistoryRepository;
import org.user.repository.SugarGoalsRepository;
import org.user.pojo.SugarGoals;
import org.user.enums.SugarSummaryStatus;


import java.time.LocalDateTime;
import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Optional;
import java.util.ArrayList;
import java.util.stream.Collectors;
import java.time.YearMonth;

@Service
@Transactional
public class SugarIntakeHistoryService implements ISugarIntakeHistoryService {
    
    @Autowired
    private SugarIntakeHistoryRepository sugarIntakeHistoryRepository;
    
    @Autowired
    private SugarGoalsRepository sugarGoalsRepository;
    
    @Autowired
    private IDailySugarSummaryService dailySugarSummaryService;
    
    @Override
    public ResponseMessage<SugarIntakeHistoryDto> addSugarIntakeRecord(SugarIntakeHistoryDto sugarIntakeHistoryDto) {
        try {
            SugarIntakeHistory sugarIntakeHistory = convertDtoToEntity(sugarIntakeHistoryDto);
            SugarIntakeHistory savedRecord = sugarIntakeHistoryRepository.save(sugarIntakeHistory);
            
            // update daily sugar summary (replace the core logic of the SQL trigger)
            LocalDate intakeDate = savedRecord.getConsumedAt().toLocalDate();
            dailySugarSummaryService.updateDailySugarSummary(savedRecord.getUserId(), intakeDate);
            
            SugarIntakeHistoryDto resultDto = convertEntityToDto(savedRecord);
            return ResponseMessage.success(201, "Sugar record added successfully", resultDto);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to add sugar intake record: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<SugarIntakeHistoryDto> updateSugarIntakeRecord(Integer intakeId, SugarIntakeHistoryDto sugarIntakeHistoryDto) {
        try {
            Optional<SugarIntakeHistory> existingRecord = sugarIntakeHistoryRepository.findById(intakeId);
            if (!existingRecord.isPresent()) {
                return new ResponseMessage<>(404, "Sugar intake record not found with ID: " + intakeId, null);
            }
            
            SugarIntakeHistory sugarIntakeHistory = existingRecord.get();
            LocalDate oldDate = sugarIntakeHistory.getConsumedAt().toLocalDate();
            
            updateEntityFromDto(sugarIntakeHistory, sugarIntakeHistoryDto);
            SugarIntakeHistory updatedRecord = sugarIntakeHistoryRepository.save(sugarIntakeHistory);
            
            // update daily sugar summary (replace the core logic of the SQL trigger)
            LocalDate newDate = updatedRecord.getConsumedAt().toLocalDate();
            
            // if the date changes, update the summaries for both dates
            if (!oldDate.equals(newDate)) {
                dailySugarSummaryService.updateDailySugarSummary(updatedRecord.getUserId(), oldDate);
                dailySugarSummaryService.updateDailySugarSummary(updatedRecord.getUserId(), newDate);
            } else {
                // only update the summary for the current date
                dailySugarSummaryService.updateDailySugarSummary(updatedRecord.getUserId(), newDate);
            }
            
            SugarIntakeHistoryDto resultDto = convertEntityToDto(updatedRecord);
            return ResponseMessage.success(resultDto);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to update sugar intake record: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<String> deleteSugarIntakeRecord(Integer intakeId) {
        try {
            Optional<SugarIntakeHistory> recordOpt = sugarIntakeHistoryRepository.findById(intakeId);
            if (!recordOpt.isPresent()) {
                return new ResponseMessage<>(404, "Sugar intake record not found with ID: " + intakeId, null);
            }
            
            SugarIntakeHistory record = recordOpt.get();
            Integer userId = record.getUserId();
            LocalDate intakeDate = record.getConsumedAt().toLocalDate();
            
            sugarIntakeHistoryRepository.deleteById(intakeId);
            
            // update daily sugar summary (replace the core logic of the SQL trigger)
            dailySugarSummaryService.updateDailySugarSummary(userId, intakeDate);
            
            return ResponseMessage.success("Sugar intake record deleted successfully");
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to delete sugar intake record: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<SugarIntakeHistoryDto> getSugarIntakeRecordById(Integer intakeId) {
        try {
            Optional<SugarIntakeHistory> record = sugarIntakeHistoryRepository.findById(intakeId);
            if (!record.isPresent()) {
                return new ResponseMessage<>(404, "Sugar intake record not found with ID: " + intakeId, null);
            }
            
            SugarIntakeHistoryDto resultDto = convertEntityToDto(record.get());
            return ResponseMessage.success(resultDto);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve sugar intake record: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByUserId(Integer userId) {
        try {
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository.findByUserIdOrderByConsumedAtDesc(userId);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByUserIdAndTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime) {
        try {
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository
                    .findByUserIdAndConsumedAtBetween(userId, startTime, endTime);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve sugar intake records: " + e.getMessage(), null);
        }
    }
    

    
    @Override
    public ResponseMessage<Float> calculateTotalSugarIntakeByTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime) {
        try {
            Float totalSugar = sugarIntakeHistoryRepository
                    .calculateTotalSugarIntakeByUserIdAndTimeRange(userId, startTime, endTime);
            return ResponseMessage.success(totalSugar);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to calculate total sugar intake: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<Float> calculateTodayTotalSugarIntake(Integer userId) {
        try {
            Float totalSugar = sugarIntakeHistoryRepository.calculateTodayTotalSugarIntakeByUserId(userId);
            return ResponseMessage.success(totalSugar);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to calculate today's total sugar intake: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> getRecentSugarIntakeRecords(Integer userId, Integer limit) {
        try {
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository
                    .findRecentRecordsByUserId(userId, limit);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve recent sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> searchSugarIntakeRecordsByFoodName(Integer userId, String foodName) {
        try {
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository
                    .findByUserIdAndFoodNameContainingIgnoreCaseOrderByConsumedAtDesc(userId, foodName);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to search sugar intake records: " + e.getMessage(), null);
        }
    }

    @Override
    public ResponseMessage<String> deleteAllSugarIntakeRecordsByUserId(Integer userId) {
        try {
            sugarIntakeHistoryRepository.deleteByUserId(userId);
            return ResponseMessage.success("All sugar intake records deleted successfully");
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to delete sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<String> deleteSugarIntakeRecordsByUserIdAndTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime) {
        try {
            sugarIntakeHistoryRepository.deleteByUserIdAndConsumedAtBetween(userId, startTime, endTime);
            return ResponseMessage.success("Sugar intake records deleted successfully");
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to delete sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<Boolean> hasUserSugarIntakeRecords(Integer userId) {
        try {
            boolean hasRecords = sugarIntakeHistoryRepository.existsByUserId(userId);
            return ResponseMessage.success(hasRecords);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to check user records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<Long> countSugarIntakeRecordsByUserId(Integer userId) {
        try {
            long count = sugarIntakeHistoryRepository.countByUserId(userId);
            return ResponseMessage.success(count);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to count sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<Long> countSugarIntakeRecordsByUserIdAndTimeRange(
            Integer userId, LocalDateTime startTime, LocalDateTime endTime) {
        try {
            long count = sugarIntakeHistoryRepository
                    .countByUserIdAndConsumedAtBetween(userId, startTime, endTime);
            return ResponseMessage.success(count);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to count sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByUserIdAndDate(Integer userId, String date) {
        try {
            Date sqlDate = Date.valueOf(LocalDate.parse(date));
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository
                    .findByUserIdAndDate(userId, sqlDate);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<Map<String, Object>>> getDailySugarIntakeStats(Integer userId) {
        try {
            LocalDateTime startDate = LocalDateTime.now().minusDays(30);
            List<Object[]> rawStats = sugarIntakeHistoryRepository.getDailySugarIntakeStats(userId, startDate);
            
            List<Map<String, Object>> stats = rawStats.stream()
                    .map(row -> {
                        Map<String, Object> stat = new HashMap<>();
                        stat.put("date", row[0]);
                        stat.put("totalSugar", row[1]);
                        return stat;
                    })
                    .collect(Collectors.toList());
            
            return ResponseMessage.success(stats);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve daily sugar intake statistics: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> addBatchSugarIntakeRecords(List<SugarIntakeHistoryDto> sugarIntakeHistoryDtos) {
        try {
            List<SugarIntakeHistory> entities = sugarIntakeHistoryDtos.stream()
                    .map(this::convertDtoToEntity)
                    .collect(Collectors.toList());
            
            List<SugarIntakeHistory> savedRecords = sugarIntakeHistoryRepository.saveAll(entities);
            List<SugarIntakeHistoryDto> resultDtos = savedRecords.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to add batch sugar intake records: " + e.getMessage(), null);
        }
    }
    
    // helper method: convert DTO to Entity
    private SugarIntakeHistory convertDtoToEntity(SugarIntakeHistoryDto dto) {
        SugarIntakeHistory entity = new SugarIntakeHistory();
        entity.setIntakeId(dto.getIntakeId());
        entity.setUserId(dto.getUserId());
        entity.setFoodName(dto.getFoodName());
        entity.setSugarAmountMg(dto.getSugarAmountMg());
        entity.setQuantity(1.0f); // by default, the quantity is 1, because the frontend has already calculated the total sugar intake
        entity.setConsumedAt(dto.getIntakeTime()); // DTO的intakeTime映射到Entity的consumedAt
        // entity.setBarcode(dto.getBarcode());
        entity.setCreatedAt(dto.getCreatedAt());
        return entity;
    }
    
    // helper method: convert Entity to DTO
    private SugarIntakeHistoryDto convertEntityToDto(SugarIntakeHistory entity) {
        SugarIntakeHistoryDto dto = new SugarIntakeHistoryDto();
        dto.setIntakeId(entity.getIntakeId());
        dto.setUserId(entity.getUserId());
        dto.setFoodName(entity.getFoodName());
        dto.setSugarAmountMg(entity.getSugarAmountMg());
        dto.setIntakeTime(entity.getConsumedAt()); // Entity的consumedAt映射到DTO的intakeTime
        // dto.setBarcode(entity.getBarcode());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }
    
    // helper method: update Entity from DTO
    private void updateEntityFromDto(SugarIntakeHistory entity, SugarIntakeHistoryDto dto) {
        if (dto.getFoodName() != null) {
            entity.setFoodName(dto.getFoodName());
        }
        if (dto.getSugarAmountMg() != null) {
            entity.setSugarAmountMg(dto.getSugarAmountMg());
        }
        // if (dto.getBarcode() != null) {
        //     entity.setBarcode(dto.getBarcode());
        // }
    }
    
    @Override
    public ResponseMessage<Map<String, Object>> getDailySugarTrackingData(Integer userId, String date) {
        try {
            String targetDate;
            LocalDate queryDate;

            if (date != null && !date.isEmpty()) {
                targetDate = date;
                queryDate = LocalDate.parse(date);
            } else {
                targetDate = LocalDate.now().toString();
                queryDate = LocalDate.now();
            }

            // get the summary data from the daily_sugar_summary table first
            Float currentIntakeMg = 0.0f;
            Float dailyGoalMg = 30000.0f; // default 30g
            Float progressPercentage = 0.0f;
            String status = "on_track";

            ResponseMessage<DailySugarSummaryDto> summaryResponse = dailySugarSummaryService.getDailySummaryByDate(userId, queryDate);
            
            if (summaryResponse.getCode() == 200 && summaryResponse.getData() != null) {
                // get the data from the summary table
                DailySugarSummaryDto summary = summaryResponse.getData();
                currentIntakeMg = summary.getTotalIntakeMg().floatValue();
                dailyGoalMg = summary.getDailyGoalMg().floatValue();
                progressPercentage = summary.getProgressPercentage().floatValue();
                
                // map the status
                switch (summary.getStatus()) {
                    case GOOD:
                        status = "on_track";
                        break;
                    case WARNING:
                        status = "warning";
                        break;
                    case OVER_LIMIT:
                        status = "over_limit";
                        break;
                    default:
                        status = "on_track";
                }
            } else {
                // if the summary table has no data, calculate from the detailed records
                List<SugarIntakeHistory> dailyRecords;
                if (date != null && !date.isEmpty()) {
                    Date sqlDate = Date.valueOf(queryDate);
                    dailyRecords = sugarIntakeHistoryRepository.findByUserIdAndDate(userId, sqlDate);
                } else {
                    dailyRecords = sugarIntakeHistoryRepository.findByUserIdAndCurrentDate(userId);
                }
                
                currentIntakeMg = dailyRecords.stream()
                        .map(SugarIntakeHistory::getSugarAmountMg)
                        .reduce(0.0f, Float::sum);
                
                // obtain the user's sugar goal
                SugarGoals userGoal = sugarGoalsRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
                dailyGoalMg = (userGoal != null && userGoal.getDailyGoalMg() != null) ? 
                        userGoal.getDailyGoalMg().floatValue() : 30000.0f;
                
                // calculate the progress percentage
                progressPercentage = dailyGoalMg > 0 ? (currentIntakeMg / dailyGoalMg) * 100.0f : 0.0f;
                progressPercentage = Math.round(progressPercentage * 10.0f) / 10.0f;
                
                // determine the status
                if (progressPercentage <= 75.0f) {
                    status = "on_track";
                } else if (progressPercentage <= 100.0f) {
                    status = "warning";
                } else {
                    status = "over_limit";
                }
            }

            // get the detailed records from the sugar_intake_history table as topContributors
            List<SugarIntakeHistory> dailyRecords;
            if (date != null && !date.isEmpty()) {
                Date sqlDate = Date.valueOf(queryDate);
                dailyRecords = sugarIntakeHistoryRepository.findByUserIdAndDate(userId, sqlDate);
            } else {
                dailyRecords = sugarIntakeHistoryRepository.findByUserIdAndCurrentDate(userId);
            }
            
            // build the top contributors list
            List<Map<String, Object>> topContributors = new ArrayList<>();
            
            // sort by sugar amount and get the top 5
            dailyRecords.stream()
                    .sorted((a, b) -> Float.compare(b.getSugarAmountMg(), a.getSugarAmountMg()))
                    .limit(5)
                    .forEach(record -> {
                        Map<String, Object> contributor = new HashMap<>();
                        contributor.put("id", record.getIntakeId()); // int类型，直接返回Integer
                        contributor.put("foodName", record.getFoodName());
                        contributor.put("sugarAmountMg", Math.round(record.getSugarAmountMg()));
                        contributor.put("quantity", record.getQuantity() != null ? record.getQuantity() : 1.0f);
                        contributor.put("totalSugarAmount", Math.round(record.getSugarAmountMg() * (record.getQuantity() != null ? record.getQuantity() : 1.0f))); // 新增计算字段
                        contributor.put("consumedAt", record.getConsumedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")));
                        
                        topContributors.add(contributor);
                    });
            
            // build the response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("date", targetDate);
            responseData.put("currentIntakeMg", Math.round(currentIntakeMg));
            responseData.put("dailyGoalMg", Math.round(dailyGoalMg));
            responseData.put("progressPercentage", progressPercentage);
            // responseData.put("remainingMg", Math.round(remainingMg));
            responseData.put("status", status);
            responseData.put("topContributors", topContributors);
            
            return ResponseMessage.success(responseData);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to get daily sugar tracking data: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<MonthlyStatsDto> getMonthlySugarStats(Integer userId, String month) {
        try {
            // parse the month parameter (format: yyyy-MM)
            YearMonth yearMonth = YearMonth.parse(month);
            int year = yearMonth.getYear();
            int monthValue = yearMonth.getMonthValue();
            
            // get the user's sugar goal
            SugarGoals userGoal = sugarGoalsRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
            Double dailyGoalMg = (userGoal != null && userGoal.getDailyGoalMg() != null) ? 
                    userGoal.getDailyGoalMg() : 30000.0; // default 30g
            
            // get the daily sugar intake data of the month
            List<Object[]> monthlyData = sugarIntakeHistoryRepository.getMonthlyDailySugarIntakeStats(userId, year, monthValue);
            
            // build the daily data list
            List<MonthlyStatsDto.DailyDataDto> dailyDataList = new ArrayList<>();
            double totalIntake = 0.0;
            int daysWithData = 0;
            int daysOverGoal = 0;
            
            // get all the dates of the month
            LocalDate startDate = yearMonth.atDay(1);
            LocalDate endDate = yearMonth.atEndOfMonth();
            LocalDate currentDate = startDate;
            
            // create a map to quickly find the daily data
            Map<String, Double> dailyIntakeMap = new HashMap<>();
            for (Object[] data : monthlyData) {
                String dateStr = data[0].toString();
                Double intake = ((Number) data[1]).doubleValue();
                dailyIntakeMap.put(dateStr, intake);
            }
            
            String peakIntakeDay = null;
            String bestDay = null;
            double maxIntake = 0.0;
            double minIntake = Double.MAX_VALUE;
            
            // create the data items for each day of the month
            while (!currentDate.isAfter(endDate)) {
                String dateStr = currentDate.toString();
                Double dayIntake = dailyIntakeMap.getOrDefault(dateStr, 0.0);
                
                // only count the days with data
                if (dayIntake > 0) {
                    daysWithData++;
                    totalIntake += dayIntake;
                    
                    // find the day with the highest and lowest intake
                    if (dayIntake > maxIntake) {
                        maxIntake = dayIntake;
                        peakIntakeDay = dateStr;
                    }
                    if (dayIntake < minIntake) {
                        minIntake = dayIntake;
                        bestDay = dateStr;
                    }
                }
                
                boolean exceeded = dayIntake > dailyGoalMg;
                if (exceeded) {
                    daysOverGoal++;
                }
                
                dailyDataList.add(new MonthlyStatsDto.DailyDataDto(
                        dateStr,
                        (int) Math.round(dayIntake),
                        (int) Math.round(dailyGoalMg),
                        exceeded
                ));
                
                currentDate = currentDate.plusDays(1);
            }
            
            // calculate the average daily intake
            Double averageDailyIntake = daysWithData > 0 ? 
                    Math.round((totalIntake / daysWithData) * 10.0) / 10.0 : 0.0;
            
            // calculate the goal achievement rate (the ratio of days under the goal)
            int totalDaysInMonth = dailyDataList.size();
            Double goalAchievementRate = totalDaysInMonth > 0 ? 
                    Math.round(((double)(totalDaysInMonth - daysOverGoal) / totalDaysInMonth) * 100.0 * 10.0) / 10.0 : 0.0;
            
            // calculate the trends data (simplified implementation)
            int improvingDays = calculateImprovingDays(dailyDataList);
            int worseningDays = calculateWorseningDays(dailyDataList);
            
            MonthlyStatsDto.TrendsDto trends = new MonthlyStatsDto.TrendsDto(
                    improvingDays,
                    worseningDays,
                    peakIntakeDay,
                    bestDay
            );
            
            MonthlyStatsDto result = new MonthlyStatsDto(
                    month,
                    averageDailyIntake,
                    goalAchievementRate,
                    daysWithData,
                    dailyDataList,
                    trends
            );
            
            return ResponseMessage.success(result);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to get monthly sugar statistics: " + e.getMessage(), null);
        }
    }
    
    /**
     * calculate the improving days (simplified implementation: consecutive days of decreasing intake)
     */
    private int calculateImprovingDays(List<MonthlyStatsDto.DailyDataDto> dailyData) {
        int improvingDays = 0;
        for (int i = 1; i < dailyData.size(); i++) {
            Integer currentIntake = dailyData.get(i).getIntake();
            Integer previousIntake = dailyData.get(i-1).getIntake();
            
            if (currentIntake != null && previousIntake != null && 
                currentIntake > 0 && previousIntake > 0 && 
                currentIntake < previousIntake) {
                improvingDays++;
            }
        }
        return improvingDays;
    }
    
    /**
     * calculate the worsening days (simplified implementation: consecutive days of increasing intake)
     */
    private int calculateWorseningDays(List<MonthlyStatsDto.DailyDataDto> dailyData) {
        int worseningDays = 0;
        for (int i = 1; i < dailyData.size(); i++) {
            Integer currentIntake = dailyData.get(i).getIntake();
            Integer previousIntake = dailyData.get(i-1).getIntake();
            
            if (currentIntake != null && previousIntake != null && 
                currentIntake > 0 && previousIntake > 0 && 
                currentIntake > previousIntake) {
                worseningDays++;
            }
        }
        return worseningDays;
    }
    
    @Override
    public ResponseMessage<Map<String, Object>> getSugarIntakeHistoryStats(Integer userId, String period) {
        System.out.println("getSugarIntakeHistoryStats");
        try {
            // calculate date range based on period - calculate by day, not considering specific time
            LocalDate today = LocalDate.now();
            LocalDate startLocalDate;
            LocalDate endLocalDate = today; // 结束日期是今天
            
            switch (period.toLowerCase()) {
                case "week":
                    startLocalDate = today.minusDays(6); // today + 6 days
                    break;
                case "month":
                    startLocalDate = today.minusDays(29); // today + 29 days
                    break;
                case "year":
                    startLocalDate = today.minusDays(364); // today + 364 days
                    break;
                default:
                    startLocalDate = today.minusDays(6); // default to week
                    break;
            }
            
            // convert to LocalDateTime, start time is 00:00:00, end time is 23:59:59
            LocalDateTime startDate = startLocalDate.atStartOfDay(); // 00:00:00
            LocalDateTime endDate = endLocalDate.atTime(23, 59, 59); // 23:59:59
            
            // get user's sugar goal
            SugarGoals userGoal = sugarGoalsRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
            System.out.println("userGoal: " + userGoal.getDailyGoalMg());
            Float dailyGoalMg = (userGoal != null && userGoal.getDailyGoalMg() != null) ? 
                    userGoal.getDailyGoalMg().floatValue() : 30000.0f; // default 30g
            
            // First check what time range we're using
            System.out.println("Querying time range: " + startDate + " to " + endDate);
            
            // get records within the period
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository
                    .findByUserIdAndConsumedAtBetween(userId, startDate, endDate);
            
            System.out.println("Found " + records.size() + " records in time range");
            for (SugarIntakeHistory record : records) {
                System.out.println("record: " + record.getFoodName() + " " + record.getSugarAmountMg() + " at " + record.getConsumedAt());
            }
            
            // If no records found, let's check all records for this user to debug
            if (records.isEmpty()) {
                System.out.println("No records found in range, checking all user records...");
                List<SugarIntakeHistory> allRecords = sugarIntakeHistoryRepository.findByUserIdOrderByConsumedAtDesc(userId);
                System.out.println("Total records for user " + userId + ": " + allRecords.size());
                for (SugarIntakeHistory record : allRecords) {
                    System.out.println("All records - " + record.getFoodName() + " at " + record.getConsumedAt());
                }
            }
            // calculate total intake
            Float totalIntake = records.stream()
                    .map(SugarIntakeHistory::getSugarAmountMg)
                    .reduce(0.0f, Float::sum);
            
            // calculate days tracked (days with records)
            long daysTracked = records.stream()
                    .map(record -> record.getConsumedAt().toLocalDate())
                    .distinct()
                    .count();
            
            // calculate average daily intake
            Float averageDailyIntake = daysTracked > 0 ? totalIntake / daysTracked : 0.0f;
            
            // calculate goal achievement rate
            // Count days where daily intake was within goal
            Map<LocalDate, Float> dailyIntakeMap = records.stream()
                    .collect(Collectors.groupingBy(
                            record -> record.getConsumedAt().toLocalDate(),
                            Collectors.reducing(0.0f, SugarIntakeHistory::getSugarAmountMg, Float::sum)
                    ));
            
            long daysWithinGoal = dailyIntakeMap.values().stream()
                    .mapToLong(dailyIntake -> dailyIntake <= dailyGoalMg ? 1 : 0)
                    .sum();
            
            Float goalAchievementRate = daysTracked > 0 ? 
                    (daysWithinGoal * 100.0f / daysTracked) : 100.0f;
            
            // create daily breakdown data
            List<Map<String, Object>> dailyBreakdown = new ArrayList<>();
            LocalDate currentDate = startDate.toLocalDate();
            LocalDate endDateLocal = endDate.toLocalDate();
            
            while (!currentDate.isAfter(endDateLocal)) {
                Map<String, Object> dayData = new HashMap<>();
                Float dayIntake = dailyIntakeMap.getOrDefault(currentDate, 0.0f);
                boolean achievedGoal = dayIntake <= dailyGoalMg;
                
                dayData.put("date", currentDate.toString());
                dayData.put("totalIntakeMg", Math.round(dayIntake));
                dayData.put("goalMg", Math.round(dailyGoalMg));
                dayData.put("achievedGoal", achievedGoal);
                
                dailyBreakdown.add(dayData);
                currentDate = currentDate.plusDays(1);
            }
            
            // build response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("period", period);
            responseData.put("averageDailyIntake", Math.round(averageDailyIntake * 10.0f) / 10.0f);
            responseData.put("totalIntake", Math.round(totalIntake));
            responseData.put("daysTracked", (int) daysTracked);
            responseData.put("goalAchievementRate", Math.round(goalAchievementRate * 10.0f) / 10.0f);
            responseData.put("dailyBreakdown", dailyBreakdown);
            
            return ResponseMessage.success(responseData);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to get sugar intake history statistics: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<MonthlyCalendarDto> getMonthlyCalendarData(Integer userId, Integer year, Integer month) {
        try {
            // parameter validation
            if (month < 1 || month > 12) {
                return new ResponseMessage<>(400, "Month must be between 1 and 12", null);
            }
            if (year < 2020 || year > 2100) {
                return new ResponseMessage<>(400, "Year must be between 2020 and 2100", null);
            }
            
            // get the user's sugar goal
            SugarGoals userGoal = sugarGoalsRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
            Double dailyGoalMg = (userGoal != null && userGoal.getDailyGoalMg() != null) ? 
                    userGoal.getDailyGoalMg() : 50000.0; // default 50g
            
            // use DailySugarSummaryService to query the monthly data
            List<DailySugarSummaryDto> monthlySummaries = dailySugarSummaryService
                    .getDailySummariesByDateRange(
                            userId,
                            LocalDate.of(year, month, 1),
                            LocalDate.of(year, month, 1).withDayOfMonth(
                                    LocalDate.of(year, month, 1).lengthOfMonth()
                            )
                    ).getData();
            
            // if the summary table has no data, recalculate from the history records
            if (monthlySummaries == null || monthlySummaries.isEmpty()) {
                // recalculate the monthly summary data
                LocalDate startDate = LocalDate.of(year, month, 1);
                LocalDate endDate = startDate.withDayOfMonth(startDate.lengthOfMonth());
                dailySugarSummaryService.recalculateUserSugarSummaries(userId, startDate, endDate);
                
                // recalculate the monthly summary data
                monthlySummaries = dailySugarSummaryService
                        .getDailySummariesByDateRange(userId, startDate, endDate).getData();
            }
            
            // create the calendar data
            List<MonthlyCalendarDto.DailySummaryDto> dailySummaries = new ArrayList<>();
            LocalDate startDate = LocalDate.of(year, month, 1);
            LocalDate endDate = startDate.withDayOfMonth(startDate.lengthOfMonth());
            LocalDate currentDate = startDate;
            System.out.println("startDate: " + startDate);
            System.out.println("endDate: " + endDate);
            System.out.println("currentDate: " + currentDate);
            System.out.println("monthlySummaries: " + monthlySummaries);
            // convert the summary data to Map for quick lookup
            Map<LocalDate, DailySugarSummaryDto> summaryMap = new HashMap<>();
            if (monthlySummaries != null) {
                for (DailySugarSummaryDto summary : monthlySummaries) {
                    summaryMap.put(summary.getDate(), summary);
                }
            }
            System.out.println("************************************************");
            System.out.println("summaryMap: " + summaryMap);
            // initialize the monthly statistics data
            double totalIntake = 0.0;
            int daysTracked = 0;
            int daysOverGoal = 0;
            
            // create the data for each day
            while (!currentDate.isAfter(endDate)) {
                DailySugarSummaryDto summary = summaryMap.get(currentDate);
                
                if (summary != null) {
                    // the date with data
                    double totalIntakeMg = summary.getTotalIntakeMg().doubleValue();
                    double progressPercentage = summary.getProgressPercentage().doubleValue();
                    
                    // only count the days with records
                    if (summary.getRecordCount() > 0) {
                        daysTracked++;
                        totalIntake += totalIntakeMg;
                        
                        if (totalIntakeMg > dailyGoalMg) {
                            daysOverGoal++;
                        }
                    }
                    
                    // status mapping
                    String status = mapSugarSummaryStatusToString(summary.getStatus());
                    
                    dailySummaries.add(new MonthlyCalendarDto.DailySummaryDto(
                            currentDate.toString(),
                            totalIntakeMg,
                            dailyGoalMg,
                            progressPercentage,
                            status,
                            summary.getRecordCount()
                    ));
                } else {
                    // the date with no data, return the default value
                    dailySummaries.add(new MonthlyCalendarDto.DailySummaryDto(
                            currentDate.toString(),
                            0.0,
                            dailyGoalMg,
                            0.0,
                            "GOOD",
                            0
                    ));
                }
                
                currentDate = currentDate.plusDays(1);
            }
            
            // calculate the monthly average intake
            Double monthlyAverageIntake = daysTracked > 0 ? 
                    Math.round((totalIntake / daysTracked) * 10.0) / 10.0 : 0.0;
            
            // calculate the overall achievement rate
            Double overallAchievementRate = daysTracked > 0 ?
                    Math.round(((double)(daysTracked - daysOverGoal) / daysTracked) * 100.0 * 10.0) / 10.0 : 100.0;
            
            // build the response
            MonthlyCalendarDto result = new MonthlyCalendarDto(
                    year,
                    month,
                    monthlyAverageIntake,
                    daysTracked,
                    daysOverGoal,
                    overallAchievementRate,
                    dailySummaries
            );
            
            return ResponseMessage.success(result);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to get monthly calendar data: " + e.getMessage(), null);
        }
    }
    
    /**
     * status mapping helper method
     */
    private String mapSugarSummaryStatusToString(org.user.enums.SugarSummaryStatus status) {
        if (status == null) {
            return "GOOD";
        }
        switch (status) {
            case GOOD:
                return "GOOD";
            case WARNING:
                return "WARNING";
            case OVER_LIMIT:
                return "OVER_LIMIT";
            default:
                return "GOOD";
        }
    }
} 