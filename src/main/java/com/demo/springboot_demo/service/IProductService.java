package com.demo.springboot_demo.service;

import com.demo.springboot_demo.pojo.Product;
import com.demo.springboot_demo.pojo.DTO.ProductDto;

public interface IProductService {
    /**
     * insert product
     *
     * @param product
     * @return
     */
    Product add(ProductDto user);

    /**
     * query product
     * @param barCode barCode
     * @return
     */
    Product getProduct(String barCode);

    /**
     * update product
     * @param product
     * @return
     */
    Product edit(ProductDto product);

    /**
     * delete product
     * @param barCode barCode
     * @return
     */
    void delete(String barCode);
}
