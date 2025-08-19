package org.user.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.user.pojo.UserPreference;
import org.user.enums.PreferenceSource;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserPreferenceRepository extends JpaRepository<UserPreference, Integer> {
    
    /**
     * find user preference by user id
     * @param userId user id
     * @return user preference
     */
    Optional<UserPreference> findByUserId(Integer userId);
    
    /**
     * find user preference by user id and preference source
     * @param userId user id
     * @param preferenceSource preference source
     * @return user preference list
     */
    List<UserPreference> findByUserIdAndPreferenceSource(Integer userId, PreferenceSource preferenceSource);
    
    /**
     * check if user has preference
     * @param userId user id
     * @return true if user has preference, false otherwise
     */
    boolean existsByUserId(Integer userId);
    
    /**
     * delete user preference by user id
     * @param userId user id
     */
    void deleteByUserId(Integer userId);
    
    /**
     * find all manual preferences
     * @return manual preferences list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferenceSource = 'USER_MANUAL'")
    List<UserPreference> findAllManualPreferences();
    
    /**
     * find all system inferred preferences
     * @return system inferred preferences list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferenceSource = 'SYSTEM_INFERRED'")
    List<UserPreference> findAllSystemInferredPreferences();
    
    /**
     * find users with low sugar preference
     * @return users with low sugar preference list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferLowSugar = true")
    List<UserPreference> findUsersWithLowSugarPreference();
    
    /**
     * find users with low fat preference
     * @return users with low fat preference list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferLowFat = true")
    List<UserPreference> findUsersWithLowFatPreference();
    
    /**
     * find users with high protein preference
     * @return users with high protein preference list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferHighProtein = true")
    List<UserPreference> findUsersWithHighProteinPreference();
    
    /**
     * find users with low sodium preference
     * @return users with low sodium preference list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferLowSodium = true")
    List<UserPreference> findUsersWithLowSodiumPreference();
    
    /**
     * find users with organic preference
     * @return users with organic preference list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferOrganic = true")
    List<UserPreference> findUsersWithOrganicPreference();
    
    /**
     * find users with low calorie preference
     * @return users with low calorie preference list
     */
    @Query("SELECT up FROM UserPreference up WHERE up.preferLowCalorie = true")
    List<UserPreference> findUsersWithLowCaloriePreference();
    
    /**
     * find user preference by user id and version
     * @param userId user id
     * @param version version
     * @return user preference
     */
    Optional<UserPreference> findByUserIdAndVersion(Integer userId, Integer version);
    
    /**
     * find user's latest version preference
     * @param userId user id
     * @return latest version user preference
     */
    @Query("SELECT up FROM UserPreference up WHERE up.userId = :userId ORDER BY up.version DESC LIMIT 1")
    Optional<UserPreference> findLatestByUserId(@Param("userId") Integer userId);
} 