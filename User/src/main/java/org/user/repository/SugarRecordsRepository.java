package org.user.repository;

import org.user.pojo.SugarRecords;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.util.List;

@Repository
public interface SugarRecordsRepository extends CrudRepository<SugarRecords, Integer> {
    
    /**
     * query user's daily sugar intake records
     */
    @Query("SELECT sr FROM SugarRecords sr WHERE sr.userId = :userId AND DATE(sr.consumedAt) = :date")
    List<SugarRecords> findByUserIdAndDate(@Param("userId") Integer userId, @Param("date") Date date);
    
    /**
     * query user's sugar intake records in a date range
     */
    @Query("SELECT sr FROM SugarRecords sr WHERE sr.userId = :userId AND DATE(sr.consumedAt) BETWEEN :startDate AND :endDate ORDER BY sr.consumedAt DESC")
    List<SugarRecords> findByUserIdAndDateRange(@Param("userId") Integer userId, @Param("startDate") Date startDate, @Param("endDate") Date endDate);
    
    /**
     * query user's total sugar intake in a specific date
     */
    @Query("SELECT COALESCE(SUM(sr.sugarAmountMg * sr.quantity), 0.0) FROM SugarRecords sr WHERE sr.userId = :userId AND DATE(sr.consumedAt) = :date")
    Double getTotalSugarIntakeByUserIdAndDate(@Param("userId") Integer userId, @Param("date") Date date);
    
    /**
     * query user's daily sugar intake grouped by date within date range
     */
    @Query("SELECT DATE(sr.consumedAt) as date, COALESCE(SUM(sr.sugarAmountMg * sr.quantity), 0.0) as totalIntake " +
           "FROM SugarRecords sr " +
           "WHERE sr.userId = :userId AND DATE(sr.consumedAt) BETWEEN :startDate AND :endDate " +
           "GROUP BY DATE(sr.consumedAt) " +
           "ORDER BY DATE(sr.consumedAt)")
    List<Object[]> getDailySugarIntakeInRange(@Param("userId") Integer userId, @Param("startDate") Date startDate, @Param("endDate") Date endDate);
    
    /**
     * query top food sources by total sugar amount within date range
     */
    @Query("SELECT sr.foodName, COALESCE(SUM(sr.sugarAmountMg * sr.quantity), 0.0) as totalSugar " +
           "FROM SugarRecords sr " +
           "WHERE sr.userId = :userId AND DATE(sr.consumedAt) BETWEEN :startDate AND :endDate " +
           "GROUP BY sr.foodName " +
           "ORDER BY totalSugar DESC")
    List<Object[]> getTopFoodSourcesInRange(@Param("userId") Integer userId, @Param("startDate") Date startDate, @Param("endDate") Date endDate);
} 