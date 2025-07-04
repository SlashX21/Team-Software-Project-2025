package org.user.service;

import org.springframework.data.domain.Page;
import org.user.pojo.DTO.UserHistoryResponseDto;
import org.user.pojo.DTO.UserHistoryListDto;
import org.user.enums.ScanType;

public interface IUserHistoryService {
    
    /**
     * 获取用户历史记录列表
     * 
     * @param userId 用户ID
     * @param page 页码（从1开始）
     * @param limit 每页数量
     * @param search 搜索关键词（可选）
     * @param type 筛选类型（可选）- 'barcode' 或 'receipt'
     * @param range 时间范围（可选）- 'week', 'month', 'year'
     * @return 分页的用户历史记录
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
} 