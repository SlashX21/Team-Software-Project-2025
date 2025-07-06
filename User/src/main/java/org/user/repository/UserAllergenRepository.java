package org.user.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.allergen.pojo.UserAllergen;

import java.util.List;

@Repository
public interface UserAllergenRepository extends JpaRepository<UserAllergen, Integer> {
    
    /**
     * find all allergens by user id
     * @param userId user id
     * @return user allergens list
     */
    List<UserAllergen> findByUserId(Integer userId);
    
    /**
     * find allergens by user id and confirmed status
     * @param userId user id
     * @param confirmed confirmed status
     * @return user allergens list
     */
    List<UserAllergen> findByUserIdAndConfirmed(Integer userId, Boolean confirmed);
    
    /**
     * query user allergens details (include allergen basic information)
     * @param userId user id
     * @return user allergens details list
     */
    @Query("SELECT ua FROM UserAllergen ua WHERE ua.userId = :userId ORDER BY ua.severityLevel DESC, ua.userAllergenId")
    List<UserAllergen> findByUserIdOrderBySeverityLevel(@Param("userId") Integer userId);
} 