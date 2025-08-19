package org.user.service;

import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.user.pojo.UserPreference;
import org.user.pojo.DTO.UserPreferenceDto;
import org.user.pojo.User;
import org.user.repository.UserPreferenceRepository;
import org.user.repository.UserRepository;
import org.user.enums.PreferenceSource;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional
public class UserPreferenceService implements IUserPreferenceService {
    
    @Autowired
    private UserPreferenceRepository userPreferenceRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Override
    public Map<String, Object> getUserPreference(Integer userId) {
        // check if user exists
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found, ID: " + userId));
        
        // find user preference
        Optional<UserPreference> preferenceOpt = userPreferenceRepository.findByUserId(userId);
        
        UserPreferenceDto preference;
        if (preferenceOpt.isPresent()) {
            preference = convertToDto(preferenceOpt.get());
        } else {
            // if no preference, return default preference
            preference = createDefaultPreference(userId);
        }
        
        // convert to nested structure
        return convertToNestedFormat(preference);
    }
    
    @Override
    public UserPreferenceDto saveOrUpdateUserPreference(UserPreferenceDto userPreferenceDto) {
        // check if user exists
        User user = userRepository.findById(userPreferenceDto.getUserId())
            .orElseThrow(() -> new IllegalArgumentException("User not found, ID: " + userPreferenceDto.getUserId()));
        
        UserPreference userPreference;
        
        // check if preference exists
        Optional<UserPreference> existingPreference = userPreferenceRepository.findByUserId(userPreferenceDto.getUserId());
        
        if (existingPreference.isPresent()) {
            // update existing preference
            userPreference = existingPreference.get();
            BeanUtils.copyProperties(userPreferenceDto, userPreference, "preferenceId", "createdAt", "version");
            userPreference.updateTimestamp();
        } else {
            // create new preference
            userPreference = new UserPreference();
            BeanUtils.copyProperties(userPreferenceDto, userPreference, "preferenceId");
            userPreference.setCreatedAt(LocalDateTime.now());
            userPreference.setUpdatedAt(LocalDateTime.now());
        }
        
        UserPreference savedPreference = userPreferenceRepository.save(userPreference);
        return convertToDto(savedPreference);
    }
    
    @Override
    public void deleteUserPreference(Integer userId) {
        // check if user exists
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found, ID: " + userId));
        
        if (userPreferenceRepository.existsByUserId(userId)) {
            userPreferenceRepository.deleteByUserId(userId);
        } else {
            throw new IllegalArgumentException("User preference not found, ID: " + userId);
        }
    }
    
    @Override
    public UserPreferenceDto generatePreferenceFromBehavior(Integer userId) {
        // check if user exists
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found, ID: " + userId));
        
        // TODO: here should be based on user's purchase history and scan record to analyze preference
        // currently return a sample implementation
        UserPreferenceDto inferredPreference = new UserPreferenceDto(userId);
        inferredPreference.setPreferenceSource(PreferenceSource.SYSTEM_INFERRED);
        inferredPreference.setInferenceConfidence(new BigDecimal("0.75"));
        
        // simulate preference inference based on behavior analysis
        // in actual implementation, this should call the analysis service
        inferredPreference.setPreferLowSugar(true);
        inferredPreference.setPreferLowFat(false);
        inferredPreference.setPreferHighProtein(true);
        inferredPreference.setPreferLowSodium(false);
        inferredPreference.setPreferOrganic(false);
        inferredPreference.setPreferLowCalorie(true);
        
        return saveOrUpdateUserPreference(inferredPreference);
    }
    
    @Override
    public UserPreferenceDto updatePreferenceField(Integer userId, String preferenceType, Boolean value) {
        UserPreferenceDto currentPreference = getUserPreferenceDto(userId);
        
        // update specified field
        switch (preferenceType.toLowerCase()) {
            case "lowsugar":
                currentPreference.setPreferLowSugar(value);
                break;
            case "lowfat":
                currentPreference.setPreferLowFat(value);
                break;
            case "highprotein":
                currentPreference.setPreferHighProtein(value);
                break;
            case "lowsodium":
                currentPreference.setPreferLowSodium(value);
                break;
            case "organic":
                currentPreference.setPreferOrganic(value);
                break;
            case "lowcalorie":
                currentPreference.setPreferLowCalorie(value);
                break;
            default:
                throw new IllegalArgumentException("未知的偏好类型: " + preferenceType);
        }
        
        // mark as user manual
        currentPreference.setPreferenceSource(PreferenceSource.USER_MANUAL);
        currentPreference.setInferenceConfidence(BigDecimal.ONE);
        
        return saveOrUpdateUserPreference(currentPreference);
    }
    
    @Override
    public Map<String, Object> getUserPreferenceStats(Integer userId) {
        UserPreferenceDto preference = getUserPreferenceDto(userId);
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("userId", userId);
        stats.put("hasPreferences", preference.getPreferenceId() != null);
        stats.put("preferenceSource", preference.getPreferenceSource().name());
        stats.put("inferenceConfidence", preference.getInferenceConfidence());
        stats.put("version", preference.getVersion());
        stats.put("lastUpdated", preference.getUpdatedAt());
        
        // count enabled preferences
        int enabledPreferences = 0;
        if (Boolean.TRUE.equals(preference.getPreferLowSugar())) enabledPreferences++;
        if (Boolean.TRUE.equals(preference.getPreferLowFat())) enabledPreferences++;
        if (Boolean.TRUE.equals(preference.getPreferHighProtein())) enabledPreferences++;
        if (Boolean.TRUE.equals(preference.getPreferLowSodium())) enabledPreferences++;
        if (Boolean.TRUE.equals(preference.getPreferOrganic())) enabledPreferences++;
        if (Boolean.TRUE.equals(preference.getPreferLowCalorie())) enabledPreferences++;
        
        stats.put("enabledPreferencesCount", enabledPreferences);
        
        // preference details
        Map<String, Boolean> preferenceDetails = new HashMap<>();
        preferenceDetails.put("lowSugar", preference.getPreferLowSugar());
        preferenceDetails.put("lowFat", preference.getPreferLowFat());
        preferenceDetails.put("highProtein", preference.getPreferHighProtein());
        preferenceDetails.put("lowSodium", preference.getPreferLowSodium());
        preferenceDetails.put("organic", preference.getPreferOrganic());
        preferenceDetails.put("lowCalorie", preference.getPreferLowCalorie());
        
        stats.put("preferences", preferenceDetails);
        
        return stats;
    }
    
    @Override
    public List<UserPreferenceDto> getBatchUserPreferences(List<Integer> userIds) {
        return userIds.stream()
            .map(this::getUserPreferenceDto)
            .collect(Collectors.toList());
    }
    
    @Override
    public List<Integer> findUsersByPreferenceType(String preferenceType) {
        List<UserPreference> preferences;
        
        switch (preferenceType.toLowerCase()) {
            case "lowsugar":
                preferences = userPreferenceRepository.findUsersWithLowSugarPreference();
                break;
            case "lowfat":
                preferences = userPreferenceRepository.findUsersWithLowFatPreference();
                break;
            case "highprotein":
                preferences = userPreferenceRepository.findUsersWithHighProteinPreference();
                break;
            case "lowsodium":
                preferences = userPreferenceRepository.findUsersWithLowSodiumPreference();
                break;
            case "organic":
                preferences = userPreferenceRepository.findUsersWithOrganicPreference();
                break;
            case "lowcalorie":
                preferences = userPreferenceRepository.findUsersWithLowCaloriePreference();
                break;
            default:
                throw new IllegalArgumentException("未知的偏好类型: " + preferenceType);
        }
        
        return preferences.stream()
            .map(UserPreference::getUserId)
            .collect(Collectors.toList());
    }
    
    @Override
    public UserPreferenceDto mergePreferences(Integer userId) {
        // get manual preferences
        List<UserPreference> manualPreferences = userPreferenceRepository
            .findByUserIdAndPreferenceSource(userId, PreferenceSource.USER_MANUAL);
        
        // get system inferred preferences
        List<UserPreference> inferredPreferences = userPreferenceRepository
            .findByUserIdAndPreferenceSource(userId, PreferenceSource.SYSTEM_INFERRED);
        
        UserPreferenceDto mergedPreference = new UserPreferenceDto(userId);
        mergedPreference.setPreferenceSource(PreferenceSource.MIXED);
        
        // manual preferences have higher priority
        if (!manualPreferences.isEmpty()) {
            UserPreference manual = manualPreferences.get(0);
            BeanUtils.copyProperties(manual, mergedPreference);
        }
        
        // use system inferred preferences to fill the gaps
        if (!inferredPreferences.isEmpty()) {
            UserPreference inferred = inferredPreferences.get(0);
            if (mergedPreference.getPreferLowSugar() == null) {
                mergedPreference.setPreferLowSugar(inferred.getPreferLowSugar());
            }
            // other fields similar processing...
        }
        
        return mergedPreference;
    }
    
    @Override
    public boolean hasUserPreference(Integer userId) {
        return userPreferenceRepository.existsByUserId(userId);
    }
    
    @Override
    public UserPreferenceDto resetUserPreference(Integer userId) {
        // delete existing preference
        if (hasUserPreference(userId)) {
            deleteUserPreference(userId);
        }
        
        // create default preference
        return createDefaultPreference(userId);
    }
    
    @Override
    public Map<String, Object> exportUserPreferenceData(Integer userId) {
        UserPreferenceDto preference = getUserPreferenceDto(userId);
        
        Map<String, Object> exportData = new HashMap<>();
        exportData.put("userId", preference.getUserId());
        exportData.put("preferLowSugar", preference.getPreferLowSugar());
        exportData.put("preferLowFat", preference.getPreferLowFat());
        exportData.put("preferHighProtein", preference.getPreferHighProtein());
        exportData.put("preferLowSodium", preference.getPreferLowSodium());
        exportData.put("preferOrganic", preference.getPreferOrganic());
        exportData.put("preferLowCalorie", preference.getPreferLowCalorie());
        exportData.put("preferenceSource", preference.getPreferenceSource().name());
        exportData.put("inferenceConfidence", preference.getInferenceConfidence());
        exportData.put("version", preference.getVersion());
        exportData.put("exportTime", LocalDateTime.now());
        
        return exportData;
    }
    
    @Override
    public UserPreferenceDto importUserPreferenceData(Integer userId, Map<String, Object> preferenceData) {
        UserPreferenceDto preference = new UserPreferenceDto(userId);
        
        // set preferences from imported data
        preference.setPreferLowSugar((Boolean) preferenceData.get("preferLowSugar"));
        preference.setPreferLowFat((Boolean) preferenceData.get("preferLowFat"));
        preference.setPreferHighProtein((Boolean) preferenceData.get("preferHighProtein"));
        preference.setPreferLowSodium((Boolean) preferenceData.get("preferLowSodium"));
        preference.setPreferOrganic((Boolean) preferenceData.get("preferOrganic"));
        preference.setPreferLowCalorie((Boolean) preferenceData.get("preferLowCalorie"));
        
        // set source to user manual
        preference.setPreferenceSource(PreferenceSource.USER_MANUAL);
        preference.setInferenceConfidence(BigDecimal.ONE);
        
        return saveOrUpdateUserPreference(preference);
    }
    
    // private helper methods
    private UserPreferenceDto convertToDto(UserPreference userPreference) {
        UserPreferenceDto dto = new UserPreferenceDto();
        BeanUtils.copyProperties(userPreference, dto);
        return dto;
    }
    
    private UserPreference convertToEntity(UserPreferenceDto dto) {
        UserPreference entity = new UserPreference();
        BeanUtils.copyProperties(dto, entity);
        return entity;
    }
    
    private UserPreferenceDto createDefaultPreference(Integer userId) {
        UserPreferenceDto defaultPreference = new UserPreferenceDto(userId);
        defaultPreference.setPreferenceSource(PreferenceSource.USER_MANUAL);
        defaultPreference.setInferenceConfidence(BigDecimal.ZERO);
        defaultPreference.setCreatedAt(LocalDateTime.now());
        defaultPreference.setUpdatedAt(LocalDateTime.now());
        return defaultPreference;
    }
    
    private Map<String, Object> convertToNestedFormat(UserPreferenceDto preference) {
        Map<String, Object> result = new HashMap<>();
        
        // create nutritionPreferences nested object
        Map<String, Object> nutritionPreferences = new HashMap<>();
        nutritionPreferences.put("preferLowSugar", preference.getPreferLowSugar());
        nutritionPreferences.put("preferLowFat", preference.getPreferLowFat());
        nutritionPreferences.put("preferHighProtein", preference.getPreferHighProtein());
        nutritionPreferences.put("preferLowSodium", preference.getPreferLowSodium());
        nutritionPreferences.put("preferOrganic", preference.getPreferOrganic());
        nutritionPreferences.put("preferLowCalorie", preference.getPreferLowCalorie());
        
        result.put("nutritionPreferences", nutritionPreferences);
        result.put("inferenceConfidence", preference.getInferenceConfidence());
        result.put("version", preference.getVersion());
        
        return result;
    }
    
    private UserPreferenceDto getUserPreferenceDto(Integer userId) {
        // check if user exists
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found, ID: " + userId));
        
        // find user preference
        Optional<UserPreference> preferenceOpt = userPreferenceRepository.findByUserId(userId);
        
        if (preferenceOpt.isPresent()) {
            return convertToDto(preferenceOpt.get());
        } else {
            // if no preference, return default preference
            return createDefaultPreference(userId);
        }
    }
} 