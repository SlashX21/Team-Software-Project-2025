package org.product.service;

import org.product.pojo.DTO.ProductPreferenceDto;
import org.product.pojo.DTO.ResponseMessage;
import org.product.pojo.DTO.PagedResponseDto;
import org.product.enums.PreferenceType;

import java.util.List;
import java.util.Map;

public interface IProductPreferenceService {
    
    /**
     * set or update product preference
     * @param userId user ID
     * @param productPreferenceDto preference data
     * @return preference result
     */
    ResponseMessage<ProductPreferenceDto> setProductPreference(Integer userId, ProductPreferenceDto productPreferenceDto);
    
    /**
     * get user product preferences
     * @param userId user ID
     * @param type preference type (optional)
     * @param page page number (0-based)
     * @param size page size
     * @return paged preference list
     */
    ResponseMessage<PagedResponseDto<ProductPreferenceDto>> getUserProductPreferences(Integer userId, PreferenceType type, Integer page, Integer size);
    
    /**
     * get user preference for a specific product
     * @param userId user ID
     * @param barCode product barcode
     * @return preference data or null if not exists
     */
    ResponseMessage<ProductPreferenceDto> getProductPreference(Integer userId, String barCode);
    
    /**
     * delete product preference
     * @param userId user ID
     * @param barCode product barcode
     * @return operation result
     */
    ResponseMessage<String> deleteProductPreference(Integer userId, String barCode);
    
    /**
     * get user preference statistics
     * @param userId user ID
     * @return preference statistics by type
     */
    ResponseMessage<Map<String, Long>> getUserPreferenceStats(Integer userId);
    
    /**
     * get user blacklisted products (for recommendation filtering)
     * @param userId user ID
     * @return list of blacklisted product barcodes
     */
    List<String> getUserBlacklistedProducts(Integer userId);
    
    /**
     * get user liked products (for recommendation weighting)
     * @param userId user ID
     * @return list of liked product barcodes
     */
    List<String> getUserLikedProducts(Integer userId);
} 