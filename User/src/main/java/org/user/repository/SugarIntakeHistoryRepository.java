package org.user.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.user.pojo.SugarIntakeHistory;
import org.user.enums.SourceType;

import java.sql.Date;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SugarIntakeHistoryRepository extends JpaRepository<SugarIntakeHistory, Integer> {
    
    /**
     * query all sugar intake history by user id
     */
    List<SugarIntakeHistory> findByUserIdOrderByIntakeTimeDesc(Integer userId);
    
    /**
     * query sugar intake history by user id and time range
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.intakeTime BETWEEN :startTime AND :endTime ORDER BY s.intakeTime DESC")
    List<SugarIntakeHistory> findByUserIdAndIntakeTimeBetween(
            @Param("userId") Integer userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
    
    /**
     * query sugar intake history by user id and source type
     */
    List<SugarIntakeHistory> findByUserIdAndSourceTypeOrderByIntakeTimeDesc(Integer userId, SourceType sourceType);
    
    /**
     * calculate total sugar intake by user id and time range
     */
    @Query("SELECT COALESCE(SUM(s.sugarAmountMg), 0) FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.intakeTime BETWEEN :startTime AND :endTime")
    Float calculateTotalSugarIntakeByUserIdAndTimeRange(
            @Param("userId") Integer userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
    
    /**
     * calculate today total sugar intake by user id
     */
    @Query("SELECT COALESCE(SUM(s.sugarAmountMg), 0) FROM SugarIntakeHistory s WHERE s.userId = :userId AND DATE(s.intakeTime) = CURRENT_DATE")
    Float calculateTodayTotalSugarIntakeByUserId(@Param("userId") Integer userId);
    
    /**
     * query recent records by user id
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId ORDER BY s.intakeTime DESC LIMIT :limit")
    List<SugarIntakeHistory> findRecentRecordsByUserId(@Param("userId") Integer userId, @Param("limit") Integer limit);
    
    /**
     * query records by user id and food name
     */
    List<SugarIntakeHistory> findByUserIdAndFoodNameContainingIgnoreCaseOrderByIntakeTimeDesc(Integer userId, String foodName);
    
    /**
     * query records by barcode
     */
    List<SugarIntakeHistory> findByBarcodeOrderByIntakeTimeDesc(String barcode);
    
    /**
     * delete all records by user id
     */
    void deleteByUserId(Integer userId);
    
    /**
     * delete records by user id and time range
     */
    @Query("DELETE FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.intakeTime BETWEEN :startTime AND :endTime")
    void deleteByUserIdAndIntakeTimeBetween(
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
    @Query("SELECT COUNT(s) FROM SugarIntakeHistory s WHERE s.userId = :userId AND s.intakeTime BETWEEN :startTime AND :endTime")
    long countByUserIdAndIntakeTimeBetween(
            @Param("userId") Integer userId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
    
    /**
     * query records by user id and date
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId AND DATE(s.intakeTime) = :date ORDER BY s.intakeTime DESC")
    List<SugarIntakeHistory> findByUserIdAndDate(
            @Param("userId") Integer userId,
            @Param("date") Date date);
    
    /**
     * query records by user id and current date
     */
    @Query("SELECT s FROM SugarIntakeHistory s WHERE s.userId = :userId AND DATE(s.intakeTime) = CURRENT_DATE ORDER BY s.intakeTime DESC")
    List<SugarIntakeHistory> findByUserIdAndCurrentDate(@Param("userId") Integer userId);
    
    /**
     * get daily sugar intake stats by user id (last 30 days)
     */
    @Query("SELECT DATE(s.intakeTime) as date, SUM(s.sugarAmountMg) as totalSugar " +
           "FROM SugarIntakeHistory s " +
           "WHERE s.userId = :userId AND s.intakeTime >= :startDate " +
           "GROUP BY DATE(s.intakeTime) " +
           "ORDER BY DATE(s.intakeTime) DESC")
    List<Object[]> getDailySugarIntakeStats(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDateTime startDate);
    
    /**
     * get monthly sugar intake statistics grouped by date
     */
    @Query("SELECT DATE(s.intakeTime) as date, COALESCE(SUM(s.sugarAmountMg), 0) as totalSugar " +
           "FROM SugarIntakeHistory s " +
           "WHERE s.userId = :userId AND YEAR(s.intakeTime) = :year AND MONTH(s.intakeTime) = :month " +
           "GROUP BY DATE(s.intakeTime) " +
           "ORDER BY DATE(s.intakeTime)")
    List<Object[]> getMonthlyDailySugarIntakeStats(
            @Param("userId") Integer userId,
            @Param("year") Integer year,
            @Param("month") Integer month);
} 