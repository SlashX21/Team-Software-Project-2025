import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyEmail = 'email';
  static const String _keyLoginTime = 'login_time';
  static const String _keyIsLoggedIn = 'is_logged_in';

  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  
  UserService._();

  /// 保存用户信息到SharedPreferences
  // 在 user_service.dart
  Future<bool> saveUserInfo(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // --- START OF MODIFICATION ---
      // 优先检查 'userId' (驼峰命名), 再检查 'user_id' (下划线), 最后检查 'id'
      final dynamic rawUserId = userData['userId'] ?? userData['user_id'] ?? userData['id'];

      // 进行更安全的数据类型转换
      int? userIdToSave;
      if (rawUserId is int) {
        userIdToSave = rawUserId;
      } else if (rawUserId is String) {
        userIdToSave = int.tryParse(rawUserId);
      } else if (rawUserId is double) {
        userIdToSave = rawUserId.toInt();
      }

      // 如果最终无法解析出有效的userId，则保存失败
      if (userIdToSave == null) {
        print('Failed to find or parse a valid user ID from backend data.');
        return false;
      }
      // --- END OF MODIFICATION ---

      // 保存用户基本信息
      await prefs.setInt(_keyUserId, userIdToSave); // 使用解析后的安全值

      // 对 username 也做类似的安全处理
      await prefs.setString(_keyUserName, userData['userName'] ?? userData['username'] ?? '');

      await prefs.setString(_keyEmail, userData['email'] ?? '');
      await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());
      await prefs.setBool(_keyIsLoggedIn, true);

      // 在这里加一个打印，确认保存成功
      print('User info saved successfully. UserID: $userIdToSave');

      return true;
    } catch (e) {
      print('Error saving user info: $e');
      return false;
    }
  }

  /// 获取当前登录用户ID
  Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (!isLoggedIn) return null;
      
      final userId = prefs.getInt(_keyUserId);
      return userId != 0 ? userId : null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  /// 获取完整用户信息
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (!isLoggedIn) return null;
      
      // 安全地获取用户ID，确保类型一致性
      final userId = prefs.getInt(_keyUserId);
      
      if (userId == null || userId <= 0) {
        print('⚠️ Invalid user ID found in preferences: $userId');
        return null;
      }
      
      return {
        'user_id': userId,
        'username': prefs.getString(_keyUserName) ?? '',
        'email': prefs.getString(_keyEmail) ?? '',
        'login_time': prefs.getString(_keyLoginTime) ?? '',
      };
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  /// 检查用户是否已登录
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userId = prefs.getInt(_keyUserId) ?? 0;
      
      // 检查登录状态和用户ID是否有效
      return isLoggedIn && userId > 0;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// 获取用户名
  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (!isLoggedIn) return null;
      
      return prefs.getString(_keyUserName);
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  /// 用户登出，清除所有用户数据
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 清除所有用户相关数据
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyLoginTime);
      await prefs.setBool(_keyIsLoggedIn, false);
      
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  /// 清除所有用户数据（用于数据重置）
  Future<bool> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      print('Error clearing all user data: $e');
      return false;
    }
  }

  /// 验证用户数据完整性
  Future<bool> validateUserData() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;
      
      final userId = user['user_id'] as int?;
      final username = user['username'] as String?;
      
      // 基本验证：用户ID存在且大于0，用户名不为空
      return userId != null && userId > 0 && username != null && username.isNotEmpty;
    } catch (e) {
      print('Error validating user data: $e');
      return false;
    }
  }
}