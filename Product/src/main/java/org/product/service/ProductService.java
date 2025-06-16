package org.product.service;

import org.product.pojo.DTO.ProductDto;
import org.product.pojo.Product;
import org.product.repository.ProductRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

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

        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        productPojo.setCreatedAt(now.format(formatter));
        
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

        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        existingProduct.setUpdatedAt(now.format(formatter));

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
}
