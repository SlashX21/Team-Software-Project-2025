package org.product.controller;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import org.product.pojo.DTO.ProductDto;
import org.product.pojo.Product;
import org.product.service.IProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/product") 
public class ProductController {
    @Autowired
    IProductService productService;

    // add new product
    @PostMapping // URL: localhost:8088/product method: post
    public ResponseMessage<Product> add(@Validated @RequestBody ProductDto product){
        // System.out.println("ProductController.add() called");
        // System.out.println("Received ProductDto: " + product.toString());
        Product productNew = productService.add(product);
        return ResponseMessage.success(productNew);
    }

    // query product
    @GetMapping("/{barcode}") // URL: localhost:8088/user/'123456' method: get
    public ResponseMessage<Product> get(@PathVariable String barcode){
        Product productNew = productService.getProduct(barcode);
        return ResponseMessage.success(productNew);
    }
    
    // 修改
    // put mapping
    @PutMapping // URL: localhost:8088/product/ method: put
    public ResponseMessage<Product> edit(@Validated @RequestBody ProductDto product){
        Product productNew = productService.edit(product);
        return ResponseMessage.success(productNew);
    }

    // 如果需要通过barcode来对product进行修改, 则使用这个, 传递barcode和body
    // @PutMapping("/{barcode}")  // 修改为: localhost:8088/product/{barcode} method: PUT
    // public ResponseMessage<Product> edit(@PathVariable String barcode, @Validated @RequestBody ProductDto product){
    //     product.setBarCode(barcode);  // 确保设置条形码
    //     Product productNew = productService.edit(product);
    //     return ResponseMessage.success(productNew);
    // }

    // 删除
    // delete mapping
    @DeleteMapping("/{barcode}") // URL: localhost:8088/product/1 method: get
    public ResponseMessage<Product> delete(@PathVariable String barcode){
        productService.delete(barcode);
        return ResponseMessage.success();
    }

}
