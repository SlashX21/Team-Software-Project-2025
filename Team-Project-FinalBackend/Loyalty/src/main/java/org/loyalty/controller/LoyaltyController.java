package org.loyalty.controller;

import org.loyalty.pojo.DTO.LoyaltyPointsRequest;
import org.loyalty.pojo.DTO.CheckPointsRequest;
import org.loyalty.pojo.response.LoyaltyPointsResponse;
import org.loyalty.pojo.response.ContractInfoResponse;
import org.loyalty.service.ILoyaltyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/loyalty")
public class LoyaltyController {
    
    @Autowired
    private ILoyaltyService loyaltyService;
    
    /**
     * 奖励积分接口
     * POST /loyalty/award-points
     * Returns FastAPI format response
     */
    @PostMapping("/award-points")
    public Map<String, Object> awardPoints(@Valid @RequestBody LoyaltyPointsRequest request) {
        try {
            LoyaltyPointsResponse response = loyaltyService.awardPoints(request);
            // Return FastAPI format: {"success": true, "transaction_hash": "...", "message": "..."}
            Map<String, Object> fastApiResponse = new HashMap<>();
            fastApiResponse.put("success", response.isSuccess());
            fastApiResponse.put("transaction_hash", response.getTransactionHash());
            fastApiResponse.put("message", response.getMessage());
            return fastApiResponse;
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "奖励积分失败: " + e.getMessage());
            return errorResponse;
        }
    }
    
    /**
     * 检查积分接口
     * POST /loyalty/check-points
     * Returns FastAPI format response
     */
    @PostMapping("/check-points")
    public Map<String, Object> checkPoints(@Valid @RequestBody CheckPointsRequest request) {
        try {
            LoyaltyPointsResponse response = loyaltyService.checkPoints(request);
            // Return FastAPI format: {"points": 100}
            Map<String, Object> fastApiResponse = new HashMap<>();
            fastApiResponse.put("points", response.getPoints());
            return fastApiResponse;
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("points", 0);
            return errorResponse;
        }
    }
    
    /**
     * 兑换积分接口
     * POST /loyalty/redeem-points
     * Returns FastAPI format response
     */
    @PostMapping("/redeem-points")
    public Map<String, Object> redeemPoints(@Valid @RequestBody CheckPointsRequest request) {
        try {
            LoyaltyPointsResponse response = loyaltyService.redeemPoints(request);
            // Return FastAPI format: {"user_id": "...", "barcode": "...", "points_redeemed": 100, "transaction_hash": "..."}
            Map<String, Object> fastApiResponse = new HashMap<>();
            fastApiResponse.put("user_id", request.getUserId());
            fastApiResponse.put("barcode", response.getBarcode());
            fastApiResponse.put("points_redeemed", response.getPoints()); // Fixed: use getPoints() instead of getPointsRedeemed()
            fastApiResponse.put("transaction_hash", response.getTransactionHash());
            return fastApiResponse;
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("user_id", request.getUserId());
            errorResponse.put("barcode", "");
            errorResponse.put("points_redeemed", 0);
            errorResponse.put("transaction_hash", "");
            return errorResponse;
        }
    }
    
    /**
     * 检查用户是否存在接口
     * POST /loyalty/user-exists
     * Returns FastAPI format response
     */
    @PostMapping("/user-exists")
    public Map<String, Object> checkUserExists(@Valid @RequestBody CheckPointsRequest request) {
        try {
            LoyaltyPointsResponse response = loyaltyService.checkUserExists(request);
            // Return FastAPI format: {"user_id": "...", "exists": true/false}
            Map<String, Object> fastApiResponse = new HashMap<>();
            fastApiResponse.put("user_id", request.getUserId());
            fastApiResponse.put("exists", response.isSuccess());
            return fastApiResponse;
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("user_id", request.getUserId());
            errorResponse.put("exists", false);
            return errorResponse;
        }
    }
    
    /**
     * 获取合约信息接口
     * GET /loyalty/contract-info
     * Returns FastAPI format response
     */
    @GetMapping("/contract-info")
    public Map<String, Object> getContractInfo() {
        try {
            ContractInfoResponse response = loyaltyService.getContractInfo();
            // Return FastAPI format: {"contract_address": "...", "owner": "...", "network": "...", "block_number": 0, "version": "..."}
            Map<String, Object> fastApiResponse = new HashMap<>();
            fastApiResponse.put("contract_address", response.getContractAddress());
            fastApiResponse.put("owner", response.getOwnerAddress());
            fastApiResponse.put("network", response.getNetwork());
            fastApiResponse.put("block_number", 0); // Not provided by FastAPI
            fastApiResponse.put("version", "2.0.0"); // Not provided by FastAPI
            return fastApiResponse;
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("contract_address", "");
            errorResponse.put("owner", "");
            errorResponse.put("network", "");
            errorResponse.put("block_number", 0);
            errorResponse.put("version", "");
            return errorResponse;
        }
    }
    
    /**
     * 健康检查接口
     * GET /loyalty/health
     * Returns FastAPI format response
     */
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> healthResponse = new HashMap<>();
        healthResponse.put("status", "healthy");
        healthResponse.put("network", "Sepolia");
        healthResponse.put("contract_address", "0x92812CdA22aF3485E33e0a589fB7960c24e1a34c");
        healthResponse.put("version", "2.0.0");
        return healthResponse;
    }
} 