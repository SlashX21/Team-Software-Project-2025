package org.user.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.user.pojo.SugarIntakeHistory;
import org.user.pojo.DTO.SugarIntakeHistoryDto;
import org.user.pojo.DTO.ResponseMessage;
import org.user.pojo.DTO.MonthlyStatsDto;
import org.user.repository.SugarIntakeHistoryRepository;
import org.user.repository.SugarGoalsRepository;
import org.user.pojo.SugarGoals;
import org.user.enums.SourceType;

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
    
    @Override
    public ResponseMessage<SugarIntakeHistoryDto> addSugarIntakeRecord(SugarIntakeHistoryDto sugarIntakeHistoryDto) {
        try {
            SugarIntakeHistory sugarIntakeHistory = convertDtoToEntity(sugarIntakeHistoryDto);
            SugarIntakeHistory savedRecord = sugarIntakeHistoryRepository.save(sugarIntakeHistory);
            SugarIntakeHistoryDto resultDto = convertEntityToDto(savedRecord);
            return ResponseMessage.success(resultDto);
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
            updateEntityFromDto(sugarIntakeHistory, sugarIntakeHistoryDto);
            SugarIntakeHistory updatedRecord = sugarIntakeHistoryRepository.save(sugarIntakeHistory);
            SugarIntakeHistoryDto resultDto = convertEntityToDto(updatedRecord);
            return ResponseMessage.success(resultDto);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to update sugar intake record: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<String> deleteSugarIntakeRecord(Integer intakeId) {
        try {
            if (!sugarIntakeHistoryRepository.existsById(intakeId)) {
                return new ResponseMessage<>(404, "Sugar intake record not found with ID: " + intakeId, null);
            }
            
            sugarIntakeHistoryRepository.deleteById(intakeId);
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
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository.findByUserIdOrderByIntakeTimeDesc(userId);
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
                    .findByUserIdAndIntakeTimeBetween(userId, startTime, endTime);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByUserIdAndSourceType(
            Integer userId, SourceType sourceType) {
        try {
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository
                    .findByUserIdAndSourceTypeOrderByIntakeTimeDesc(userId, sourceType);
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
                    .findByUserIdAndFoodNameContainingIgnoreCaseOrderByIntakeTimeDesc(userId, foodName);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to search sugar intake records: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<List<SugarIntakeHistoryDto>> getSugarIntakeRecordsByBarcode(String barcode) {
        try {
            List<SugarIntakeHistory> records = sugarIntakeHistoryRepository
                    .findByBarcodeOrderByIntakeTimeDesc(barcode);
            List<SugarIntakeHistoryDto> resultDtos = records.stream()
                    .map(this::convertEntityToDto)
                    .collect(Collectors.toList());
            return ResponseMessage.success(resultDtos);
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to retrieve sugar intake records: " + e.getMessage(), null);
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
            sugarIntakeHistoryRepository.deleteByUserIdAndIntakeTimeBetween(userId, startTime, endTime);
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
                    .countByUserIdAndIntakeTimeBetween(userId, startTime, endTime);
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
    
    // 辅助方法：DTO转Entity
    private SugarIntakeHistory convertDtoToEntity(SugarIntakeHistoryDto dto) {
        SugarIntakeHistory entity = new SugarIntakeHistory();
        entity.setIntakeId(dto.getIntakeId());
        entity.setUserId(dto.getUserId());
        entity.setFoodName(dto.getFoodName());
        entity.setSugarAmountMg(dto.getSugarAmountMg());
        entity.setIntakeTime(dto.getIntakeTime());
        entity.setSourceType(dto.getSourceType());
        entity.setBarcode(dto.getBarcode());
        entity.setServingSize(dto.getServingSize());
        entity.setCreatedAt(dto.getCreatedAt());
        return entity;
    }
    
    // 辅助方法：Entity转DTO
    private SugarIntakeHistoryDto convertEntityToDto(SugarIntakeHistory entity) {
        SugarIntakeHistoryDto dto = new SugarIntakeHistoryDto();
        dto.setIntakeId(entity.getIntakeId());
        dto.setUserId(entity.getUserId());
        dto.setFoodName(entity.getFoodName());
        dto.setSugarAmountMg(entity.getSugarAmountMg());
        dto.setIntakeTime(entity.getIntakeTime());
        dto.setSourceType(entity.getSourceType());
        dto.setBarcode(entity.getBarcode());
        dto.setServingSize(entity.getServingSize());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }
    
    // 辅助方法：从DTO更新Entity
    private void updateEntityFromDto(SugarIntakeHistory entity, SugarIntakeHistoryDto dto) {
        if (dto.getFoodName() != null) {
            entity.setFoodName(dto.getFoodName());
        }
        if (dto.getSugarAmountMg() != null) {
            entity.setSugarAmountMg(dto.getSugarAmountMg());
        }
        if (dto.getIntakeTime() != null) {
            entity.setIntakeTime(dto.getIntakeTime());
        }
        if (dto.getSourceType() != null) {
            entity.setSourceType(dto.getSourceType());
        }
        if (dto.getBarcode() != null) {
            entity.setBarcode(dto.getBarcode());
        }
        if (dto.getServingSize() != null) {
            entity.setServingSize(dto.getServingSize());
        }
    }
    
    @Override
    public ResponseMessage<Map<String, Object>> getDailySugarTrackingData(Integer userId, String date) {
        try {
            // obtain the daily records of the user
            List<SugarIntakeHistory> dailyRecords;
            String targetDate;

            if (date != null && !date.isEmpty()) {
                targetDate = date;
                Date sqlDate = Date.valueOf(LocalDate.parse(date));

                dailyRecords = sugarIntakeHistoryRepository.findByUserIdAndDate(userId, sqlDate);
            } else {
                targetDate = LocalDate.now().toString();
                dailyRecords = sugarIntakeHistoryRepository.findByUserIdAndCurrentDate(userId);
            }
            for (SugarIntakeHistory record : dailyRecords) {
                System.out.println("record: " + record.getFoodName() + " " + record.getSugarAmountMg());
            }
            // calculate the current intake
            Float currentIntakeMg = dailyRecords.stream()
                    .map(SugarIntakeHistory::getSugarAmountMg)
                    .reduce(0.0f, Float::sum);
            
            // obtain the user's sugar goal
            SugarGoals userGoal = sugarGoalsRepository.findByUserIdAndIsActiveTrue(userId);
            Float dailyGoalMg = (userGoal != null && userGoal.getDailyGoalMg() != null) ? 
                    userGoal.getDailyGoalMg().floatValue() : 30000.0f; // default 30g
            
            // calculate the progress percentage
            Float progressPercentage = dailyGoalMg > 0 ? (currentIntakeMg / dailyGoalMg) * 100.0f : 0.0f;
            progressPercentage = Math.round(progressPercentage * 10.0f) / 10.0f; // keep one decimal place
            
            // calculate the remaining amount
            Float remainingMg = Math.max(0, dailyGoalMg - currentIntakeMg);
            
            // determine the status
            String status;
            if (progressPercentage <= 75.0f) {
                status = "on_track";
            } else if (progressPercentage <= 100.0f) {
                status = "warning";
            } else {
                status = "over_limit";
            }
            
            // build the top contributors list
            List<Map<String, Object>> topContributors = new ArrayList<>();
            
            // sort by sugar amount and get the top 5
            dailyRecords.stream()
                    .sorted((a, b) -> Float.compare(b.getSugarAmountMg(), a.getSugarAmountMg()))
                    .limit(5)
                    .forEach(record -> {
                        Map<String, Object> contributor = new HashMap<>();
                        contributor.put("foodName", record.getFoodName());
                        contributor.put("sugarAmount", Math.round(record.getSugarAmountMg()));
                        
                        // calculate the percentage of this food in the total intake
                        Float percentage = currentIntakeMg > 0 ? (record.getSugarAmountMg() / currentIntakeMg) * 100.0f : 0.0f;
                        contributor.put("percentage", Math.round(percentage));
                        
                        // format the time
                        String timeStr = record.getIntakeTime().format(DateTimeFormatter.ofPattern("HH:mm"));
                        contributor.put("time", timeStr);
                        
                        topContributors.add(contributor);
                    });
            
            // build the response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("date", targetDate);
            responseData.put("currentIntakeMg", Math.round(currentIntakeMg));
            responseData.put("dailyGoalMg", Math.round(dailyGoalMg));
            responseData.put("progressPercentage", progressPercentage);
            responseData.put("remainingMg", Math.round(remainingMg));
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
            SugarGoals userGoal = sugarGoalsRepository.findByUserIdAndIsActiveTrue(userId);
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
} 