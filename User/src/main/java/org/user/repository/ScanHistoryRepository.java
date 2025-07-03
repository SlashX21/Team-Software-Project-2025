package org.user.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.user.enums.ScanType;
import org.user.pojo.ScanHistory;

import java.time.LocalDateTime;

@Repository
public interface ScanHistoryRepository extends JpaRepository<ScanHistory, Integer> {
    
    /**
     * Query scan history by user id
     */
    Page<ScanHistory> findByUserIdOrderByScanTimeDesc(Integer userId, Pageable pageable);
    
    /**
     * Query scan history by user id and scan type
     */
    Page<ScanHistory> findByUserIdAndScanTypeOrderByScanTimeDesc(
            Integer userId, ScanType scanType, Pageable pageable);
    
    /**
     * Complex query: support search, filter and time range
     */
    @Query(value = """
            SELECT sh.* FROM scan_history sh
            LEFT JOIN product p ON sh.barcode = p.barcode
            WHERE sh.user_id = :userId
            AND (:search IS NULL OR :search = '' OR 
                 LOWER(p.name) LIKE LOWER(CONCAT('%', :search, '%')) OR
                 LOWER(sh.barcode) LIKE LOWER(CONCAT('%', :search, '%')))
            AND (:scanType IS NULL OR sh.scan_type = :scanType)
            AND (:startDate IS NULL OR sh.scan_time >= :startDate)
            AND (:endDate IS NULL OR sh.scan_time <= :endDate)
            ORDER BY sh.scan_time DESC
            """, 
            countQuery = """
            SELECT COUNT(sh.scan_id) FROM scan_history sh
            LEFT JOIN product p ON sh.barcode = p.barcode
            WHERE sh.user_id = :userId
            AND (:search IS NULL OR :search = '' OR 
                 LOWER(p.name) LIKE LOWER(CONCAT('%', :search, '%')) OR
                 LOWER(sh.barcode) LIKE LOWER(CONCAT('%', :search, '%')))
            AND (:scanType IS NULL OR sh.scan_type = :scanType)
            AND (:startDate IS NULL OR sh.scan_time >= :startDate)
            AND (:endDate IS NULL OR sh.scan_time <= :endDate)
            """,
            nativeQuery = true)
    Page<ScanHistory> findUserHistoryWithFilters(
            @Param("userId") Integer userId,
            @Param("search") String search,
            @Param("scanType") String scanType,
            @Param("startDate") String startDate,
            @Param("endDate") String endDate,
            Pageable pageable);
    
    /**
     * Get user scan history statistics
     */
    @Query("SELECT COUNT(sh) FROM ScanHistory sh WHERE sh.userId = :userId")
    Long countByUserId(@Param("userId") Integer userId);
    
    /**
     * Get the number of unique products scanned by the user
     */
    @Query("SELECT COUNT(DISTINCT sh.barcode) FROM ScanHistory sh WHERE sh.userId = :userId")
    Long countDistinctProductsByUserId(@Param("userId") Integer userId);
} 