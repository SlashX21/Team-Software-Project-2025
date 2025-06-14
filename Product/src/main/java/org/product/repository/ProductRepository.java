package org.product.repository;

import org.product.pojo.Product;
import java.util.Optional;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository //把这个类注册为Spring Bean
public interface ProductRepository extends CrudRepository<Product, String> {
    Optional<Product> findByBarCode(String barCode);
    void deleteByBarCode(String barCode);
    boolean existsByBarCode(String barCode);
}
