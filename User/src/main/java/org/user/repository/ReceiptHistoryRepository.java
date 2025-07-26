package org.user.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.user.pojo.ReceiptHistory;

@Repository
public interface ReceiptHistoryRepository extends JpaRepository<ReceiptHistory, Integer> {
    
    /**
     * get the number of receipt uploads for a user in a specific month
     * 
     * @param userId user id
     * @param month month, format: "YYYY-MM"
     * @return the number of uploads
     */
    @Query("SELECT COUNT(*) FROM ReceiptHistory rh " +
           "WHERE rh.userId = :userId " +
           "AND DATE_FORMAT(rh.scanTime, '%Y-%m') = :month")
    Long countReceiptUploadsForUserAndMonth(@Param("userId") Integer userId, @Param("month") String month);
    
    /**
     * obtain receipt history for a user, support pagination
     * 
     * @param userId user id
     * @param pageable pageable
     * @return paginated receipt history
     */
    @Query("SELECT rh FROM ReceiptHistory rh " +
           "WHERE rh.userId = :userId " +
           "ORDER BY rh.scanTime DESC")
    Page<ReceiptHistory> findByUserIdOrderByScanTimeDesc(@Param("userId") Integer userId, Pageable pageable);
}