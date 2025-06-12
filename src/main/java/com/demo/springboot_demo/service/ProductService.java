package com.demo.springboot_demo.service;

import com.demo.springboot_demo.pojo.DTO.ProductDto;
import com.demo.springboot_demo.pojo.Product;
import com.demo.springboot_demo.repository.ProductRepository;
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
        Product productDto = new Product();
        BeanUtils.copyProperties(product, productDto);

        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        productDto.setCreatedAt(now.format(formatter));
        
        return productRepository.save(productDto);
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
        Product productDto = new Product();
        BeanUtils.copyProperties(product, productDto);

        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        productDto.setUpdatedAt(now.format(formatter));
        return productRepository.save(productDto);
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
