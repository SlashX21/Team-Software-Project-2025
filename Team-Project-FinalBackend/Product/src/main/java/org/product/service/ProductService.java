package org.product.service;

import org.product.pojo.DTO.ProductDto;
import org.product.pojo.DTO.ProductSearchDto;
import org.product.pojo.DTO.PagedResponseDto;
import org.product.pojo.Product;
import org.product.repository.ProductRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class ProductService implements IProductService{
    @Autowired
    ProductRepository productRepository;

    @Override
    public Product add(ProductDto product){
        // System.out.println("Received ProductDto: " + product.toString());
        // System.out.println("ProductDto.getProductName(): " + product.getProductName());
        
        Product productPojo = new Product();
        BeanUtils.copyProperties(product, productPojo);
        // 手动设置字段而不是使用BeanUtils.copyProperties
        // productDto.setBarCode(product.getBarCode());
        // productDto.setProductName(product.getProductName());
        // productDto.setBrand(product.getBrand());
        // productDto.setIngredients(product.getIngredients());
        // productDto.setAllergens(product.getAllergens());
        // productDto.setEnergy100g(product.getEnergy100g());
        // productDto.setEnergyKcal100g(product.getEnergyKcal100g());
        // productDto.setFat100g(product.getFat100g());
        // productDto.setSaturatedFat100g(product.getSaturatedFat100g());
        // productDto.setCarbohydrates100g(product.getCarbohydrates100g());
        // productDto.setSugars100g(product.getSugars100g());
        // productDto.setProteins100g(product.getProteins100g());
        // productDto.setServingSize(product.getServingSize());
        // productDto.setCategory(product.getCategory());
        
        // System.out.println("After manual setting:");
        // System.out.println("Product.getProductName(): " + productDto.getProductName());
        // System.out.println("Product.getBarCode(): " + productDto.getBarCode());

        // LocalDateTime now = LocalDateTime.now();
        // DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        // productPojo.setCreatedAt(now.format(formatter));
        
        return productRepository.save(productPojo);
    }

    /**
     * query product
     * @param barCode barCode
     * @return
     */
    public Product getProduct(String barCode){
        return productRepository.findByBarCode(barCode).orElseThrow(()->{
            throw new IllegalArgumentException("Product not exist.");
        });
    }

    /**
     * update product
     * @param product
     * @return
     */
    public Product edit(ProductDto product){

        // 先查找现有产品
        Product existingProduct = productRepository.findByBarCode(product.getBarCode())
            .orElseThrow(() -> new IllegalArgumentException("Product not exist."));
        
        // 更新现有产品的属性
        BeanUtils.copyProperties(product, existingProduct, "barCode", "createdAt");

        // LocalDateTime now = LocalDateTime.now();
        // DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        // existingProduct.setUpdatedAt(now.format(formatter));

        // 保存更新后的产品
        return productRepository.save(existingProduct);
    }

    /**
     * delete product
     * @param barCode barCode
     * @return
     */
    @Transactional
    public void delete(String barCode){
        if (!productRepository.existsByBarCode(barCode)){
            throw new IllegalArgumentException("Product not exist.");
        }
        productRepository.deleteByBarCode(barCode);
    }
    
    /**
     * search products by name with pagination
     */
    @Override
    public PagedResponseDto<ProductSearchDto> searchProductsByName(String productName, Integer page, Integer size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<Product> productPage = productRepository.searchByProductNameContainingIgnoreCase(productName, pageable);
            
            List<ProductSearchDto> productSearchDtos = productPage.getContent().stream()
                    .map(this::convertToSearchDto)
                    .collect(Collectors.toList());
            
            return new PagedResponseDto<>(productSearchDtos, (int) productPage.getTotalElements());
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to search products by name: " + e.getMessage());
        }
    }
    
    /**
     * get products by category with pagination
     */
    @Override
    public PagedResponseDto<ProductSearchDto> getProductsByCategory(String category, Integer page, Integer size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<Product> productPage = productRepository.findByCategoryIgnoreCase(category, pageable);
            
            List<ProductSearchDto> productSearchDtos = productPage.getContent().stream()
                    .map(this::convertToSearchDto)
                    .collect(Collectors.toList());
            
            return new PagedResponseDto<>(productSearchDtos, (int) productPage.getTotalElements());
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to get products by category: " + e.getMessage());
        }
    }
    
    /**
     * filter products by nutrition criteria
     */
    @Override
    public PagedResponseDto<ProductSearchDto> filterProductsByNutrition(Float maxCalories, Float maxSugar, Float minProtein, Integer page, Integer size) {
        try {
            Pageable pageable = PageRequest.of(page, size);
            Page<Product> productPage = productRepository.filterByNutrition(maxCalories, maxSugar, minProtein, pageable);
            
            List<ProductSearchDto> productSearchDtos = productPage.getContent().stream()
                    .map(product -> convertToNutritionSearchDto(product, maxCalories, maxSugar, minProtein))
                    .collect(Collectors.toList());
            
            return new PagedResponseDto<>(productSearchDtos, (int) productPage.getTotalElements());
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to filter products by nutrition: " + e.getMessage());
        }
    }
    
    /**
     * convert Product entity to ProductSearchDto
     */
    private ProductSearchDto convertToSearchDto(Product product) {
        // calculate a simple match score based on product completeness
        double matchScore = calculateMatchScore(product);
        
        return new ProductSearchDto(
                product.getBarCode(),
                product.getProductName(),
                product.getBrand(),
                product.getCategory(),
                product.getEnergyKcal100g(),
                product.getSugars100g(),
                product.getProteins100g(),
                product.getIsSustainable(),
                matchScore
        );
    }
    
    /**
     * convert Product entity to ProductSearchDto with nutrition-based scoring
     */
    private ProductSearchDto convertToNutritionSearchDto(Product product, Float maxCalories, Float maxSugar, Float minProtein) {
        // calculate nutrition-based match score
        double matchScore = calculateNutritionMatchScore(product, maxCalories, maxSugar, minProtein);
        
        return new ProductSearchDto(
                product.getBarCode(),
                product.getProductName(),
                product.getBrand(),
                product.getCategory(),
                product.getEnergyKcal100g(),
                product.getSugars100g(),
                product.getProteins100g(),
                product.getIsSustainable(),
                matchScore
        );
    }
    
    /**
     * calculate match score based on product data completeness
     */
    private double calculateMatchScore(Product product) {
        double score = 0.0;
        int totalFields = 7; // total number of key fields to check
        
        // check key fields and add to score
        if (product.getProductName() != null && !product.getProductName().trim().isEmpty()) score += 1.0;
        if (product.getBrand() != null && !product.getBrand().trim().isEmpty()) score += 1.0;
        if (product.getCategory() != null && !product.getCategory().trim().isEmpty()) score += 1.0;
        if (product.getEnergyKcal100g() != null) score += 1.0;
        if (product.getSugars100g() != null) score += 1.0;
        if (product.getProteins100g() != null) score += 1.0;
        if (product.getFat100g() != null) score += 1.0;
        
        // normalize to 0-1 range and round to 2 decimal places
        double normalizedScore = score / totalFields;
        return Math.round(normalizedScore * 100.0) / 100.0;
    }
    
    /**
     * calculate nutrition-based match score
     */
    private double calculateNutritionMatchScore(Product product, Float maxCalories, Float maxSugar, Float minProtein) {
        double score = 0.0;
        int criteriaCount = 0;
        
        // check calories criteria
        if (maxCalories != null) {
            criteriaCount++;
            if (product.getEnergyKcal100g() != null) {
                if (product.getEnergyKcal100g() <= maxCalories) {
                    // better score for lower calories (closer to 0)
                    score += 1.0 - (product.getEnergyKcal100g() / maxCalories * 0.5);
                }
            } else {
                score += 0.5; // partial score for missing data
            }
        }
        
        // check sugar criteria
        if (maxSugar != null) {
            criteriaCount++;
            if (product.getSugars100g() != null) {
                if (product.getSugars100g() <= maxSugar) {
                    // better score for lower sugar (closer to 0)
                    score += 1.0 - (product.getSugars100g() / maxSugar * 0.5);
                }
            } else {
                score += 0.5; // partial score for missing data
            }
        }
        
        // check protein criteria
        if (minProtein != null) {
            criteriaCount++;
            if (product.getProteins100g() != null) {
                if (product.getProteins100g() >= minProtein) {
                    // better score for higher protein
                    score += Math.min(1.0, product.getProteins100g() / minProtein * 0.8);
                }
            } else {
                score += 0.3; // lower score for missing protein data
            }
        }
        
        // if no criteria specified, use completeness score
        if (criteriaCount == 0) {
            return calculateMatchScore(product);
        }
        
        // normalize and round
        double normalizedScore = score / criteriaCount;
        return Math.round(normalizedScore * 100.0) / 100.0;
    }

    @Override
    public java.util.List<Product> batchLookupByNames(java.util.List<String> names) {
        if (names == null || names.isEmpty()) return java.util.Collections.emptyList();
        // Lowercase all names for case-insensitive match
        java.util.List<String> lowerNames = names.stream()
            .filter(n -> n != null && !n.trim().isEmpty())
            .map(n -> n.trim().toLowerCase())
            .toList();
        return productRepository.findByProductNameInIgnoreCase(lowerNames);
    }

    @Override
    public Long countSustainableProductsByNames(java.util.List<String> names) {
        if (names == null || names.isEmpty()) return 0L;
        // Lowercase all names for case-insensitive match
        java.util.List<String> lowerNames = names.stream()
            .filter(n -> n != null && !n.trim().isEmpty())
            .map(n -> n.trim().toLowerCase())
            .toList();
        return productRepository.countSustainableProductsByNames(lowerNames);
    }
}
