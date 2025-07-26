# 📚 Grocery Guardian 功能 & 接口文档

## 📝 目录

1. 前端功能
2. 后端功能及接口（标准格式）

---

## 📱 1. 前端功能

- 用户注册 / 登录 / 个人资料编辑
- 扫描商品条码并获取推荐
- 上传小票图片并分析营养信息
- 显示每日 / 月度糖分摄入情况
- 查看历史推荐记录和购物记录
- 设置每日糖分健康目标
- 查看健康报告和趋势分析

---

## 🖇️ 2. 后端功能及接口

### 用户管理

#### 注册
- **请求方式**: POST
- **端口**: 8080
- **URL**: `/user/register`
- **功能**: 注册新用户，若用户名已存在返回错误
- **请求示例**:
```json
{
  "userName": "example",
  "passwordHash": "hashedPassword"
}
```

#### 登录
- **请求方式**: POST
- **端口**: 8080
- **URL**: `/user/login`
- **功能**: 检查用户名是否存在并验证密码，防止SQL注入
- **请求示例**:
```json
{
  "userName": "example",
  "passwordHash": "hashedPassword"
}
```

### 推荐系统

#### 条码推荐
- **请求方式**: POST
- **端口**: 8001
- **URL**: `/recommendations/barcode`
- **功能**: 根据条码返回个性化推荐
- **请求示例**:
```json
{
  "userId": 1,
  "productBarcode": "5000112548167"
}
```

#### 小票推荐
- **请求方式**: POST
- **端口**: 8001
- **URL**: `/recommendations/receipt`
- **功能**: 分析购物清单并返回营养分析与推荐
- **请求示例**:
```json
{
  "userId": 1,
  "purchasedItems": [
    { "productName": "Coca Cola", "quantity": 2 },
    { "productName": "Whole Wheat Bread", "quantity": 1 }
  ]
}
```

#### 推荐系统健康检查
- **请求方式**: GET
- **端口**: 8001
- **URL**: `/recommendations/health`
- **功能**: 检查推荐系统状态

### 糖分追踪

#### 设置糖分目标
- **请求方式**: POST
- **端口**: 8080
- **URL**: `/sugar/target`
- **功能**: 设置每日糖分目标
- **请求示例**:
```json
{
  "userId": 1,
  "targetAmount": 30
}
```

#### 记录摄入
- **请求方式**: POST
- **端口**: 8080
- **URL**: `/sugar/intake`
- **功能**: 记录摄入糖分
- **请求示例**:
```json
{
  "userId": 1,
  "amount": 10,
  "source": "Coca Cola"
}
```

#### 查询月度统计
- **请求方式**: GET
- **端口**: 8080
- **URL**: `/sugar/monthly-summary?userId=1`
- **功能**: 返回月度统计

### 其他模块

#### 过敏源分析
- **请求方式**: POST
- **端口**: 8080
- **URL**: `/allergens/analyze`
- **功能**: 分析商品是否包含用户敏感成分
- **请求示例**:
```json
{
  "userId": 1,
  "productName": "Peanut Butter"
}
```

#### OCR 小票识别
- **请求方式**: POST
- **端口**: 8000
- **URL**: `/ocr/parse`
- **功能**: 解析小票图片
- **请求格式**: Multipart Form Data (上传图片)
- **返回示例**:
```json
{
  "success": true,
  "data": [
    { "productName": "Milk", "quantity": 1 },
    { "productName": "Bread", "quantity": 2 }
  ]
}
```

### 商品管理

#### 查询所有商品
- **请求方式**: GET
- **端口**: 8080
- **URL**: `/products`
- **功能**: 获取商品列表
- **返回示例**:
```json
[
  { "id": 1, "name": "Coca Cola", "category": "Drink", "price": 3.5 },
  { "id": 2, "name": "Bread", "category": "Food", "price": 2.0 }
]
```

#### 新增商品
- **请求方式**: POST
- **端口**: 8080
- **URL**: `/products`
- **功能**: 新增商品
- **请求示例**:
```json
{
  "name": "Coca Cola",
  "category": "Drink",
  "price": 3.5
}
```

#### 修改商品
- **请求方式**: PUT
- **端口**: 8080
- **URL**: `/products/{productId}`
- **功能**: 更新指定商品信息
- **请求示例**:
```json
{
  "name": "Coca Cola Zero",
  "category": "Drink",
  "price": 3.0
}
```

#### 删除商品
- **请求方式**: DELETE
- **端口**: 8080
- **URL**: `/products/{productId}`
- **功能**: 删除指定商品

### 用户偏好管理

#### 设置偏好
- **请求方式**: POST
- **端口**: 8080
- **URL**: `/user/preferences`
- **功能**: 记录用户饮食偏好
- **请求示例**:
```json
{
  "userId": 1,
  "preferences": ["Low Sugar", "Vegetarian"]
}
```
- **返回示例**:
```json
{
  "success": true
}
```

### 用户历史记录

#### 查询历史
- **请求方式**: GET
- **端口**: 8080
- **URL**: `/user/history?userId=1`
- **功能**: 查询用户历史记录
- **返回示例**:
```json
[
  { "date": "2024-07-12", "action": "Purchased Coca Cola" },
  { "date": "2024-07-11", "action": "Redeemed Coupon" }
]
```

