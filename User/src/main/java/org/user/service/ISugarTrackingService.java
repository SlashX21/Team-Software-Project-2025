package org.user.service;

import org.user.pojo.DTO.SugarGoalResponseDto;
import org.user.pojo.DTO.SugarGoalRequestDto;

public interface ISugarTrackingService {
    
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
} 