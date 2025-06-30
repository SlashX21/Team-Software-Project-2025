
# 📄 新增功能说明：根据商品名称获取产品信息接口（含 barcode）

---

## ✅ 1. `Product\src\main\java\org\product\controller\ProductController.java`：添加新接口方法

```java
@GetMapping("/name/{productName}")
public ResponseEntity<Response<ProductDto>> getProductByName(@PathVariable String productName) {
    ProductDto productDto = productService.getProductByName(productName);
    return ResponseEntity.ok(new Response<>(productDto));
}
```

> 路径：`GET /product/name/{productName}`  
> 返回：封装了产品信息（包括 `barCode`, `ingredients`, `allergens` 等）的 JSON 响应

---

## ✅ 2. `IProductService.java`：添加方法签名

```java
Product getByName(String productName);
```

---

## ✅ 3. `ProductService.java`：添加接口实现

```java
@Override
public Product getByName(String productName) {
    return productRepository.findByProductNameIgnoreCase(productName)
            .orElseThrow(() -> new RuntimeException("Product not found with name: " + productName));
}
```

---

## ✅ 4. `ProductRepository.java`：添加 JPA 查询方法（若尚未定义）

```java
Optional<Product> findByProductNameIgnoreCase(String productName);
```

---

## 🔁 使用示例

调用以下接口：

```
GET http://localhost:8080/product/name/Mango
```

返回示例（JSON）：

```json
{
	"code": 200,
	"message": "success!",
	"data": {
		"barCode": "10067819",
		"productName": "Mango",
		"brand": "Tesco",
		"ingredients": "Dried Mango, Preservative (_Sulphur Dioxide_).",
		"allergens": "mango, sulphur-dioxide-and-sulphites",
		"energy100g": 1400,
		"energyKcal100g": 331,
		"fat100g": 1.4,
		"saturatedFat100g": 0.4,
		"carbohydrates100g": 73.5,
		"sugars100g": 51.6,
		"proteins100g": 2.3,
		"servingSize": "30g",
		"category": "Other",
		"createdAt": "2025-06-29 01:45:24",
		"updatedAt": "2025-06-29 01:45:24"
	}
}
```

---

## 📌 注意事项

- 控制器返回结构应为统一封装的 `Response<T>` 类（已假设存在）。
- `productMapper.toDto(product)` 方法默认正确映射 `Product` → `ProductDto`。
- 请确保数据库中存在该名称的产品，否则会抛出 `RuntimeException`。
