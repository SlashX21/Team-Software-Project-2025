import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 缓存修复助手类
/// 专门处理缓存中的类型错误和损坏数据
class CacheFixHelper {
  static final CacheFixHelper _instance = CacheFixHelper._internal();
  factory CacheFixHelper() => _instance;
  CacheFixHelper._internal();

  /// 修复用户ID类型错误
  /// 处理 user_id 在整数和字符串之间转换的问题
  static Future<void> fixUserIdTypeError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查是否存在整数类型的 user_id
      final intUserId = prefs.getInt('user_id');
      if (intUserId != null && intUserId > 0) {
        // 将整数转换为字符串存储
        await prefs.setString('user_id', intUserId.toString());
        print('🔧 Fixed user_id type: $intUserId -> "${intUserId.toString()}"');
        return;
      }
      
      // 检查是否存在字符串类型的 user_id
      final stringUserId = prefs.getString('user_id');
      if (stringUserId != null && stringUserId.isNotEmpty) {
        final parsedUserId = int.tryParse(stringUserId);
        if (parsedUserId != null && parsedUserId > 0) {
          // 将字符串转换为整数存储
          await prefs.setInt('user_id', parsedUserId);
          print('🔧 Fixed user_id type: "$stringUserId" -> $parsedUserId');
          return;
        }
      }
      
      print('✅ No user_id type errors found');
    } catch (e) {
      print('❌ Error fixing user_id type: $e');
    }
  }

  /// 修复所有已知的缓存类型错误
  static Future<void> fixAllTypeErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      int fixedCount = 0;

      for (final key in keys) {
        if (key is! String) {
          print('🔧 Found non-string key: $key (type: ${key.runtimeType})');
          try {
            final value = prefs.get(key);
            if (value != null) {
              await prefs.setString(key.toString(), value.toString());
              await prefs.remove(key);
              fixedCount++;
              print('🔧 Fixed non-string key: $key');
            }
          } catch (e) {
            print('❌ Failed to fix non-string key $key: $e');
          }
        }
      }

      // 特别处理用户相关的键
      await fixUserIdTypeError();
      
      if (fixedCount > 0) {
        print('✅ Fixed $fixedCount type errors');
      } else {
        print('✅ No type errors found');
      }
    } catch (e) {
      print('❌ Error fixing type errors: $e');
    }
  }

  /// 清理损坏的缓存数据
  static Future<void> cleanCorruptedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      int removedCount = 0;

      for (final key in keys) {
        if (key is String) {
          try {
            final value = prefs.getString(key);
            if (value != null && value.isNotEmpty) {
              // 尝试解析JSON数据，如果失败则认为是损坏的
              try {
                if (value.startsWith('{') || value.startsWith('[')) {
                  // 尝试解析JSON
                  final decoded = jsonDecode(value);
                  // 如果解析成功，检查是否有必要的字段
                  if (decoded is Map<String, dynamic>) {
                    if (!decoded.containsKey('timestamp') && !decoded.containsKey('expiresAt')) {
                      // 可能是损坏的缓存数据
                      await prefs.remove(key);
                      removedCount++;
                      print('🗑️ Removed corrupted cache: $key');
                    }
                  }
                }
              } catch (jsonError) {
                // JSON解析失败，删除损坏的数据
                await prefs.remove(key);
                removedCount++;
                print('🗑️ Removed corrupted JSON cache: $key');
              }
            }
          } catch (e) {
            // 获取数据失败，删除有问题的键
            await prefs.remove(key);
            removedCount++;
            print('🗑️ Removed problematic cache key: $key');
          }
        }
      }

      if (removedCount > 0) {
        print('✅ Cleaned $removedCount corrupted cache entries');
      } else {
        print('✅ No corrupted cache found');
      }
    } catch (e) {
      print('❌ Error cleaning corrupted cache: $e');
    }
  }

  /// 验证缓存数据完整性
  static Future<bool> validateCacheIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      int errorCount = 0;

      for (final key in keys) {
        if (key is! String) {
          print('⚠️ Found non-string key: $key');
          errorCount++;
          continue;
        }

        try {
          final value = prefs.getString(key);
          if (value != null && value.isNotEmpty) {
            // 检查JSON格式的缓存数据
            if (value.startsWith('{') || value.startsWith('[')) {
              try {
                jsonDecode(value);
              } catch (e) {
                print('⚠️ Corrupted JSON in cache key: $key');
                errorCount++;
              }
            }
          }
        } catch (e) {
          print('⚠️ Error accessing cache key: $key');
          errorCount++;
        }
      }

      if (errorCount > 0) {
        print('❌ Found $errorCount cache integrity issues');
        return false;
      } else {
        print('✅ Cache integrity validation passed');
        return true;
      }
    } catch (e) {
      print('❌ Error validating cache integrity: $e');
      return false;
    }
  }

  /// 完整的缓存修复流程
  static Future<void> performFullCacheFix() async {
    print('🔧 Starting full cache fix process...');
    
    // 1. 验证缓存完整性
    final isValid = await validateCacheIntegrity();
    
    // 2. 修复类型错误
    await fixAllTypeErrors();
    
    // 3. 清理损坏的缓存
    await cleanCorruptedCache();
    
    // 4. 再次验证
    final finalValidation = await validateCacheIntegrity();
    
    if (finalValidation) {
      print('✅ Full cache fix completed successfully');
    } else {
      print('⚠️ Cache fix completed with remaining issues');
    }
  }
} 