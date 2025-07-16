package org.user.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.user.pojo.SugarIntakeHistory;


import java.sql.Date;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SugarIntakeHistoryRepository extends JpaRepository<SugarIntakeHistory, Integer> {
    
    /**
     * query all sugar intake history by user id
     */
    List<SugarIntakeHistory> findByUserIdOrderByConsumedAtDesc(Integer userId);
    
    /**
     * query sugar intake history by user id and time range
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.consumedAt BETWEEN :startTime AND :endTime ORDER BY s.consumedAt DESC")
    List<SugarIntakeHistory> findByUserIdAndConsumedAtBetween(
            @Param("userId") Integer userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
    

    
    /**
     * calculate total sugar intake by user id and time range
     */
    @Query("SELECT COALESCE(SUM(s.sugarAmountMg), 0) FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.consumedAt BETWEEN :startTime AND :endTime")
    Float calculateTotalSugarIntakeByUserIdAndTimeRange(
            @Param("userId") Integer userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
    
    /**
     * calculate today total sugar intake by user id
     */
    @Query("SELECT COALESCE(SUM(s.sugarAmountMg), 0) FROM SugarIntakeHistory s WHERE s.userId = :userId AND DATE(s.consumedAt) = CURRENT_DATE")
    Float calculateTodayTotalSugarIntakeByUserId(@Param("userId") Integer userId);
    
    /**
     * query recent records by user id
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId ORDER BY s.consumedAt DESC LIMIT :limit")
    List<SugarIntakeHistory> findRecentRecordsByUserId(@Param("userId") Integer userId, @Param("limit") Integer limit);
    
    /**
     * query records by user id and food name
     */
    List<SugarIntakeHistory> findByUserIdAndFoodNameContainingIgnoreCaseOrderByConsumedAtDesc(Integer userId, String foodName);
    
    /**
     * query records by barcode
     */
    List<SugarIntakeHistory> findByBarcodeOrderByConsumedAtDesc(String barcode);
    
    /**
     * delete all records by user id
     */
    void deleteByUserId(Integer userId);
    
    /**
     * delete records by user id and time range
     */
    @Query("DELETE FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.consumedAt BETWEEN :startTime AND :endTime")
    void deleteByUserIdAndConsumedAtBetween(
            @Param("userId") Integer userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
    
    /**
     * check if user has sugar intake history
     */
    boolean existsByUserId(Integer userId);
    
    /**
     * count records by user id
     */
    long countByUserId(Integer userId);
    
    /**
     * count records by user id and time range
     */
    @Query("SELECT COUNT(s) FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.consumedAt BETWEEN :startTime AND :endTime")
    long countByUserIdAndConsumedAtBetween(
            @Param("userId") Integer userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
    
    /**
     * query records by user id and date
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId AND DATE(s.consumedAt) = :date ORDER BY s.consumedAt DESC")
    List<SugarIntakeHistory> findByUserIdAndDate(
            @Param("userId") Integer userId,
            @Param("date") Date date);
    
    /**
     * query records by user id and current date
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId AND DATE(s.consumedAt) = CURRENT_DATE ORDER BY s.consumedAt DESC")
    List<SugarIntakeHistory> findByUserIdAndCurrentDate(@Param("userId") Integer userId);
    
    /**
     * get daily sugar intake stats by user id (last 30 days)
     */
    @Query("SELECT DATE(s.consumedAt) as date, SUM(s.sugarAmountMg) as totalSugar " +
           "FROM SugarIntakeHistory s " +
           "WHERE s.userId = :userId AND s.consumedAt >= :startDate " +
           "GROUP BY DATE(s.consumedAt) " +
           "ORDER BY DATE(s.consumedAt) DESC")
    List<Object[]> getDailySugarIntakeStats(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDateTime startDate);
    
    /**
     * get monthly sugar intake statistics grouped by date
     */
    @Query("SELECT DATE(s.consumedAt) as date, COALESCE(SUM(s.sugarAmountMg), 0) as totalSugar " +
           "FROM SugarIntakeHistory s " +
           "WHERE s.userId = :userId AND YEAR(s.consumedAt) = :year AND MONTH(s.consumedAt) = :month " +
           "GROUP BY DATE(s.consumedAt) " +
           "ORDER BY DATE(s.consumedAt)")
    List<Object[]> getMonthlyDailySugarIntakeStats(
            @Param("userId") Integer userId,
            @Param("year") Integer year,
            @Param("month") Integer month);
} 