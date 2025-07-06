
# 🧪 分析结果界面与核心 API 功能文档

本文件记录了前端中 `AnalysisResultScreen` 界面的逻辑说明以及与后端交互的关键 API 接口，包括商品条码查询与小票图片上传分析。

---

## 📱 AnalysisResultScreen 界面说明

### 类功能：

该界面为产品分析结果展示页，提供条码扫描、小票上传及商品信息展示功能。

### 状态变量：

| 变量名            | 类型                      | 功能描述                           |
|-------------------|---------------------------|------------------------------------|
| `_currentAnalysis`| ProductAnalysis?          | 当前扫描到或上传识别的商品信息     |
| `_receiptItems`   | List<Map<String, dynamic>>| 小票识别出的商品条目列表           |
| `_showScanner`    | bool                      | 控制是否展示扫码页面               |
| `_isLoading`      | bool                      | 是否处于加载中                     |
| `_scannedOnce`    | bool                      | 是否已扫描过一次                   |

### 页面结构逻辑：

- 如果 `_showScanner = true`，显示扫码界面（MobileScanner）；
- 否则展示两个按钮（开始扫码、上传小票）；
- 若有分析结果（条码 or 小票），展示商品详细信息列表。

### 主要功能函数：

#### _onBarcodeScanned

- 调用 `fetchProductByBarcode`，根据条形码获取产品分析。
- 若请求成功，更新 `_currentAnalysis`。
- 异常时弹出提示。

#### _uploadReceipt

- 调用 `uploadReceiptImage` 上传用户选择的小票图像。
- 若成功，解析返回商品条目并更新 `_receiptItems`。
- 异常时弹出提示。

---

## 🌐 API 接口说明（核心网络功能）

### 📦 1. fetchProductByBarcode

**功能**：  
通过条形码向服务器请求商品分析信息，包括商品名、图片、配料、过敏原等。

**函数签名**：
```dart
Future<ProductAnalysis> fetchProductByBarcode(String barcode)
```

**请求地址**：
```
GET $baseUrl/product/{barcode}
```

**请求参数**：

| 参数名    | 类型     | 说明           |
|-----------|----------|----------------|
| `barcode` | String   | 商品的条形码编号 |

**响应格式**：
```json
{
  "code": 200,
  "data": {
    "productName": "Organic Milk",
    "imageUrl": "http://...",
    "ingredients": ["Milk", "Water"],
    "allergens": ["Lactose"]
  }
}
```

**处理逻辑**：
- 若返回状态码为 200，则解析 JSON 并构建 `ProductAnalysis` 对象；
- 否则抛出异常：`Product not found`。

**辅助函数说明**：

```dart
List<String> _parseList(dynamic value)
```
- 若为字符串："a, b, c" → [a, b, c]
- 若为列表：["a", "b"] → [a, b]
- 否则返回空列表。

---

### 🧾 2. uploadReceiptImage

**功能**：  
上传用户选中的小票图片给服务器，服务器返回识别出的商品信息列表。

**函数签名**：
```dart
Future<Map<String, dynamic>> uploadReceiptImage(XFile imageFile, int userId)
```

**请求地址**：
```
POST $baseUrl/ocr/scan
```

**请求类型**：`multipart/form-data`

**请求体字段**：

| 字段名     | 类型     | 说明             |
|------------|----------|------------------|
| `userId`   | int      | 用户 ID          |
| `file`     | XFile    | 小票图像（JPEG） |

**响应示例**：
```json
{
  "code": 200,
  "data": {
    "products": [
      {
        "name": "Yogurt",
        "quantity": 2
      },
      {
        "name": "Apple Juice",
        "quantity": 1
      }
    ]
  }
}
```

**异常处理**：
- 若状态码非 200，将抛出 `Exception('Failed to upload receipt')`。

---
