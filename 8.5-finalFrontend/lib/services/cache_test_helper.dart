import 'package:shared_preferences/shared_preferences.dart';
import 'cache_fix_helper.dart';

/// 缓存测试助手
/// 用于测试缓存修复功能
class CacheTestHelper {
  /// 模拟创建类型错误的缓存数据
  static Future<void> createTestTypeErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 创建一些测试数据
      await prefs.setInt('user_id', 1001); // 整数类型的user_id
      await prefs.setString('user_name', 'test_user');
      await prefs.setString('corrupted_json', '{invalid json}');
      
      print('🧪 Created test type errors');
    } catch (e) {
      print('❌ Error creating test data: $e');
    }
  }

  /// 验证修复结果
  static Future<void> verifyFixResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查user_id是否被正确修复
      final userId = prefs.getInt('user_id');
      final userIdString = prefs.getString('user_id');
      
      print('🔍 Verification results:');
      print('   user_id (int): $userId');
      print('   user_id (string): $userIdString');
      
      if (userId == 1001 || userIdString == '1001') {
        print('✅ user_id type error fixed successfully');
      } else {
        print('❌ user_id type error not fixed');
      }
      
      // 检查损坏的JSON是否被清理
      final corruptedJson = prefs.getString('corrupted_json');
      if (corruptedJson == null) {
        print('✅ Corrupted JSON cleaned successfully');
      } else {
        print('❌ Corrupted JSON not cleaned');
      }
      
    } catch (e) {
      print('❌ Error verifying fix results: $e');
    }
  }

  /// 运行完整的测试流程
  static Future<void> runFullTest() async {
    print('🧪 Starting cache fix test...');
    
    // 1. 创建测试数据
    await createTestTypeErrors();
    
    // 2. 运行修复流程
    await CacheFixHelper.performFullCacheFix();
    
    // 3. 验证结果
    await verifyFixResults();
    
    print('🧪 Cache fix test completed');
  }
} 