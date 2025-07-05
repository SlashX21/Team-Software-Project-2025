package org.user.service;

import org.user.pojo.UserPreference;
import org.user.pojo.DTO.UserPreferenceDto;
import org.user.enums.PreferenceSource;

import java.util.List;
import java.util.Map;

public interface IUserPreferenceService {
    
    /**
     * get user preference
     * @param userId user id
     * @return user preference
     */
    Map<String, Object> getUserPreference(Integer userId);
    
    /**
     * create or update user preference
     * @param userPreferenceDto user preference DTO
     * @return saved user preference
     */
    UserPreferenceDto saveOrUpdateUserPreference(UserPreferenceDto userPreferenceDto);
    
    /**
     * delete user preference
     * @param userId user id
     */
    void deleteUserPreference(Integer userId);
    
    /**
     * generate user preference from behavior
     * @param userId user id
     * @return system inferred user preference
     */
    UserPreferenceDto generatePreferenceFromBehavior(Integer userId);
    
    /**
     * update user preference field
     * @param userId user id
     * @param preferenceType preference type
     * @param value preference value
     * @return updated user preference
     */
    UserPreferenceDto updatePreferenceField(Integer userId, String preferenceType, Boolean value);
    
    /**
     * get user preference stats
     * @param userId user id
     * @return user preference stats
     */
    Map<String, Object> getUserPreferenceStats(Integer userId);
    
    /**
     * get batch user preferences
     * @param userIds user id list
     * @return user preference list
     */
    List<UserPreferenceDto> getBatchUserPreferences(List<Integer> userIds);
    
    /**
     * find users by preference type
     * @param preferenceType preference type
     * @return user id list
     */
    List<Integer> findUsersByPreferenceType(String preferenceType);
    
    /**
     * merge system inferred and user manual preferences
     * @param userId user id
     * @return merged preferences
     */
    UserPreferenceDto mergePreferences(Integer userId);
    
    /**
     * check if user has preference
     * @param userId user id
     * @return true if user has preference, false otherwise
     */
    boolean hasUserPreference(Integer userId);
    
    /**
     * reset user preference to default value
     * @param userId user id
     * @return reset user preference
     */
    UserPreferenceDto resetUserPreference(Integer userId);
    
    /**
     * export user preference data
     * @param userId user id
     * @return preference data map
     */
    Map<String, Object> exportUserPreferenceData(Integer userId);
    
    /**
     * import user preference data
     * @param userId user id
     * @param preferenceData preference data
     * @return imported user preference
     */
    UserPreferenceDto importUserPreferenceData(Integer userId, Map<String, Object> preferenceData);
} 