import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/product_analysis.dart';
import 'performance_monitor.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // 缓存键前缀
  static const String _productPrefix = 'product_';
  static const String _userPrefix = 'user_';
  static const String _allergenPrefix = 'allergen_';
  static const String _profilePrefix = 'profile_';
  static const String _metadataPrefix = 'meta_';

  // 缓存过期时间（小时）
  static const int _productCacheHours = 24;      // 产品信息缓存24小时
  static const int _userCacheHours = 1;          // 用户信息缓存1小时
  static const int _allergenCacheHours = 168;    // 过敏原信息缓存7天
  static const int _profileCacheHours = 6;       // 个人资料缓存6小时

  /// 初始化缓存服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      print('✅ Cache service initialized');
      
      // 首先清理所有无效类型的缓存键（修复类型错误）
      await cleanupInvalidKeys();
      
      // 然后清理过期缓存
      await _cleanExpiredCache();
      
      print('✅ Cache service fully initialized and cleaned');
    } catch (e) {
      print('❌ Failed to initialize cache service: $e');
      // 如果初始化失败，尝试清除所有缓存重新开始
      try {
        if (_prefs != null) {
          await _prefs!.clear();
          print('🔄 Cleared all cache due to initialization failure');
        }
      } catch (clearError) {
        print('❌ Failed to clear cache after initialization failure: $clearError');
      }
    }
  }

  /// 确保缓存服务已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// 缓存产品信息
  Future<bool> cacheProduct(String barcode, ProductAnalysis product) async {
    final monitor = PerformanceMonitor();
    monitor.startTimer('cache_product');

    try {
      await _ensureInitialized();
      if (_prefs == null) return false;

      final key = '$_productPrefix$barcode';
      final data = {
        'product': _productToJson(product),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(Duration(hours: _productCacheHours)).millisecondsSinceEpoch,
      };

      final success = await _prefs!.setString(key, jsonEncode(data));
      
      final duration = monitor.endTimer('cache_product');
      
      if (success) {
        print('✅ Product cached: $barcode (${duration.inMilliseconds}ms)');
      } else {
        print('❌ Failed to cache product: $barcode');
      }

      return success;
    } catch (e) {
      print('❌ Error caching product: $e');
      monitor.endTimer('cache_product');
      return false;
    }
  }

  /// 获取缓存的产品信息
  Future<ProductAnalysis?> getCachedProduct(String barcode) async {
    final monitor = PerformanceMonitor();
    monitor.startTimer('get_cached_product');

    try {
      await _ensureInitialized();
      if (_prefs == null) return null;

      final key = '$_productPrefix$barcode';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) {
        monitor.endTimer('get_cached_product');
        return null;
      }

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final expiresAt = _safeGetInt(data['expiresAt']);
      
      // 检查是否过期
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _prefs!.remove(key);
        monitor.endTimer('get_cached_product');
        print('🗑️ Expired product cache removed: $barcode');
        return null;
      }

      final productData = data['product'] as Map<String, dynamic>;
      final product = _productFromJson(productData);
      
      final duration = monitor.endTimer('get_cached_product');
      print('📦 Product cache hit: $barcode (${duration.inMilliseconds}ms)');
      
      return product;
    } catch (e) {
      print('❌ Error getting cached product: $e');
      monitor.endTimer('get_cached_product');
      return null;
    }
  }

  /// 缓存用户信息
  Future<bool> cacheUserProfile(int userId, Map<String, dynamic> userData) async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return false;

      final key = '$_userPrefix$userId';
      final data = {
        'userData': userData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(Duration(hours: _userCacheHours)).millisecondsSinceEpoch,
      };

      final success = await _prefs!.setString(key, jsonEncode(data));
      
      if (success) {
        print('✅ User profile cached: $userId');
      }

      return success;
    } catch (e) {
      print('❌ Error caching user profile: $e');
      return false;
    }
  }

  /// 获取缓存的用户信息
  Future<Map<String, dynamic>?> getCachedUserProfile(int userId) async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return null;

      final key = '$_userPrefix$userId';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return null;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final expiresAt = _safeGetInt(data['expiresAt']);
      
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _prefs!.remove(key);
        print('🗑️ Expired user cache removed: $userId');
        return null;
      }

      print('👤 User profile cache hit: $userId');
      return data['userData'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting cached user profile: $e');
      return null;
    }
  }

  /// 清除指定用户的缓存信息
  Future<void> clearUserProfileCache(int userId) async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return;

      final userKey = '$_userPrefix$userId';
      final allergenKey = '$_allergenPrefix$userId';
      
      await _prefs!.remove(userKey);
      await _prefs!.remove(allergenKey);
      
      print('🗑️ User cache cleared: $userId');
    } catch (e) {
      print('❌ Error clearing user cache: $e');
    }
  }

  /// 缓存过敏原列表
  Future<bool> cacheAllergens(List<Map<String, dynamic>> allergens) async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return false;

      const key = '${_allergenPrefix}all';
      final data = {
        'allergens': allergens,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(Duration(hours: _allergenCacheHours)).millisecondsSinceEpoch,
      };

      final success = await _prefs!.setString(key, jsonEncode(data));
      
      if (success) {
        print('✅ Allergens cached: ${allergens.length} items');
      }

      return success;
    } catch (e) {
      print('❌ Error caching allergens: $e');
      return false;
    }
  }

  /// 获取缓存的过敏原列表
  Future<List<Map<String, dynamic>>?> getCachedAllergens() async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return null;

      const key = '${_allergenPrefix}all';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return null;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final expiresAt = _safeGetInt(data['expiresAt']);
      
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _prefs!.remove(key);
        print('🗑️ Expired allergens cache removed');
        return null;
      }

      final allergens = (data['allergens'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      print('🥜 Allergens cache hit: ${allergens.length} items');
      return allergens;
    } catch (e) {
      print('❌ Error getting cached allergens: $e');
      return null;
    }
  }

  /// 缓存用户过敏原
  Future<bool> cacheUserAllergens(int userId, List<Map<String, dynamic>> allergens) async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return false;

      final key = '$_allergenPrefix$userId';
      final data = {
        'allergens': allergens,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(Duration(hours: _profileCacheHours)).millisecondsSinceEpoch,
      };

      final success = await _prefs!.setString(key, jsonEncode(data));
      
      if (success) {
        print('✅ User allergens cached: $userId (${allergens.length} items)');
      }

      return success;
    } catch (e) {
      print('❌ Error caching user allergens: $e');
      return false;
    }
  }

  /// 获取缓存的用户过敏原
  Future<List<Map<String, dynamic>>?> getCachedUserAllergens(int userId) async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return null;

      final key = '$_allergenPrefix$userId';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return null;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final expiresAt = _safeGetInt(data['expiresAt']);
      
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _prefs!.remove(key);
        print('🗑️ Expired user allergens cache removed: $userId');
        return null;
      }

      final allergens = (data['allergens'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      print('🥜 User allergens cache hit: $userId (${allergens.length} items)');
      return allergens;
    } catch (e) {
      print('❌ Error getting cached user allergens: $e');
      return null;
    }
  }

  /// 检查产品是否在缓存中
  Future<bool> hasValidProductCache(String barcode) async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return false;

      final key = '$_productPrefix$barcode';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return false;

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final expiresAt = _safeGetInt(data['expiresAt']);
      
      return DateTime.now().millisecondsSinceEpoch <= expiresAt;
    } catch (e) {
      return false;
    }
  }

  /// 清理过期缓存
  Future<void> _cleanExpiredCache() async {
    try {
      if (_prefs == null) return;

      final keys = _prefs!.getKeys().toList();
      final now = DateTime.now().millisecondsSinceEpoch;
      int removedCount = 0;

      for (final key in keys) {
        // Ensure key is a String and check if it's one of our cache prefixes
        if (key is String && 
            (key.startsWith(_productPrefix) || 
             key.startsWith(_userPrefix) || 
             key.startsWith(_allergenPrefix) ||
             key.startsWith(_profilePrefix))) {
          
          try {
            final cachedData = _prefs!.getString(key);
            if (cachedData != null && cachedData.isNotEmpty) {
              try {
                final data = jsonDecode(cachedData) as Map<String, dynamic>;
                final expiresAtValue = data['expiresAt'];
                
                // Safely check if expiresAt exists and is a valid timestamp
                if (expiresAtValue != null) {
                  final expiresAt = _safeGetInt(expiresAtValue);
                  
                  if (expiresAt > 0 && now > expiresAt) {
                    await _prefs!.remove(key);
                    removedCount++;
                    print('🗑️ Removed expired cache: $key');
                  }
                }
              } catch (parseError) {
                // If JSON parsing fails, the cached data is corrupted - remove it
                print('⚠️ Corrupted cache data found for key: $key, removing...');
                await _prefs!.remove(key);
                removedCount++;
              }
            } else {
              // Empty cache entry - remove it
              await _prefs!.remove(key);
              removedCount++;
            }
          } catch (keyError) {
            print('❌ Error processing cache key $key: $keyError');
            // Try to remove problematic key
            try {
              await _prefs!.remove(key);
              removedCount++;
            } catch (removeError) {
              print('❌ Failed to remove problematic key $key: $removeError');
            }
          }
        }
      }

      if (removedCount > 0) {
        print('🗑️ Cleaned $removedCount expired cache entries');
      }
    } catch (e) {
      print('❌ Error cleaning expired cache: $e');
      // If cache cleanup fails completely, try to reinitialize the cache service
      try {
        _initialized = false;
        await initialize();
      } catch (reinitError) {
        print('❌ Failed to reinitialize cache service: $reinitError');
      }
    }
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return;

      final keys = _prefs!.getKeys().toList();
      int removedCount = 0;

      for (final key in keys) {
        // 确保key是String类型并且匹配我们的缓存前缀
        if (key is String && 
            (key.startsWith(_productPrefix) || 
             key.startsWith(_userPrefix) || 
             key.startsWith(_allergenPrefix) ||
             key.startsWith(_profilePrefix))) {
          try {
            await _prefs!.remove(key);
            removedCount++;
          } catch (removeError) {
            print('❌ Failed to remove cache key $key: $removeError');
          }
        } else if (key is! String) {
          // 记录非字符串类型的key，这可能是问题的来源
          print('⚠️ Found non-string cache key: $key (type: ${key.runtimeType})');
          try {
            await _prefs!.remove(key);
            removedCount++;
            print('🗑️ Removed problematic non-string key: $key');
          } catch (removeError) {
            print('❌ Failed to remove non-string key $key: $removeError');
          }
        }
      }

      print('🗑️ Cleared all cache: $removedCount entries removed');
    } catch (e) {
      print('❌ Error clearing cache: $e');
      // 如果清理失败，尝试重新初始化缓存服务
      try {
        _initialized = false;
        await initialize();
      } catch (reinitError) {
        print('❌ Failed to reinitialize cache service after clearAllCache error: $reinitError');
      }
    }
  }

  /// 获取缓存统计信息
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      await _ensureInitialized();
      if (_prefs == null) {
        return CacheStatistics(
          totalEntries: 0,
          productEntries: 0,
          userEntries: 0,
          allergenEntries: 0,
          totalSizeKB: 0,
        );
      }

      final keys = _prefs!.getKeys().toList();
      int productCount = 0;
      int userCount = 0;
      int allergenCount = 0;
      int totalSize = 0;

      for (final key in keys) {
        // 确保key是String类型
        if (key is String) {
          if (key.startsWith(_productPrefix)) {
            productCount++;
          } else if (key.startsWith(_userPrefix)) {
            userCount++;
          } else if (key.startsWith(_allergenPrefix)) {
            allergenCount++;
          }

          final data = _prefs!.getString(key);
          if (data != null) {
            totalSize += data.length;
          }
        } else {
          // 记录非字符串类型的key
          print('⚠️ Found non-string key in cache statistics: $key (type: ${key.runtimeType})');
        }
      }

      return CacheStatistics(
        totalEntries: productCount + userCount + allergenCount,
        productEntries: productCount,
        userEntries: userCount,
        allergenEntries: allergenCount,
        totalSizeKB: (totalSize / 1024).round(),
      );
    } catch (e) {
      print('❌ Error getting cache statistics: $e');
      return CacheStatistics(
        totalEntries: 0,
        productEntries: 0,
        userEntries: 0,
        allergenEntries: 0,
        totalSizeKB: 0,
      );
    }
  }

  /// 产品分析对象转JSON
  Map<String, dynamic> _productToJson(ProductAnalysis product) {
    return {
      'name': product.name,
      'imageUrl': product.imageUrl,
      'ingredients': product.ingredients,
      'detectedAllergens': product.detectedAllergens,
      'summary': product.summary,
      'detailedAnalysis': product.detailedAnalysis,
      'actionSuggestions': product.actionSuggestions,
      'barcode': product.barcode, // 包含条码信息
      'recommendations': product.recommendations.map((rec) => {
        'name': rec.name,
        'imageUrl': rec.imageUrl,
        'summary': rec.summary,
        'detailedAnalysis': rec.detailedAnalysis,
        'barcode': rec.barcode, // 推荐产品的条码信息
      }).toList(),
    };
  }

  /// JSON转产品分析对象
  ProductAnalysis _productFromJson(Map<String, dynamic> json) {
    // 解析推荐产品列表
    List<ProductAnalysis> recommendations = [];
    if (json['recommendations'] != null) {
      final recsData = json['recommendations'] as List;
      for (final recData in recsData) {
        recommendations.add(ProductAnalysis(
          name: recData['name'] ?? '',
          imageUrl: recData['imageUrl'] ?? '',
          ingredients: [],
          detectedAllergens: [],
          summary: recData['summary'] ?? '',
          detailedAnalysis: recData['detailedAnalysis'] ?? '',
          actionSuggestions: [],
          barcode: recData['barcode'], // 恢复推荐产品的条码信息
        ));
      }
    }

    return ProductAnalysis(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      detectedAllergens: List<String>.from(json['detectedAllergens'] ?? []),
      summary: json['summary'] ?? '',
      detailedAnalysis: json['detailedAnalysis'] ?? '',
      actionSuggestions: List<String>.from(json['actionSuggestions'] ?? []),
      recommendations: recommendations,
      barcode: json['barcode'], // 恢复主产品的条码信息
    );
  }

  /// 清理所有非字符串类型的缓存键 (修复类型错误的专用方法)
  Future<void> cleanupInvalidKeys() async {
    try {
      await _ensureInitialized();
      if (_prefs == null) return;

      final keys = _prefs!.getKeys().toList();
      int removedCount = 0;

      for (final key in keys) {
        if (key is! String) {
          print('🔧 Found and removing invalid key type: $key (type: ${key.runtimeType})');
          try {
            await _prefs!.remove(key);
            removedCount++;
          } catch (e) {
            print('❌ Failed to remove invalid key $key: $e');
          }
        }
      }

      if (removedCount > 0) {
        print('✅ Cleaned up $removedCount invalid cache keys');
      } else {
        print('✅ No invalid cache keys found');
      }
    } catch (e) {
      print('❌ Error during invalid key cleanup: $e');
    }
  }

  /// 安全地获取int值，处理类型转换错误
  int _safeGetInt(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        if (value.isEmpty) return 0;
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      
      // Log unexpected types for debugging
      print('⚠️ Unexpected type in _safeGetInt: ${value.runtimeType} with value: $value');
      return 0; // 默认值
    } catch (e) {
      print('❌ Error in _safeGetInt for value $value: $e');
      return 0;
    }
  }
}

/// 缓存统计信息
class CacheStatistics {
  final int totalEntries;
  final int productEntries;
  final int userEntries;
  final int allergenEntries;
  final int totalSizeKB;

  CacheStatistics({
    required this.totalEntries,
    required this.productEntries,
    required this.userEntries,
    required this.allergenEntries,
    required this.totalSizeKB,
  });

  @override
  String toString() {
    return 'CacheStatistics(total: $totalEntries, products: $productEntries, '
           'users: $userEntries, allergens: $allergenEntries, size: ${totalSizeKB}KB)';
  }
}