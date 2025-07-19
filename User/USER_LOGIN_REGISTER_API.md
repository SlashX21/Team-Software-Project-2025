# 用户登录注册 API 文档

## 概述
用户登录注册API提供了完整的用户认证和账户管理功能，包括用户注册、登录、查询、更新和删除等操作。

## 基础URL
```
/user
```

## API 端点

### 1. 用户注册
**POST** `/user`

**描述:** 创建新的用户账户

**请求体示例:**
```json
{
  "userName": "testuser",
  "passwordHash": "123456",
  "email": "test@example.com",
  "age": 25,
  "gender": "MALE",
  "heightCm": 175,
  "weightKg": 70.5,
  "activityLevel": "MODERATELY_ACTIVE",
  "nutritionGoal": "WEIGHT_MAINTENANCE",
  "dailyCaloriesTarget": 2000.0,
  "dailyProteinTarget": 150.0,
  "dailyCarbTarget": 250.0,
  "dailyFatTarget": 65.0,
  "date_of_birth": "1999-01-01"
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "success!",
  "data": {
    "userId": 1,
    "userName": "testuser",
    "email": "test@example.com",
    "age": 25,
    "gender": "MALE",
    "heightCm": 175,
    "weightKg": 70.5,
    "activityLevel": "MODERATELY_ACTIVE",
    "nutritionGoal": "WEIGHT_MAINTENANCE",
    "dailyCaloriesTarget": 2000.0,
    "dailyProteinTarget": 150.0,
    "dailyCarbTarget": 250.0,
    "dailyFatTarget": 65.0,
    "date_of_birth": "1999-01-01",
    "createdTime": "2024-01-15 14:30:00",
    "updatedTime": null
  }
}
```

**错误响应示例:**
```json
{
  "code": 400,
  "message": "Error: user name already exists.",
  "data": null
}
```

### 2. 用户登录
**POST** `/user/login`

**描述:** 用户登录验证

**请求体示例:**
```json
{
  "userName": "testuser",
  "passwordHash": "123456"
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "success!",
  "data": {
    "userId": 1,
    "userName": "testuser",
    "email": "test@example.com",
    "age": 25,
    "gender": "MALE",
    "heightCm": 175,
    "weightKg": 70.5,
    "activityLevel": "MODERATELY_ACTIVE",
    "nutritionGoal": "WEIGHT_MAINTENANCE",
    "dailyCaloriesTarget": 2000.0,
    "dailyProteinTarget": 150.0,
    "dailyCarbTarget": 250.0,
    "dailyFatTarget": 65.0,
    "date_of_birth": "1999-01-01",
    "createdTime": "2024-01-15 14:30:00",
    "updatedTime": null
  }
}
```

**错误响应示例:**
```json
{
  "code": 400,
  "message": "Error: user name or password is incorrect.",
  "data": null
}
```

### 3. 获取用户信息
**GET** `/user/{userId}`

**描述:** 根据用户ID获取用户详细信息

**路径参数:**
- `userId` (Integer): 用户ID

**响应示例:**
```json
{
  "code": 200,
  "message": "success!",
  "data": {
    "userId": 1,
    "userName": "testuser",
    "email": "test@example.com",
    "age": 25,
    "gender": "MALE",
    "heightCm": 175,
    "weightKg": 70.5,
    "activityLevel": "MODERATELY_ACTIVE",
    "nutritionGoal": "WEIGHT_MAINTENANCE",
    "dailyCaloriesTarget": 2000.0,
    "dailyProteinTarget": 150.0,
    "dailyCarbTarget": 250.0,
    "dailyFatTarget": 65.0,
    "date_of_birth": "1999-01-01",
    "createdTime": "2024-01-15 14:30:00",
    "updatedTime": null
  }
}
```

**错误响应示例:**
```json
{
  "code": 400,
  "message": "User not exist.",
  "data": null
}
```

### 4. 更新用户信息
**PUT** `/user`

**描述:** 更新用户信息

**请求体示例:**
```json
{
  "userId": 1,
  "userName": "testuser",
  "email": "newemail@example.com",
  "age": 26,
  "gender": "MALE",
  "heightCm": 175,
  "weightKg": 68.0,
  "activityLevel": "VERY_ACTIVE",
  "nutritionGoal": "WEIGHT_LOSS",
  "dailyCaloriesTarget": 1800.0,
  "dailyProteinTarget": 140.0,
  "dailyCarbTarget": 200.0,
  "dailyFatTarget": 55.0
}
```

**响应示例:**
```json
{
  "code": 200,
  "message": "success!",
  "data": {
    "userId": 1,
    "userName": "testuser",
    "email": "newemail@example.com",
    "age": 26,
    "gender": "MALE",
    "heightCm": 175,
    "weightKg": 68.0,
    "activityLevel": "VERY_ACTIVE",
    "nutritionGoal": "WEIGHT_LOSS",
    "dailyCaloriesTarget": 1800.0,
    "dailyProteinTarget": 140.0,
    "dailyCarbTarget": 200.0,
    "dailyFatTarget": 55.0,
    "date_of_birth": "1999-01-01",
    "createdTime": "2024-01-15 14:30:00",
    "updatedTime": "2024-01-16 10:15:00"
  }
}
```

### 5. 删除用户
**DELETE** `/user/{userId}`

**描述:** 删除用户账户

**路径参数:**
- `userId` (Integer): 用户ID

**响应示例:**
```json
{
  "code": 200,
  "message": "success!",
  "data": null
}
```

## 数据模型

### UserDto (请求数据传输对象)
| 字段 | 类型 | 必填 | 验证规则 | 描述 |
|------|------|------|----------|------|
| userId | Integer | 否 | - | 用户ID（更新时需要） |
| userName | String | 是 | 不能为空 | 用户名（唯一） |
| passwordHash | String | 是 | 长度6-12位 | 密码哈希 |
| email | String | 否 | 邮箱格式 | 邮箱地址 |
| age | Integer | 否 | - | 年龄 |
| gender | Gender | 否 | 枚举值 | 性别 |
| heightCm | Integer | 否 | - | 身高（厘米） |
| weightKg | Float | 否 | - | 体重（公斤） |
| activityLevel | ActivityLevel | 否 | 枚举值 | 活动水平 |
| nutritionGoal | NutritionGoal | 否 | 枚举值 | 营养目标 |
| dailyCaloriesTarget | Float | 否 | - | 每日卡路里目标 |
| dailyProteinTarget | Float | 否 | - | 每日蛋白质目标（克） |
| dailyCarbTarget | Float | 否 | - | 每日碳水化合物目标（克） |
| dailyFatTarget | Float | 否 | - | 每日脂肪目标（克） |
| date_of_birth | String | 否 | 日期格式 | 出生日期（YYYY-MM-DD） |

### User (响应数据对象)
包含UserDto的所有字段，另外还有：
| 字段 | 类型 | 描述 |
|------|------|------|
| createdTime | String | 创建时间（YYYY-MM-DD HH:mm:ss） |
| updatedTime | String | 更新时间（YYYY-MM-DD HH:mm:ss） |

### 枚举类型

#### Gender (性别)
- `MALE`: 男
- `FEMALE`: 女  
- `OTHER`: 其他

#### ActivityLevel (活动水平)
- `SEDENTARY`: 久坐不动
- `LIGHTLY_ACTIVE`: 轻度活动
- `MODERATELY_ACTIVE`: 中度活动
- `VERY_ACTIVE`: 重度活动
- `EXTRA_ACTIVE`: 极度活动

#### NutritionGoal (营养目标)
- `WEIGHT_LOSS`: 减重
- `WEIGHT_MAINTENANCE`: 维持体重
- `WEIGHT_GAIN`: 增重
- `MUSCLE_GAIN`: 增肌
- `HEALTH_MAINTENANCE`: 健康维持

## 错误处理

### 常见错误码
- `200`: 成功
- `400`: 请求参数错误/业务逻辑错误
- `404`: 资源不存在
- `500`: 服务器内部错误

### 错误响应格式
```json
{
  "code": 400,
  "message": "错误描述信息",
  "data": null
}
```

## 使用示例

### 用户注册
```bash
curl -X POST http://localhost:8080/user \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "testuser",
    "passwordHash": "123456",
    "email": "test@example.com",
    "age": 25,
    "gender": "MALE",
    "heightCm": 175,
    "weightKg": 70.5,
    "activityLevel": "MODERATELY_ACTIVE",
    "nutritionGoal": "WEIGHT_MAINTENANCE"
  }'
```

### 用户登录
```bash
curl -X POST http://localhost:8080/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "testuser",
    "passwordHash": "123456"
  }'
```

### 获取用户信息
```bash
curl http://localhost:8080/user/1
```

### 更新用户信息
```bash
curl -X PUT http://localhost:8080/user \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "userName": "testuser",
    "email": "newemail@example.com",
    "age": 26,
    "weightKg": 68.0,
    "activityLevel": "VERY_ACTIVE",
    "nutritionGoal": "WEIGHT_LOSS"
  }'
```

### 删除用户
```bash
curl -X DELETE http://localhost:8080/user/1
```

## 注意事项

1. **密码安全**: 前端需要对密码进行哈希处理后再发送到后端
2. **用户名唯一性**: 注册时系统会检查用户名是否已存在
3. **邮箱格式**: 邮箱字段需要符合标准邮箱格式
4. **数据验证**: 所有必填字段都会进行验证
5. **时间格式**: 所有时间字段使用格式 `yyyy-MM-dd HH:mm:ss`
6. **日期格式**: 出生日期使用格式 `yyyy-MM-dd`
7. **枚举值**: 性别、活动水平、营养目标必须使用预定义的枚举值
8. **级联删除**: 删除用户时会自动删除用户相关的所有数据

## 安全建议

1. 建议在生产环境中使用HTTPS
2. 密码应该在前端进行哈希处理
3. 建议添加用户认证和授权机制
4. 考虑添加登录失败次数限制
5. 建议添加用户会话管理功能 