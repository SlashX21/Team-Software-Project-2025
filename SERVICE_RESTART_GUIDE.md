# 服务重启指南

## 重新编译并启动后端服务

由于Product模块的batch-lookup API没有正确加载，需要重新编译并重启服务。

### 步骤1：停止当前运行的服务
按 `Ctrl+C` 停止正在运行的Spring Boot应用

### 步骤2：清理并重新编译
```bash
cd /Users/lixiang/Desktop/UCD/Semester_3/Team-Software-Project-2025-Latest
mvn clean compile
```

### 步骤3：启动后端服务
```bash
cd Backend
mvn spring-boot:run
```

### 步骤4：验证服务启动成功
等待看到以下日志：
- `Started SpringbootDemoApplication`
- 服务端口信息（通常是8080）

### 步骤5：验证Product批量查询API
服务启动后，可以用以下命令测试batch-lookup API：
```bash
curl -X POST http://localhost:8080/product/batch-lookup \
  -H "Content-Type: application/json" \
  -d '{"names": ["Jaffa Cakes", "Large Free Range Eggs"]}'
```

### 步骤6：确保Python推荐服务运行
确认推荐服务在8001端口运行：
```bash
cd Recommendation/src/main/java/org/recommendation/Rec_LLM_Module
python main.py
```

### 步骤7：重新测试小票上传功能
在前端重新上传小票进行测试

## 问题诊断

如果仍然出现405错误，检查：
1. ProductController是否正确编译
2. @PostMapping("/batch-lookup")注解是否存在
3. Spring Boot是否正确扫描到Product模块的控制器

## 预期结果
重启后，小票分析应该能够：
1. 成功调用batch-lookup API
2. 将产品名称转换为条码
3. 返回完整的营养分析和推荐结果