package org.user.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.user.pojo.SugarGoals;
import org.user.pojo.DTO.SugarGoalResponseDto;
import org.user.pojo.DTO.SugarGoalRequestDto;
import org.user.repository.SugarGoalsRepository;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
public class SugarTrackingService implements ISugarTrackingService {
    
    @Autowired
    private SugarGoalsRepository sugarGoalsRepository;
    
    @Override
    public SugarGoalResponseDto getUserSugarGoal(Integer userId) {
        // find user's current active sugar goal
        SugarGoals activeGoal = sugarGoalsRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
        
        if (activeGoal != null) {
            return new SugarGoalResponseDto(
                    activeGoal.getDailyGoalMg(),
                    activeGoal.getGoalLevel(),
                    activeGoal.getCreatedAt(),
                    activeGoal.getUpdatedAt()
            );
        } else {
            // if no goal is set, return default goal
            String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            return new SugarGoalResponseDto(
                    25000.0, // default daily goal: 25g
                    currentTime,
                    currentTime
            );
        }
    }
    
    @Override
    public SugarGoalResponseDto setUserSugarGoal(Integer userId, SugarGoalRequestDto goalRequestDto) {
        String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        
        // check if user has existing goal
        SugarGoals existingGoal = sugarGoalsRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
        
        if (existingGoal != null) {
            // update existing goal
            existingGoal.setDailyGoalMg(goalRequestDto.getDailyGoalMg());
            existingGoal.setGoalLevel(goalRequestDto.getGoalLevel());
            existingGoal.setUpdatedAt(currentTime);
            SugarGoals savedGoal = sugarGoalsRepository.save(existingGoal);
            
            return new SugarGoalResponseDto(
                    savedGoal.getDailyGoalMg(),
                    savedGoal.getGoalLevel(),
                    savedGoal.getCreatedAt(),
                    savedGoal.getUpdatedAt()
            );
        } else {
            // create new goal
            SugarGoals newGoal = new SugarGoals();
            newGoal.setUserId(userId);
            newGoal.setDailyGoalMg(goalRequestDto.getDailyGoalMg());
            newGoal.setGoalLevel(goalRequestDto.getGoalLevel());
            newGoal.setCreatedAt(currentTime);
            newGoal.setUpdatedAt(currentTime);
            SugarGoals savedGoal = sugarGoalsRepository.save(newGoal);
            
            return new SugarGoalResponseDto(
                    savedGoal.getDailyGoalMg(),
                    savedGoal.getGoalLevel(),
                    savedGoal.getCreatedAt(),
                    savedGoal.getUpdatedAt()
            );
        }
    }
} 