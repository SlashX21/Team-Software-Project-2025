package org.product.service;

import org.product.pojo.Product;
import org.product.pojo.DTO.ProductDto;

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
