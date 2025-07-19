# Sugar Intake History API Documentation

## 概述
糖分摄入记录API提供了完整的糖分摄入历史管理功能，包括添加、查询、更新、删除记录，以及统计分析功能。

## 基础URL
```
/user/{userId}/sugar-intake
```

## API 端点

### 1. 添加糖分摄入记录
**POST** `/user/{userId}/sugar-intake`

**请求体示例：**
```json
{
  "food_name": "苹果",
  "sugar_amount_mg": 12500.0,
  "intake_time": "2024-01-15 14:30:00",
  "source_type": "manual",
  "barcode": "1234567890123",
  "serving_size": "1个中等大小"
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "success!",
  "data": {
    "intake_id": 1,
    "user_id": 1,
    "food_name": "苹果",
    "sugar_amount_mg": 12500.0,
    "intake_time": "2024-01-15 14:30:00",
    "source_type": "manual",
    "barcode": "1234567890123",
    "serving_size": "1个中等大小",
    "created_at": "2024-01-15 14:30:00"
  }
}
```

### 2. 获取用户所有糖分摄入记录
**GET** `/user/{userId}/sugar-intake`

**响应示例：**
```json
{
  "code": 200,
  "message": "success!",
  "data": [
    {
      "intake_id": 1,
      "user_id": 1,
      "food_name": "苹果",
      "sugar_amount_mg": 12500.0,
      "intake_time": "2024-01-15 14:30:00",
      "source_type": "manual",
      "barcode": "1234567890123",
      "serving_size": "1个中等大小",
      "created_at": "2024-01-15 14:30:00"
    }
  ]
}
```

### 3. 根据ID获取糖分摄入记录
**GET** `/user/{userId}/sugar-intake/{intakeId}`

### 4. 更新糖分摄入记录
**PUT** `/user/{userId}/sugar-intake/{intakeId}`

**请求体示例：**
```json
{
  "food_name": "苹果（更新）",
  "sugar_amount_mg": 13000.0,
  "serving_size": "1个大苹果"
}
```

### 5. 删除糖分摄入记录
**DELETE** `/user/{userId}/sugar-intake/{intakeId}`

### 6. 计算今日总糖分摄入量
**GET** `/user/{userId}/sugar-intake/today-total`

**响应示例：**
```json
{
  "code": 200,
  "message": "success!",
  "data": 45000.0
}
```

### 7. 获取最近N条记录
**GET** `/user/{userId}/sugar-intake/recent?limit=10`

### 8. 根据食物名称搜索记录
**GET** `/user/{userId}/sugar-intake/search?foodName=苹果`

### 9. 获取每日糖分摄入统计
**GET** `/user/{userId}/sugar-intake/daily-stats`

**响应示例：**
```json
{
  "code": 200,
  "message": "success!",
  "data": [
    {
      "date": "2024-01-15",
      "totalSugar": 45000.0
    },
    {
      "date": "2024-01-14",
      "totalSugar": 38000.0
    }
  ]
}
```

### 10. 批量添加糖分摄入记录
**POST** `/user/{userId}/sugar-intake/batch`

**请求体示例：**
```json
[
  {
    "food_name": "苹果",
    "sugar_amount_mg": 12500.0,
    "intake_time": "2024-01-15 14:30:00",
    "source_type": "manual"
  },
  {
    "food_name": "香蕉",
    "sugar_amount_mg": 15000.0,
    "intake_time": "2024-01-15 15:00:00",
    "source_type": "scan",
    "barcode": "9876543210987"
  }
]
```

### 11. 统计用户糖分摄入记录数量
**GET** `/user/{userId}/sugar-intake/count`

### 12. 删除用户所有糖分摄入记录
**DELETE** `/user/{userId}/sugar-intake`

## 数据模型

### SugarIntakeHistoryDto
| 字段 | 类型 | 必填 | 描述 |
|------|------|------|------|
| intake_id | Integer | 否 | 记录ID（自动生成） |
| user_id | Integer | 是 | 用户ID |
| food_name | String | 是 | 食物名称（最大200字符） |
| sugar_amount_mg | Float | 是 | 糖分含量（毫克） |
| intake_time | DateTime | 是 | 摄入时间 |
| source_type | String | 否 | 来源类型（scan/manual/receipt，默认manual） |
| barcode | String | 否 | 条形码（最大255字符） |
| serving_size | String | 否 | 份量大小（最大50字符） |
| created_at | DateTime | 否 | 创建时间（自动生成） |

### SourceType 枚举
- `scan`: 扫描获得
- `manual`: 手动输入
- `receipt`: 小票识别

## 错误处理

### 常见错误码
- `400`: 请求参数错误
- `404`: 记录不存在
- `500`: 服务器内部错误

### 错误响应示例
```json
{
  "code": 404,
  "message": "Sugar intake record not found with ID: 999",
  "data": null
}
```

## 使用示例

### 添加一条糖分摄入记录
```bash
curl -X POST http://localhost:8080/user/1/sugar-intake \
  -H "Content-Type: application/json" \
  -d '{
    "food_name": "苹果",
    "sugar_amount_mg": 12500.0,
    "intake_time": "2024-01-15 14:30:00",
    "source_type": "manual",
    "serving_size": "1个中等大小"
  }'
```

### 获取用户今日总糖分摄入量
```bash
curl http://localhost:8080/user/1/sugar-intake/today-total
```

### 搜索包含"苹果"的记录
```bash
curl http://localhost:8080/user/1/sugar-intake/search?foodName=苹果
```

## 注意事项

1. **时间格式**: 所有时间字段使用格式 `yyyy-MM-dd HH:mm:ss`
2. **糖分单位**: 糖分含量以毫克（mg）为单位
3. **用户验证**: 所有API都需要有效的用户ID
4. **数据验证**: 糖分含量必须为非负数
5. **级联删除**: 删除用户时会自动删除相关的糖分摄入记录 