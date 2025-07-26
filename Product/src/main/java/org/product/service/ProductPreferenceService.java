package org.product.service;

import org.product.pojo.ProductPreference;
import org.product.pojo.Product;
import org.product.pojo.DTO.ProductPreferenceDto;
import org.product.pojo.DTO.ResponseMessage;
import org.product.pojo.DTO.PagedResponseDto;
import org.product.repository.ProductPreferenceRepository;
import org.product.repository.ProductRepository;
import org.product.enums.PreferenceType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class ProductPreferenceService implements IProductPreferenceService {
    
    @Autowired
    private ProductPreferenceRepository productPreferenceRepository;
    
    @Autowired
    private ProductRepository productRepository;
    
    @Override
    public ResponseMessage<ProductPreferenceDto> setProductPreference(Integer userId, ProductPreferenceDto productPreferenceDto) {
        try {
            // validate input
            if (userId == null || productPreferenceDto.getBarCode() == null || 
                productPreferenceDto.getPreferenceType() == null) {
                return new ResponseMessage<>(400, "Invalid input parameters", null);
            }
            
            // check if product exists
            Optional<Product> productOpt = productRepository.findByBarCode(productPreferenceDto.getBarCode());
            if (!productOpt.isPresent()) {
                return new ResponseMessage<>(404, "Product not found", null);
            }
            
            // check if preference already exists
            Optional<ProductPreference> existingPreference = 
                productPreferenceRepository.findByUserIdAndBarCode(userId, productPreferenceDto.getBarCode());
            
            ProductPreference preference;
            if (existingPreference.isPresent()) {
                // update existing preference
                preference = existingPreference.get();
                preference.setPreferenceType(productPreferenceDto.getPreferenceType());
                preference.setReason(productPreferenceDto.getReason());
            } else {
                // create new preference
                preference = new ProductPreference();
                preference.setUserId(userId);
                preference.setBarCode(productPreferenceDto.getBarCode());
                preference.setPreferenceType(productPreferenceDto.getPreferenceType());
                preference.setReason(productPreferenceDto.getReason());
                preference.setCreatedAt(LocalDateTime.now());
            }
            
            ProductPreference savedPreference = productPreferenceRepository.save(preference);
            ProductPreferenceDto resultDto = convertToDto(savedPreference, productOpt.get());
            
            return ResponseMessage.success(resultDto);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to set product preference: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<PagedResponseDto<ProductPreferenceDto>> getUserProductPreferences(
            Integer userId, PreferenceType type, Integer page, Integer size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<ProductPreference> preferencePage;
            
            if (type != null) {
                preferencePage = productPreferenceRepository.findByUserIdAndPreferenceTypeOrderByCreatedAtDesc(
                    userId, type, pageable);
            } else {
                preferencePage = productPreferenceRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
            }
            
            List<ProductPreferenceDto> preferenceDtos = preferencePage.getContent().stream()
                    .map(this::convertToDtoWithProduct)
                    .collect(Collectors.toList());
            
            PagedResponseDto<ProductPreferenceDto> result = new PagedResponseDto<>(
                preferenceDtos, (int) preferencePage.getTotalElements());
            
            return ResponseMessage.success(result);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to get user preferences: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<ProductPreferenceDto> getProductPreference(Integer userId, String barCode) {
        try {
            Optional<ProductPreference> preferenceOpt = 
                productPreferenceRepository.findByUserIdAndBarCode(userId, barCode);
            
            if (!preferenceOpt.isPresent()) {
                return new ResponseMessage<>(404, "Preference not found", null);
            }
            
            ProductPreferenceDto dto = convertToDtoWithProduct(preferenceOpt.get());
            return ResponseMessage.success(dto);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to get product preference: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<String> deleteProductPreference(Integer userId, String barCode) {
        try {
            if (!productPreferenceRepository.existsByUserIdAndBarCode(userId, barCode)) {
                return new ResponseMessage<>(404, "Preference not found", null);
            }
            
            productPreferenceRepository.deleteByUserIdAndBarCode(userId, barCode);
            return ResponseMessage.success("Preference deleted successfully");
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to delete product preference: " + e.getMessage(), null);
        }
    }
    
    @Override
    public ResponseMessage<Map<String, Long>> getUserPreferenceStats(Integer userId) {
        try {
            List<Object[]> stats = productPreferenceRepository.getPreferenceStatsByUserId(userId);
            Map<String, Long> statsMap = new HashMap<>();
            
            // initialize with zero counts
            statsMap.put("like", 0L);
            statsMap.put("dislike", 0L);
            statsMap.put("blacklist", 0L);
            
            // populate with actual counts
            for (Object[] stat : stats) {
                PreferenceType type = (PreferenceType) stat[0];
                Long count = (Long) stat[1];
                statsMap.put(type.getCode(), count);
            }
            
            return ResponseMessage.success(statsMap);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Failed to get preference statistics: " + e.getMessage(), null);
        }
    }
    
    @Override
    public List<String> getUserBlacklistedProducts(Integer userId) {
        return productPreferenceRepository.findBlacklistedBarCodesByUserId(userId);
    }
    
    @Override
    public List<String> getUserLikedProducts(Integer userId) {
        return productPreferenceRepository.findLikedBarCodesByUserId(userId);
    }
    
    /**
     * convert ProductPreference entity to DTO
     */
    private ProductPreferenceDto convertToDto(ProductPreference preference, Product product) {
        ProductPreferenceDto dto = new ProductPreferenceDto();
        dto.setPreferenceId(preference.getPreferenceId());
        dto.setUserId(preference.getUserId());
        dto.setBarCode(preference.getBarCode());
        dto.setPreferenceType(preference.getPreferenceType());
        dto.setReason(preference.getReason());
        dto.setCreatedAt(preference.getCreatedAt());
        
        if (product != null) {
            dto.setProductName(product.getProductName());
            dto.setBrand(product.getBrand());
            dto.setCategory(product.getCategory());
        }
        
        return dto;
    }
    
    /**
     * convert ProductPreference entity to DTO with product information
     */
    private ProductPreferenceDto convertToDtoWithProduct(ProductPreference preference) {
        Product product = null;
        if (preference.getProduct() != null) {
            product = preference.getProduct();
        } else {
            // fallback to fetch product if not loaded
            Optional<Product> productOpt = productRepository.findByBarCode(preference.getBarCode());
            if (productOpt.isPresent()) {
                product = productOpt.get();
            }
        }
        
        return convertToDto(preference, product);
    }
} 