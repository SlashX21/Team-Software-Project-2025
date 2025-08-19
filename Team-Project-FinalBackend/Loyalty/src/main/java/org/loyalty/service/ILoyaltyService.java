package org.loyalty.service;

import org.loyalty.pojo.DTO.LoyaltyPointsRequest;
import org.loyalty.pojo.DTO.CheckPointsRequest;
import org.loyalty.pojo.response.LoyaltyPointsResponse;
import org.loyalty.pojo.response.ContractInfoResponse;

public interface ILoyaltyService {
    
    /**
     * 奖励积分给用户
     * @param request 积分奖励请求
     * @return 奖励结果
     */
    LoyaltyPointsResponse awardPoints(LoyaltyPointsRequest request);
    
    /**
     * 检查用户积分
     * @param request 检查积分请求
     * @return 积分信息
     */
    LoyaltyPointsResponse checkPoints(CheckPointsRequest request);
    
    /**
     * 兑换积分
     * @param request 兑换积分请求
     * @return 兑换结果，包含条形码
     */
    LoyaltyPointsResponse redeemPoints(CheckPointsRequest request);
    
    /**
     * 检查用户是否存在
     * @param request 检查用户请求
     * @return 用户存在状态
     */
    LoyaltyPointsResponse checkUserExists(CheckPointsRequest request);
    
    /**
     * 获取合约信息
     * @return 合约信息
     */
    ContractInfoResponse getContractInfo();
} 