package org.user.service;

import org.springframework.data.domain.Page;
import org.user.pojo.DTO.UserHistoryResponseDto;
import org.user.pojo.DTO.UserHistoryListDto;
import org.user.enums.ScanType;

public interface IUserHistoryService {
    
    /**
     * obtain user history list
     * 
     * @param userId user id
     * @param page page number (start from 1)
     * @param limit number of records per page
     * @param search search keyword (optional)
     * @param type filter type (optional) - 'barcode' or 'receipt'
     * @param range time range (optional) - 'week', 'month', 'year'
     * @return paginated user history list
     */
    Page<UserHistoryListDto> getUserHistory(
            Integer userId, 
            int page, 
            int limit, 
            String search, 
            String type, 
            String range);
    
    /**
     * obtain user history stats
     * 
     * @param userId user id
     * @param period time period ('week', 'month', 'year')
     * @return stats map
     */
    java.util.Map<String, Object> getUserHistoryStats(Integer userId, String period);

    /**
     * obtain history by id
     * 
     * @param userId user id
     * @param historyId history id
     * @return history response dto
     */
    UserHistoryResponseDto getUserHistoryById(Integer userId, String historyId);

    /**
     * delete history by id
     * 
     * @param userId user id
     * @param historyId history id
     */
    void deleteUserHistoryById(Integer userId, String historyId);

    /**
     * get brand from barcode
     * 
     * @param barcode barcode
     * @return brand
     */
    String getBrandFromBarcode(String barcode);

    /**
     * save scan history record
     * 
     * @param userId user id
     * @param barcode barcode
     * @param scanTime scan time
     * @param location location
     * @param allergenDetected allergen detected
     * @param actionTaken action taken
     * @return scan id
     */
    Integer saveScanHistory(Integer userId, String barcode, String scanTime, String location, 
                           Boolean allergenDetected, String actionTaken);
} 