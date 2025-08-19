package org.product.controller;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import org.product.pojo.DTO.ProductDto;
import org.product.pojo.DTO.ProductSearchDto;
import org.product.pojo.DTO.PagedResponseDto;
import org.product.pojo.Product;
import org.product.service.IProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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
    
    /**
     * search products by name
     * GET /product/search?name={productName}&page={page}&size={size}
     */
    @GetMapping("/search")
    public ResponseEntity<ResponseMessage<PagedResponseDto<ProductSearchDto>>> searchProducts(
            @RequestParam("name") String productName,
            @RequestParam(value = "page", defaultValue = "0") Integer page,
            @RequestParam(value = "size", defaultValue = "10") Integer size) {
        
        try {
            PagedResponseDto<ProductSearchDto> result = productService.searchProductsByName(productName, page, size);
            return ResponseEntity.ok(ResponseMessage.success(result));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to search products: " + e.getMessage(), null));
        }
    }
    
    /**
     * get products by category
     * GET /product/category/{category}?page={page}&size={size}
     */
    @GetMapping("/category/{category}")
    public ResponseEntity<ResponseMessage<PagedResponseDto<ProductSearchDto>>> getProductsByCategory(
            @PathVariable String category,
            @RequestParam(value = "page", defaultValue = "0") Integer page,
            @RequestParam(value = "size", defaultValue = "10") Integer size) {
        
        try {
            PagedResponseDto<ProductSearchDto> result = productService.getProductsByCategory(category, page, size);
            return ResponseEntity.ok(ResponseMessage.success(result));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to get products by category: " + e.getMessage(), null));
        }
    }
    
    /**
     * filter products by nutrition criteria
     * GET /product/filter?maxCalories={cal}&maxSugar={sugar}&minProtein={protein}&page={page}&size={size}
     */
    @GetMapping("/filter")
    public ResponseEntity<ResponseMessage<PagedResponseDto<ProductSearchDto>>> filterProductsByNutrition(
            @RequestParam(value = "maxCalories", required = false) Float maxCalories,
            @RequestParam(value = "maxSugar", required = false) Float maxSugar,
            @RequestParam(value = "minProtein", required = false) Float minProtein,
            @RequestParam(value = "page", defaultValue = "0") Integer page,
            @RequestParam(value = "size", defaultValue = "10") Integer size) {
        
        try {
            // validate parameters
            if (maxCalories != null && maxCalories < 0) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "maxCalories must be non-negative", null));
            }
            if (maxSugar != null && maxSugar < 0) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "maxSugar must be non-negative", null));
            }
            if (minProtein != null && minProtein < 0) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "minProtein must be non-negative", null));
            }
            if (page < 0 || size <= 0) {
                return ResponseEntity.badRequest().body(
                    new ResponseMessage<>(400, "page must be non-negative and size must be positive", null));
            }
            
            PagedResponseDto<ProductSearchDto> result = productService.filterProductsByNutrition(
                maxCalories, maxSugar, minProtein, page, size);
            return ResponseEntity.ok(ResponseMessage.success(result));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                new ResponseMessage<>(500, "Failed to filter products by nutrition: " + e.getMessage(), null));
        }
    }

    /**
     * Batch lookup products by a list of names
     * POST /product/batch-lookup
     * Body: { "names": ["name1", "name2", ...] }
     * Response: { "results": [ { "productName": ..., "barcode": ... }, ... ] }
     */
    @PostMapping("/batch-lookup")
    public ResponseEntity<?> batchLookup(@RequestBody java.util.Map<String, java.util.List<String>> request) {
        java.util.List<String> names = request.get("names");
        if (names == null || names.isEmpty()) {
            return ResponseEntity.badRequest().body(java.util.Map.of(
                "results", java.util.Collections.emptyList(),
                "message", "No product names provided"
            ));
        }
        java.util.List<org.product.pojo.Product> products = productService.batchLookupByNames(names);
        // Map found products by lowercased name for quick lookup
        java.util.Map<String, String> nameToBarcode = new java.util.HashMap<>();
        for (org.product.pojo.Product p : products) {
            if (p.getProductName() != null && p.getBarCode() != null) {
                nameToBarcode.put(p.getProductName().toLowerCase(), p.getBarCode());
            }
        }
        // Build result list, preserving input order
        java.util.List<java.util.Map<String, String>> results = new java.util.ArrayList<>();
        for (String name : names) {
            String barcode = nameToBarcode.get(name.trim().toLowerCase());
            if (barcode != null) {
                results.add(java.util.Map.of("productName", name, "barcode", barcode));
            } else {
                results.add(java.util.Map.of("productName", name, "barcode", ""));
            }
        }
        return ResponseEntity.ok(java.util.Map.of("results", results));
    }

    /**
     * Count sustainable products by a list of names
     * POST /product/count-sustainable
     * Body: { "names": ["name1", "name2", ...] }
     * Response: { "sustainableCount": 2, "totalCount": 5, "sustainablePercentage": 40 }
     */
    @PostMapping("/count-sustainable")
    public ResponseEntity<?> countSustainableProducts(@RequestBody java.util.Map<String, java.util.List<String>> request) {
        java.util.List<String> names = request.get("names");
        if (names == null || names.isEmpty()) {
            return ResponseEntity.badRequest().body(java.util.Map.of(
                "sustainableCount", 0,
                "totalCount", 0,
                "sustainablePercentage", 0,
                "message", "No product names provided"
            ));
        }
        
        Long sustainableCount = productService.countSustainableProductsByNames(names);
        Long totalCount = (long) names.size();
        Integer sustainablePercentage = totalCount > 0 ? (int) Math.round((double) sustainableCount / totalCount * 100) : 0;
        
        return ResponseEntity.ok(java.util.Map.of(
            "sustainableCount", sustainableCount,
            "totalCount", totalCount,
            "sustainablePercentage", sustainablePercentage
        ));
    }
}
