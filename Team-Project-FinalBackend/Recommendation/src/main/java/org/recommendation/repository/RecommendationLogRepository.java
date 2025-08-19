package org.recommendation.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.recommendation.pojo.RecommendationLog;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface RecommendationLogRepository extends JpaRepository<RecommendationLog, Integer> {
    
    /**
     * 根据用户ID查询推荐日志
     */
    Page<RecommendationLog> findByUserIdOrderByCreatedAtDesc(Integer userId, Pageable pageable);
    
    /**
     * 根据用户ID和请求类型查询推荐日志
     */
    Page<RecommendationLog> findByUserIdAndRequestTypeOrderByCreatedAtDesc(
            Integer userId, String requestType, Pageable pageable);
    
    /**
     * 根据用户ID和时间范围查询推荐日志
     */
    @Query("SELECT rl FROM RecommendationLog rl WHERE rl.userId = :userId " +
           "AND rl.createdAt >= :startDate AND rl.createdAt <= :endDate " +
           "ORDER BY rl.createdAt DESC")
    List<RecommendationLog> findByUserIdAndDateRange(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);
    
    /**
     * 统计用户推荐请求总数
     */
    @Query("SELECT COUNT(rl) FROM RecommendationLog rl WHERE rl.userId = :userId")
    Long countByUserId(@Param("userId") Integer userId);
    
    /**
     * 统计用户指定类型的推荐请求数量
     */
    @Query("SELECT COUNT(rl) FROM RecommendationLog rl WHERE rl.userId = :userId AND rl.requestType = :requestType")
    Long countByUserIdAndRequestType(@Param("userId") Integer userId, @Param("requestType") String requestType);
    
    /**
     * 获取用户最近的推荐日志
     */
    @Query("SELECT rl FROM RecommendationLog rl WHERE rl.userId = :userId ORDER BY rl.createdAt DESC")
    List<RecommendationLog> findRecentByUserId(@Param("userId") Integer userId, Pageable pageable);
} 