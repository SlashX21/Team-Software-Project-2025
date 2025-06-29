# Phase 1: 用户会话管理实现方案

## 目标
解决当前系统缺乏用户会话管理的问题，实现登录状态的持久化存储和管理。

## 当前问题分析
- 系统有loginUser()函数但登录后没有保存用户信息
- 代码中使用硬编码的userId而非实际登录用户ID
- 缺乏全局用户状态管理和会话验证机制

## 实现方案

### 1. 依赖确认
确保 `pubspec.yaml` 包含：
```yaml
dependencies:
  shared_preferences: ^2.2.2
```

### 2. 创建用户服务类
**新建文件**: `lib/services/user_service.dart`

**核心功能**:
- 保存登录用户信息到SharedPreferences
- 获取当前登录用户ID和信息
- 检查用户登录状态
- 处理用户登出
- 应用启动时自动检查登录状态

**需要存储的用户信息**:
- userId (int) - 主要标识
- userName (String)
- email (String) 
- loginTime (String) - 登录时间戳

**主要方法**:
- `saveUserInfo(Map<String, dynamic> userData)` - 保存用户信息
- `getCurrentUserId()` - 获取当前用户ID
- `getCurrentUser()` - 获取完整用户信息
- `isLoggedIn()` - 检查是否已登录
- `logout()` - 清除用户信息
- `getUserName()` - 获取用户名

### 3. 修改现有登录流程
**需要修改的位置**: 调用 `loginUser()` API成功的地方

**修改内容**:
- 在API调用成功后，立即调用 `UserService.saveUserInfo()` 保存用户数据
- 保存成功后再进行页面跳转
- 添加保存失败的错误处理

### 4. 应用启动检查
**修改文件**: `lib/main.dart`

**实现功能**:
- 应用启动时检查是否有保存的登录状态
- 根据登录状态决定显示登录页面还是主页面
- 自动跳转逻辑

### 5. 登出功能实现
**在需要登出的地方**:
- 调用 `UserService.logout()` 清除所有用户数据
- 跳转回登录页面
- 清除应用状态

## 错误处理要求

### SharedPreferences操作错误
- 保存失败时显示具体错误信息
- 读取失败时返回null或默认值
- 添加try-catch包装所有异步操作

### 数据验证
- 检查保存的userId是否有效
- 验证登录时间是否过期（可选）
- 处理数据格式异常

## 测试验证要点

### 基本功能测试
1. 登录成功后用户信息正确保存
2. 应用重启后登录状态保持
3. getUserId()能正确返回当前用户ID
4. 登出功能完全清除用户数据

### 边界情况测试
1. 首次安装应用（无保存数据）
2. SharedPreferences数据损坏
3. 多次登录不同用户的数据覆盖
4. 网络异常时的登录流程

## 具体文件操作指导

### 创建新文件
- `lib/services/user_service.dart` - 用户服务类

### 修改现有文件
- `lib/main.dart` - 添加启动时登录状态检查
- 登录相关的页面文件 - 添加用户信息保存逻辑
- 需要获取用户ID的地方 - 替换硬编码为动态获取

### 不需要修改的文件
- `lib/services/api.dart` - loginUser()方法保持不变
- 其他业务逻辑文件 - 暂不涉及

## 实施优先级

### 高优先级（必须实现）
1. UserService基础类创建
2. 登录成功后保存用户信息
3. getCurrentUserId()方法实现

### 中优先级（建议实现）
1. 应用启动时状态检查
2. 登出功能实现
3. 完整的错误处理

### 低优先级（可后续优化）
1. 用户信息缓存机制
2. 登录状态过期检查
3. 多用户支持预留

## 验收标准

完成后应该达到：
1. ✅ 用户登录后信息持久化保存
2. ✅ 任何地方都能通过UserService.getCurrentUserId()获取真实用户ID
3. ✅ 应用重启后用户无需重新登录
4. ✅ 登出功能正常工作
5. ✅ 所有硬编码的userId都被替换

## 下一步计划

Phase 1完成并测试通过后，将进入Phase 2：推荐功能集成，届时可以使用真实的用户ID调用推荐接口。