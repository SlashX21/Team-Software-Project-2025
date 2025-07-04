package org.user.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.user.pojo.SugarGoals;
import org.user.pojo.SugarRecords;
import org.user.pojo.DTO.SugarTrackingDto;
import org.user.pojo.DTO.SugarRecordsDto;
import org.user.pojo.DTO.SugarHistoryStatsDto;
import org.user.pojo.DTO.SugarGoalResponseDto;
import org.user.pojo.DTO.SugarGoalRequestDto;
import org.user.repository.SugarGoalsRepository;
import org.user.repository.SugarRecordsRepository;

import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.ZonedDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

@Service
public class SugarTrackingService implements ISugarTrackingService {
    
    @Autowired
    private SugarRecordsRepository sugarRecordsRepository;
    
    @Autowired
    private SugarGoalsRepository sugarGoalsRepository;
    
    @Override
    public SugarTrackingDto getDailySugarTracking(Integer userId, Date date) {
        // obtain user's daily records
        List<SugarRecords> dailyRecords = sugarRecordsRepository.findByUserIdAndDate(userId, date);
        
        // calculate current daily intake
        Double currentIntakeMg = dailyRecords.stream()
                .mapToDouble(record -> {
                    Double sugar = record.getSugarAmountMg() != null ? record.getSugarAmountMg() : 0.0;
                    Double quantity = record.getQuantity() != null ? record.getQuantity() : 1.0;
                    return sugar * quantity;
                })
                .sum();
        
        // obtain user's daily sugar goal
        SugarGoals activeGoal = sugarGoalsRepository.findByUserIdAndIsActiveTrue(userId);
        Double dailyGoalMg = activeGoal != null ? activeGoal.getDailyGoalMg() : 25000.0; // 默认25g
        
        // calculate progress percentage
        Double progressPercentage = dailyGoalMg > 0 ? Math.round((currentIntakeMg / dailyGoalMg) * 100.0 * 10.0) / 10.0 : 0.0;
        
        // determine status
        String status = determineStatus(progressPercentage);
        
        // obtain top 5 contributors
        List<SugarTrackingDto.TopContributorDto> topContributors = dailyRecords.stream()
                .map(record -> {
                    Double totalSugar = (record.getSugarAmountMg() != null ? record.getSugarAmountMg() : 0.0) * 
                                       (record.getQuantity() != null ? record.getQuantity() : 1.0);
                    return new SugarTrackingDto.TopContributorDto(
                            "sugar_" + String.format("%03d", record.getRecordId()),
                            record.getFoodName(),
                            totalSugar,
                            record.getQuantity(),
                            record.getConsumedAt(),
                            record.getProductBarcode()
                    );
                })
                .sorted((a, b) -> Double.compare(b.getSugarAmountMg(), a.getSugarAmountMg()))
                .limit(5)
                .collect(Collectors.toList());
        
        // format date time
        String formattedDate = date.toString();
        
        return new SugarTrackingDto(
                Math.round(currentIntakeMg * 10.0) / 10.0,
                dailyGoalMg,
                progressPercentage,
                status,
                formattedDate,
                topContributors
        );
    }
    
    /**
     * determine status based on progress percentage
     */
    private String determineStatus(Double progressPercentage) {
        if (progressPercentage <= 75.0) {
            return "good";
        } else if (progressPercentage <= 100.0) {
            return "warning";
        } else {
            return "over";
        }
    }
    
    @Override
    public SugarRecords addSugarRecord(SugarRecordsDto sugarRecordDto) {
        // convert DTO to entity
        SugarRecords sugarRecord = new SugarRecords();
        sugarRecord.setUserId(sugarRecordDto.getUserId());
        sugarRecord.setFoodName(sugarRecordDto.getFoodName());
        sugarRecord.setSugarAmountMg(sugarRecordDto.getSugarAmountMg());
        sugarRecord.setQuantity(sugarRecordDto.getQuantity());
        sugarRecord.setConsumedAt(sugarRecordDto.getConsumedAt());

        // TODO: product barcode, source, notes are not in the DTO
        sugarRecord.setProductBarcode(sugarRecordDto.getProductBarcode());
        sugarRecord.setSource(sugarRecordDto.getSource());
        sugarRecord.setNotes(sugarRecordDto.getNotes());
        
        // set created time
        String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        sugarRecord.setCreatedAt(currentTime);
        
        // if consumedAt is not set, use current time
        if (sugarRecord.getConsumedAt() == null || sugarRecord.getConsumedAt().isEmpty()) {
            sugarRecord.setConsumedAt(currentTime);
        } else {
            // convert ISO 8601 format to MySQL DATETIME format
            String convertedTime = convertIsoToDateTime(sugarRecord.getConsumedAt());
            sugarRecord.setConsumedAt(convertedTime);
        }
        System.out.println("consumedAt after conversion: " + sugarRecord.getConsumedAt());
        // save to database
        return sugarRecordsRepository.save(sugarRecord);
    }
    
    @Override
    public SugarHistoryStatsDto getSugarHistoryStats(Integer userId, String period) {
        // calculate date range
        LocalDate endDate = LocalDate.now();
        LocalDate startDate;
        
        switch (period.toLowerCase()) {
            case "week":
                startDate = endDate.minusDays(6); // include today, total 7 days
                break;
            case "month":
                startDate = endDate.minusDays(29); // include today, total 30 days
                break;
            case "year":
                startDate = endDate.minusDays(364); // include today, total 365 days
                break;
            default:
                startDate = endDate.minusDays(6); // default: 1 week
                break;
        }
        
        String startDateStr = startDate.toString();
        String endDateStr = endDate.toString();
        Date sqlStartDate = Date.valueOf(LocalDate.parse(startDateStr));
        Date sqlEndDate = Date.valueOf(LocalDate.parse(endDateStr));
        
        // obtain user's daily sugar goal
        SugarGoals activeGoal = sugarGoalsRepository.findByUserIdAndIsActiveTrue(userId);
        Double dailyGoalMg = activeGoal != null ? activeGoal.getDailyGoalMg() : 25000.0;
        // obtain daily sugar intake data in date range
        List<Object[]> dailyIntakeData = sugarRecordsRepository.getDailySugarIntakeInRange(userId, sqlStartDate, sqlEndDate);

        // build daily data list
        List<SugarHistoryStatsDto.DailyDataDto> dailyDataList = new ArrayList<>();
        Double totalIntake = 0.0;
        Integer daysOverGoal = 0;
        
        // create data item for each day (even if there is no record)
        LocalDate currentDate = startDate;
        // System.out.println("currentDate: " + currentDate);
        // System.out.println("endDate: " + endDate);
        // if (dailyIntakeData.size() > 0) {
        //     System.out.println("dailyIntakeData.size(): " + dailyIntakeData.size());
        // } else {
        //     System.out.println("dailyIntakeData is empty");
        // }
        // System.out.println("********************");
        while (!currentDate.isAfter(endDate)) {
            String dateStr = currentDate.toString();
            Double dayIntake = 0.0;
            // System.out.println("dateStr: " + dateStr);

            // find the intake of the date
            for (Object[] data : dailyIntakeData) {
                String recordDate = data[0].toString();
                // System.out.println("recordDate: " + recordDate);
                // for (Object a: data) {
                //     System.out.println("数据: " + a);
                // }
                if (recordDate.equals(dateStr)) {
                    dayIntake = ((Number) data[1]).doubleValue();
                    break;
                }
            }
            
            dailyDataList.add(new SugarHistoryStatsDto.DailyDataDto(
                    dateStr + "T00:00:00Z",
                    Math.round(dayIntake * 10.0) / 10.0,
                    dailyGoalMg
            ));
            
            totalIntake += dayIntake;
            if (dayIntake > dailyGoalMg) {
                daysOverGoal++;
            }
            
            currentDate = currentDate.plusDays(1);
            // System.out.println("_____________________");
        }
        
        // calculate average daily intake
        Double averageDailyIntake = dailyDataList.size() > 0 ? 
                Math.round((totalIntake / dailyDataList.size()) * 10.0) / 10.0 : 0.0;
        
        // obtain top food sources
        List<Object[]> topFoodData = sugarRecordsRepository.getTopFoodSourcesInRange(userId, sqlStartDate, sqlEndDate);
        List<String> topFoodSources = topFoodData.stream()
                .limit(4) // get top 4
                .map(data -> data[0].toString())
                .collect(Collectors.toList());
        
        return new SugarHistoryStatsDto(
                dailyDataList,
                averageDailyIntake,
                Math.round(totalIntake * 10.0) / 10.0,
                daysOverGoal,
                topFoodSources
        );
    }
    
    @Override
    public SugarGoalResponseDto getUserSugarGoal(Integer userId) {
        // obtain user's active sugar goal
        SugarGoals activeGoal = sugarGoalsRepository.findByUserIdAndIsActiveTrue(userId);
        
        if (activeGoal != null) {
            // convert time format to ISO 8601
            String createdAtIso = convertToIsoDateTime(activeGoal.getCreatedAt());
            String updatedAtIso = convertToIsoDateTime(activeGoal.getUpdatedAt());
            
            return new SugarGoalResponseDto(
                    activeGoal.getDailyGoalMg(),
                    activeGoal.getGoalLevel(),
                    createdAtIso,
                    updatedAtIso,
                    activeGoal.isIsActive()
            );
        } else {
            // if user has no goal, return default value
            String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
            return new SugarGoalResponseDto(
                    25000.0, // default 25g
                    null,
                    currentTime,
                    currentTime,
                    false
            );
        }
    }
    
    @Override
    public SugarGoalResponseDto setUserSugarGoal(Integer userId, SugarGoalRequestDto goalRequestDto) {
        // obtain user's active goal
        SugarGoals existingGoal = sugarGoalsRepository.findByUserIdAndIsActiveTrue(userId);
        
        String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        System.out.println("existingGoal: " + existingGoal);
        if (existingGoal != null) {
            // update existing goal
            existingGoal.setDailyGoalMg(goalRequestDto.getDailyGoalMg());
            System.out.println("goalRequestDto.getGoalLevel(): " + goalRequestDto.getGoalLevel());
            if (goalRequestDto.getGoalLevel() != null) {
                existingGoal.setGoalLevel(goalRequestDto.getGoalLevel());
            }
            existingGoal.setUpdatedAt(currentTime);
            
            SugarGoals savedGoal = sugarGoalsRepository.save(existingGoal);
            
            // convert to response DTO
            String createdAtIso = convertToIsoDateTime(savedGoal.getCreatedAt());
            String updatedAtIso = convertToIsoDateTime(savedGoal.getUpdatedAt());
            
            return new SugarGoalResponseDto(
                    savedGoal.getDailyGoalMg(),
                    createdAtIso,
                    updatedAtIso
            );
        } else {
            // create new goal
            SugarGoals newGoal = new SugarGoals();
            newGoal.setUserId(userId);
            newGoal.setDailyGoalMg(goalRequestDto.getDailyGoalMg());
            newGoal.setGoalLevel(goalRequestDto.getGoalLevel());
            newGoal.setCreatedAt(currentTime);
            newGoal.setUpdatedAt(currentTime);
            newGoal.setIsActive(true);
            
            SugarGoals savedGoal = sugarGoalsRepository.save(newGoal);
            
            // convert to response DTO
            String createdAtIso = convertToIsoDateTime(savedGoal.getCreatedAt());
            String updatedAtIso = convertToIsoDateTime(savedGoal.getUpdatedAt());
            
            return new SugarGoalResponseDto(
                    savedGoal.getDailyGoalMg(),
                    createdAtIso,
                    updatedAtIso
            );
        }
    }
    
    @Override
    public boolean deleteSugarRecord(Integer userId, Integer recordId) {
        try {
            // find record if it exists and belongs to the user
            SugarRecords record = sugarRecordsRepository.findById(recordId).orElse(null);
            
            if (record == null) {
                throw new RuntimeException("Sugar record not found with id: " + recordId);
            }
            
            if (!record.getUserId().equals(userId)) {
                throw new RuntimeException("Sugar record does not belong to user: " + userId);
            }
            
            // delete record
            sugarRecordsRepository.delete(record);
            return true;
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete sugar record: " + e.getMessage());
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
     * format date time
     */
    private String formatDateTime(String date) {
        try {
            return date + "T00:00:00Z";
        } catch (Exception e) {
            // if date format is wrong, return current time
            return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'"));
        }
    }
} 