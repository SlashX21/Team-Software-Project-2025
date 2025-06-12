package com.demo.springboot_demo.repository;

import com.demo.springboot_demo.pojo.Product;
import java.util.Optional;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository //把这个类注册为Spring Bean
public interface ProductRepository extends CrudRepository<Product, String> {
    Optional<Product> findByBarCode(String barCode);
    void deleteByBarCode(String barCode);
    boolean existsByBarCode(String barCode);
}
