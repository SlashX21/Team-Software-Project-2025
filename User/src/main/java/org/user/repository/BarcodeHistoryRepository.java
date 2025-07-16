package org.user.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.user.pojo.BarcodeHistory;

@Repository
public interface BarcodeHistoryRepository extends JpaRepository<BarcodeHistory, Integer> {
    
    /**
     * get the number of scans for a user in a specific month
     * 
     * @param userId user id
     * @param month month, format: "YYYY-MM"
     * @return the number of scans
     */
    @Query("SELECT COUNT(*) FROM BarcodeHistory bh " +
           "WHERE bh.userId = :userId " +
           "AND DATE_FORMAT(bh.scanTime, '%Y-%m') = :month")
    Long countBarcodeScansForUserAndMonth(@Param("userId") Integer userId, @Param("month") String month);
    
    /**
     * obtain barcode scan history for a user, support pagination and month filter
     * 
     * @param userId user id
     * @param pageable pageable
     * @return paginated barcode scan history
     */
    @Query("SELECT bh FROM BarcodeHistory bh " +
           "WHERE bh.userId = :userId " +
           "ORDER BY bh.scanTime DESC")
    Page<BarcodeHistory> findByUserIdOrderByScanTimeDesc(@Param("userId") Integer userId, Pageable pageable);
    
    /**
     * obtain barcode scan history for a user, support pagination and month filter
     * 
     * @param userId user id
     * @param month month, format: "YYYY-MM"
     * @param pageable pageable
     * @return paginated barcode scan history
     */
    @Query("SELECT bh FROM BarcodeHistory bh " +
           "WHERE bh.userId = :userId " +
           "AND (:month IS NULL OR DATE_FORMAT(bh.scanTime, '%Y-%m') = :month) " +
           "ORDER BY bh.scanTime DESC")
    Page<BarcodeHistory> findByUserIdAndMonthOrderByScanTimeDesc(
            @Param("userId") Integer userId, 
            @Param("month") String month, 
            Pageable pageable);
} 