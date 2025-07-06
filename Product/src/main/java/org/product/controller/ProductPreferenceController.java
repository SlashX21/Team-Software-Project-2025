package org.product.controller;

import org.product.pojo.DTO.ProductPreferenceDto;
import org.product.pojo.DTO.ResponseMessage;
import org.product.pojo.DTO.PagedResponseDto;
import org.product.service.IProductPreferenceService;
import org.product.enums.PreferenceType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.Map;

@RestController
@RequestMapping("/user")
@Validated
public class ProductPreferenceController {
    
    @Autowired
    private IProductPreferenceService productPreferenceService;
    
    /**
     * set product preference
     * POST /user/{userId}/product-preferences
     */
    @PostMapping("/{userId}/product-preferences")
    public ResponseEntity<ResponseMessage<ProductPreferenceDto>> setProductPreference(
            @PathVariable Integer userId,
            @Valid @RequestBody ProductPreferenceDto productPreferenceDto) {
        
        try {
            // set user ID from path parameter (不再验证请求体中的userId)
            productPreferenceDto.setUserId(userId);
            
            ResponseMessage<ProductPreferenceDto> result = productPreferenceService.setProductPreference(userId, productPreferenceDto);
            
            if (result.getCode() == 200) {
                return ResponseEntity.ok(result);
            } else if (result.getCode() == 400) {
                return ResponseEntity.badRequest().body(result);
            } else if (result.getCode() == 404) {
                return ResponseEntity.status(404).body(result);
            } else {
                return ResponseEntity.status(500).body(result);
            }
            
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to set product preference: " + e.getMessage(), null));
        }
    }
    
    /**
     * get user product preferences
     * GET /user/{userId}/product-preferences?type={like|dislike|blacklist}&page={page}&size={size}
     */
    @GetMapping("/{userId}/product-preferences")
    public ResponseEntity<ResponseMessage<PagedResponseDto<ProductPreferenceDto>>> getUserProductPreferences(
            @PathVariable Integer userId,
            @RequestParam(value = "type", required = false) String typeStr,
            @RequestParam(value = "page", defaultValue = "0") Integer page,
            @RequestParam(value = "size", defaultValue = "10") Integer size) {
        
        try {
            // validate parameters
            if (page < 0 || size <= 0) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "Page must be non-negative and size must be positive", null));
            }
            
            if (size > 100) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "Page size cannot exceed 100", null));
            }
            
            // parse preference type
            PreferenceType type = null;
            if (typeStr != null && !typeStr.trim().isEmpty()) {
                try {
                    type = PreferenceType.fromCode(typeStr.toLowerCase());
                } catch (IllegalArgumentException e) {
                    return ResponseEntity.badRequest().body(
                        new ResponseMessage<>(400, "Invalid preference type. Valid values: like, dislike, blacklist", null));
                }
            }
            
            ResponseMessage<PagedResponseDto<ProductPreferenceDto>> result = 
                productPreferenceService.getUserProductPreferences(userId, type, page, size);
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to get user preferences: " + e.getMessage(), null));
        }
    }
    
    /**
     * get user preference for a specific product
     * GET /user/{userId}/product-preferences/{barCode}
     */
    @GetMapping("/{userId}/product-preferences/{barCode}")
    public ResponseEntity<ResponseMessage<ProductPreferenceDto>> getProductPreference(
            @PathVariable Integer userId,
            @PathVariable String barCode) {
        
        try {
            if (barCode == null || barCode.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "Bar code cannot be empty", null));
            }
            
            ResponseMessage<ProductPreferenceDto> result = 
                productPreferenceService.getProductPreference(userId, barCode);
            
            if (result.getCode() == 200) {
                return ResponseEntity.ok(result);
            } else if (result.getCode() == 404) {
                return ResponseEntity.status(404).body(result);
            } else {
                return ResponseEntity.status(500).body(result);
            }
            
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to get product preference: " + e.getMessage(), null));
        }
    }
    
    /**
     * delete product preference
     * DELETE /user/{userId}/product-preferences/{barCode}
     */
    @DeleteMapping("/{userId}/product-preferences/{barCode}")
    public ResponseEntity<ResponseMessage<String>> deleteProductPreference(
            @PathVariable Integer userId,
            @PathVariable String barCode) {
        
        try {
            if (barCode == null || barCode.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "Bar code cannot be empty", null));
            }
            
            ResponseMessage<String> result = 
                productPreferenceService.deleteProductPreference(userId, barCode);
            
            if (result.getCode() == 200) {
                return ResponseEntity.ok(result);
            } else if (result.getCode() == 404) {
                return ResponseEntity.status(404).body(result);
            } else {
                return ResponseEntity.status(500).body(result);
            }
            
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to delete product preference: " + e.getMessage(), null));
        }
    }
    
    /**
     * get user preference statistics
     * GET /user/{userId}/product-preferences/stats
     */
    @GetMapping("/{userId}/product-preferences/stats")
    public ResponseEntity<ResponseMessage<Map<String, Long>>> getUserPreferenceStats(
            @PathVariable Integer userId) {
        
        try {
            ResponseMessage<Map<String, Long>> result = 
                productPreferenceService.getUserPreferenceStats(userId);
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to get preference statistics: " + e.getMessage(), null));
        }
    }
} 