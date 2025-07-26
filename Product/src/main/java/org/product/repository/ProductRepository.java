package org.product.repository;

import org.product.pojo.Product;
import java.util.Optional;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository //register this class as a Spring Bean
public interface ProductRepository extends CrudRepository<Product, String> {
    Optional<Product> findByBarCode(String barCode);
    void deleteByBarCode(String barCode);
    boolean existsByBarCode(String barCode);
    
    /**
     * search products by name with pagination
     */
    @Query("SELECT p FROM Product p WHERE LOWER(p.productName) LIKE LOWER(CONCAT('%', :productName, '%')) ORDER BY p.productName")
    Page<Product> searchByProductNameContainingIgnoreCase(@Param("productName") String productName, Pageable pageable);
    
    /**
     * get products by category with pagination
     */
    @Query("SELECT p FROM Product p WHERE LOWER(p.category) = LOWER(:category) ORDER BY p.productName")
    Page<Product> findByCategoryIgnoreCase(@Param("category") String category, Pageable pageable);
    
    /**
     * count total products by name search
     */
    @Query("SELECT COUNT(p) FROM Product p WHERE LOWER(p.productName) LIKE LOWER(CONCAT('%', :productName, '%'))")
    Long countByProductNameContainingIgnoreCase(@Param("productName") String productName);
    
    /**
     * count total products by category
     */
    @Query("SELECT COUNT(p) FROM Product p WHERE LOWER(p.category) = LOWER(:category)")
    Long countByCategoryIgnoreCase(@Param("category") String category);
    
    /**
     * filter products by nutrition criteria
     */
    @Query("SELECT p FROM Product p WHERE " +
           "(:maxCalories IS NULL OR p.energyKcal100g IS NULL OR p.energyKcal100g <= :maxCalories) AND " +
           "(:maxSugar IS NULL OR p.sugars100g IS NULL OR p.sugars100g <= :maxSugar) AND " +
           "(:minProtein IS NULL OR p.proteins100g IS NULL OR p.proteins100g >= :minProtein) " +
           "ORDER BY p.productName")
    Page<Product> filterByNutrition(@Param("maxCalories") Float maxCalories, 
                                   @Param("maxSugar") Float maxSugar, 
                                   @Param("minProtein") Float minProtein, 
                                   Pageable pageable);
    
    /**
     * count products by nutrition criteria
     */
    @Query("SELECT COUNT(p) FROM Product p WHERE " +
           "(:maxCalories IS NULL OR p.energyKcal100g IS NULL OR p.energyKcal100g <= :maxCalories) AND " +
           "(:maxSugar IS NULL OR p.sugars100g IS NULL OR p.sugars100g <= :maxSugar) AND " +
           "(:minProtein IS NULL OR p.proteins100g IS NULL OR p.proteins100g >= :minProtein)")
    Long countByNutrition(@Param("maxCalories") Float maxCalories, 
                         @Param("maxSugar") Float maxSugar, 
                         @Param("minProtein") Float minProtein);
}
