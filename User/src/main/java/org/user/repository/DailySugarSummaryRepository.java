package org.user.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.user.pojo.DailySugarSummary;
import org.user.enums.SugarSummaryStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DailySugarSummaryRepository extends JpaRepository<DailySugarSummary, Integer> {
    
    /**
     * Find daily sugar summary by user ID and date
     */
    Optional<DailySugarSummary> findByUserIdAndDate(Integer userId, LocalDate date);
    
    /**
     * Find all daily sugar summaries by user ID, ordered by date descending
     */
    List<DailySugarSummary> findByUserIdOrderByDateDesc(Integer userId);
    
    /**
     * Find daily sugar summaries by user ID and date range
     */
    @Query("SELECT d FROM DailySugarSummary d WHERE d.userId = :userId AND d.date BETWEEN :startDate AND :endDate ORDER BY d.date DESC")
    List<DailySugarSummary> findByUserIdAndDateBetween(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    /**
     * Find daily sugar summaries by user ID and status, ordered by date descending
     */
    List<DailySugarSummary> findByUserIdAndStatusOrderByDateDesc(Integer userId, SugarSummaryStatus status);
    
    /**
     * Find the most recent daily sugar summary record for a user
     */
    @Query("SELECT d FROM DailySugarSummary d WHERE d.userId = :userId ORDER BY d.date DESC LIMIT :limit")
    List<DailySugarSummary> findRecentByUserId(@Param("userId") Integer userId, @Param("limit") Integer limit);
    
    /**
     * Find all daily sugar summaries for a user in a specific month
     */
    @Query("SELECT d FROM DailySugarSummary d WHERE d.userId = :userId AND YEAR(d.date) = :year AND MONTH(d.date) = :month ORDER BY d.date DESC")
    List<DailySugarSummary> findByUserIdAndMonth(
            @Param("userId") Integer userId,
            @Param("year") Integer year,
            @Param("month") Integer month);
    
    /**
     * Find all daily sugar summaries for a user in a specific year
     */
    @Query("SELECT d FROM DailySugarSummary d WHERE d.userId = :userId AND YEAR(d.date) = :year ORDER BY d.date DESC")
    List<DailySugarSummary> findByUserIdAndYear(@Param("userId") Integer userId, @Param("year") Integer year);
    
    /**
     * Check if a user has a daily sugar summary record on a specific date
     */
    boolean existsByUserIdAndDate(Integer userId, LocalDate date);
    
    /**
     * Count the total number of records for a user
     */
    long countByUserId(Integer userId);
    
    /**
     * Count the number of records for a user with a specific status
     */
    long countByUserIdAndStatus(Integer userId, SugarSummaryStatus status);
    
    /**
     * Count the number of records for a user within a specific date range
     */
    @Query("SELECT COUNT(d) FROM DailySugarSummary d WHERE d.userId = :userId AND d.date BETWEEN :startDate AND :endDate")
    long countByUserIdAndDateBetween(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    /**
     * Get the average daily sugar intake for a user
     */
    @Query("SELECT AVG(d.totalIntakeMg) FROM DailySugarSummary d WHERE d.userId = :userId")
    Double getAverageDailyIntakeByUserId(@Param("userId") Integer userId);
    
    /**
     * Get the average daily sugar intake for a user within a specific date range
     */
    @Query("SELECT AVG(d.totalIntakeMg) FROM DailySugarSummary d WHERE d.userId = :userId AND d.date BETWEEN :startDate AND :endDate")
    Double getAverageDailyIntakeByUserIdAndDateBetween(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    /**
     * Get the highest daily sugar intake record for a user
     */
    @Query("SELECT d FROM DailySugarSummary d WHERE d.userId = :userId ORDER BY d.totalIntakeMg DESC LIMIT 1")
    Optional<DailySugarSummary> findHighestIntakeByUserId(@Param("userId") Integer userId);
    
    /**
     * Get the highest daily sugar intake record for a user within a specific date range
     */
    @Query("SELECT d FROM DailySugarSummary d WHERE d.userId = :userId AND d.date BETWEEN :startDate AND :endDate ORDER BY d.totalIntakeMg DESC LIMIT 1")
    Optional<DailySugarSummary> findHighestIntakeByUserIdAndDateBetween(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
    
    /**
     * Get the number of consecutive days with good or warning status (from the specified date backwards)
     */
    @Query(value = """
            SELECT COUNT(*) as consecutive_days
            FROM daily_sugar_summary d
            WHERE d.user_id = :userId 
            AND d.date <= :endDate 
            AND d.status IN ('GOOD', 'WARNING')
            AND NOT EXISTS (
                SELECT 1 FROM daily_sugar_summary d2
                WHERE d2.user_id = :userId
                AND d2.date > d.date 
                AND d2.date <= :endDate
                AND d2.status = 'OVER_LIMIT'
            )
            """, nativeQuery = true)
    Integer getConsecutiveGoodDaysByUserId(@Param("userId") Integer userId, @Param("endDate") LocalDate endDate);
    
    /**
     * Get the status distribution for a user in a specific month
     */
    @Query("SELECT d.status, COUNT(d) FROM DailySugarSummary d WHERE d.userId = :userId AND YEAR(d.date) = :year AND MONTH(d.date) = :month GROUP BY d.status")
    List<Object[]> getMonthlyStatusDistribution(
            @Param("userId") Integer userId,
            @Param("year") Integer year,
            @Param("month") Integer month);
    
    /**
     * Delete a record for a user on a specific date
     */
    void deleteByUserIdAndDate(Integer userId, LocalDate date);
    
    /**
     * Delete all records for a user
     */
    void deleteByUserId(Integer userId);
    
    /**
     * Delete records for a user within a specific date range
     */
    @Query("DELETE FROM DailySugarSummary d WHERE d.userId = :userId AND d.date BETWEEN :startDate AND :endDate")
    void deleteByUserIdAndDateBetween(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
} 