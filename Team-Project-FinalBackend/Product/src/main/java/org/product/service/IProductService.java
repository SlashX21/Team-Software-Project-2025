package org.product.service;

import org.product.pojo.Product;
import org.product.pojo.DTO.ProductDto;
import org.product.pojo.DTO.ProductSearchDto;
import org.product.pojo.DTO.PagedResponseDto;

public interface IProductService {
    /**
     * insert product
     *
     * @param product
     * @return
     */
    Product add(ProductDto user);

    /**
     * query product
     * @param barCode barCode
     * @return
     */
    Product getProduct(String barCode);

    /**
     * update product
     * @param product
     * @return
     */
    Product edit(ProductDto product);

    /**
     * delete product
     * @param barCode barCode
     * @return
     */
    void delete(String barCode);
    
    /**
     * search products by name with pagination
     * @param productName product name to search
     * @param page page number (0-based)
     * @param size page size
     * @return paged search results
     */
    PagedResponseDto<ProductSearchDto> searchProductsByName(String productName, Integer page, Integer size);
    
    /**
     * get products by category with pagination
     * @param category product category
     * @param page page number (0-based)
     * @param size page size
     * @return paged results by category
     */
    PagedResponseDto<ProductSearchDto> getProductsByCategory(String category, Integer page, Integer size);
    
    /**
     * filter products by nutrition criteria
     * @param maxCalories maximum calories per 100g (optional)
     * @param maxSugar maximum sugar per 100g (optional)
     * @param minProtein minimum protein per 100g (optional)
     * @param page page number (0-based)
     * @param size page size
     * @return paged filtered results
     */
    PagedResponseDto<ProductSearchDto> filterProductsByNutrition(Float maxCalories, Float maxSugar, Float minProtein, Integer page, Integer size);

    /**
     * Batch lookup products by a list of names (case-insensitive, partial match)
     * @param names list of product names
     * @return list of products
     */
    java.util.List<org.product.pojo.Product> batchLookupByNames(java.util.List<String> names);

    /**
     * Count sustainable products by a list of names
     * @param names list of product names
     * @return count of sustainable products
     */
    Long countSustainableProductsByNames(java.util.List<String> names);
}
