package org.user.repository;

import org.user.pojo.SugarGoals;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SugarGoalsRepository extends CrudRepository<SugarGoals, Integer> {
    
    /**
     * query user's latest sugar goal
     */
    SugarGoals findTopByUserIdOrderByCreatedAtDesc(Integer userId);
    
    /**
     * query user's all sugar goals
     */
    Iterable<SugarGoals> findByUserId(Integer userId);
} 