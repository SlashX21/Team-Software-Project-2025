package org.product.repository;

import org.product.pojo.ProductPreference;
import org.product.enums.PreferenceType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductPreferenceRepository extends JpaRepository<ProductPreference, Integer> {
    
    /**
     * find the preference of a specific product for a user
     */
    Optional<ProductPreference> findByUserIdAndBarCode(Integer userId, String barCode);
    
    /**
     * find all preferences of a user (paged)
     */
    Page<ProductPreference> findByUserIdOrderByCreatedAtDesc(Integer userId, Pageable pageable);
    
    /**
     * find the preference of a specific type for a user
     */
    List<ProductPreference> findByUserIdAndPreferenceType(Integer userId, PreferenceType preferenceType);
    
    /**
     * find the preference of a specific type for a user (paged)
     */
    Page<ProductPreference> findByUserIdAndPreferenceTypeOrderByCreatedAtDesc(Integer userId, PreferenceType preferenceType, Pageable pageable);
    
    /**
     * find all preferences of a product
     */
    List<ProductPreference> findByBarCode(String barCode);
    
    /**
     * count the number of preferences of a user
     */
    long countByUserId(Integer userId);
    
    /**
     * count the number of preferences of a specific type for a user
     */
    long countByUserIdAndPreferenceType(Integer userId, PreferenceType preferenceType);
    
    /**
     * count the number of preferences of a product
     */
    long countByBarCode(String barCode);
    
    /**
     * count the number of preferences of a specific type for a product
     */
    long countByBarCodeAndPreferenceType(String barCode, PreferenceType preferenceType);
    
    /**
     * check if a user has a preference for a product
     */
    boolean existsByUserIdAndBarCode(Integer userId, String barCode);
    
    /**
     * delete the preference of a specific product for a user
     */
    void deleteByUserIdAndBarCode(Integer userId, String barCode);
    
    /**
     * delete all preferences of a user
     */
    void deleteByUserId(Integer userId);
    
    /**
     * get the list of product barcodes with preferences of a user (for recommendation algorithm)
     */
    @Query("SELECT pp.barCode FROM ProductPreference pp WHERE pp.userId = :userId AND pp.preferenceType = :preferenceType")
    List<String> findBarCodesByUserIdAndPreferenceType(@Param("userId") Integer userId, @Param("preferenceType") PreferenceType preferenceType);
    
    /**
     * get the preference statistics of a user (grouped by type)
     */
    @Query("SELECT pp.preferenceType, COUNT(pp) FROM ProductPreference pp WHERE pp.userId = :userId GROUP BY pp.preferenceType")
    List<Object[]> getPreferenceStatsByUserId(@Param("userId") Integer userId);
    
    /**
     * get the preference statistics of a product (grouped by type)
     */
    @Query("SELECT pp.preferenceType, COUNT(pp) FROM ProductPreference pp WHERE pp.barCode = :barCode GROUP BY pp.preferenceType")
    List<Object[]> getPreferenceStatsByBarCode(@Param("barCode") String barCode);
    
    /**
     * get the products with preferences of a user (with detailed information)
     */
    @Query("SELECT pp FROM ProductPreference pp LEFT JOIN FETCH pp.product WHERE pp.userId = :userId ORDER BY pp.createdAt DESC")
    List<ProductPreference> findByUserIdWithProduct(@Param("userId") Integer userId);
    
    /**
     * get the products with preferences of a user (with detailed information) (paged)
     */
    @Query("SELECT pp FROM ProductPreference pp LEFT JOIN FETCH pp.product WHERE pp.userId = :userId ORDER BY pp.createdAt DESC")
    Page<ProductPreference> findByUserIdWithProduct(@Param("userId") Integer userId, Pageable pageable);
    
    /**
     * get the products with preferences of a user (with detailed information) of a specific type
     */
    @Query("SELECT pp FROM ProductPreference pp LEFT JOIN FETCH pp.product WHERE pp.userId = :userId AND pp.preferenceType = :preferenceType ORDER BY pp.createdAt DESC")
    List<ProductPreference> findByUserIdAndPreferenceTypeWithProduct(@Param("userId") Integer userId, @Param("preferenceType") PreferenceType preferenceType);
    
    /**
     * get the most recent preferences (for analyzing user behavior trends)
     */
    @Query("SELECT pp FROM ProductPreference pp WHERE pp.userId = :userId ORDER BY pp.createdAt DESC")
    List<ProductPreference> findRecentPreferencesByUserId(@Param("userId") Integer userId, Pageable pageable);
    
    /**
     * get the blacklisted product barcodes of a user (for recommendation system filtering)
     */
    @Query("SELECT pp.barCode FROM ProductPreference pp WHERE pp.userId = :userId AND pp.preferenceType = 'BLACKLIST'")
    List<String> findBlacklistedBarCodesByUserId(@Param("userId") Integer userId);
    
    /**
     * get the liked product barcodes of a user (for recommendation system weighting)
     */
    @Query("SELECT pp.barCode FROM ProductPreference pp WHERE pp.userId = :userId AND pp.preferenceType = 'LIKE'")
    List<String> findLikedBarCodesByUserId(@Param("userId") Integer userId);
} 