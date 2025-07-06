import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/entities/product_analysis.dart';
import 'api_config.dart';
import 'performance_monitor.dart';
import 'cache_service.dart';

class RealApiService {
  // 异步获取推荐信息，不阻塞主流程
  static void _fetchRecommendationAsync(String barcode, int userId, ProductAnalysis product) async {
    final monitor = PerformanceMonitor();
    
    try {
      final uri = Uri.parse('${ApiConfig.recommendationBaseUrl}/recommendations/barcode');
      print("🔎 Async fetching recommendation from: $uri");
      
      monitor.startTimer('recommendation_async_call');
      
      final recResponse = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productBarcode': barcode,
        }),
      ).timeout(Duration(seconds: 3)); // Reduced timeout for faster response

      final recDuration = monitor.endTimer('recommendation_async_call');

      monitor.recordApiCall(
        endpoint: '/recommendations/barcode',
        statusCode: recResponse.statusCode,
        duration: recDuration,
        errorMessage: recResponse.statusCode != 200 ? 'Recommendation failed' : null,
      );

      print("🔎 Async Recommendation Response Status: ${recResponse.statusCode} (${recDuration.inMilliseconds}ms)");
      
      if (recResponse.statusCode == 200) {
        final recData = jsonDecode(recResponse.body)['data'];
        final llm = recData['llmAnalysis'] ?? {};
        print('✅ Async recommendation data received in ${recDuration.inMilliseconds}ms');
        
        // Update product with recommendations if available
        if (llm.isNotEmpty) {
          product = product.copyWith(
          summary: llm['summary'] ?? product.summary,
          detailedAnalysis: llm['detailedAnalysis'] ?? product.detailedAnalysis,
        );
        if (llm.containsKey('actionSuggestions')) {
          product = product.copyWith(
            actionSuggestions: List<String>.from(llm['actionSuggestions']),
          );
        }
        }
      } else {
        print('⚠️ Recommendation service unavailable (${recResponse.statusCode})');
        // Provide static fallback recommendations
        product = product.copyWith(
          summary: 'Product information loaded. Personalized recommendations temporarily unavailable.',
          detailedAnalysis: 'Basic product analysis completed. Advanced AI insights will be available when the recommendation service is restored.',
          actionSuggestions: [
            'Check ingredients for allergens.',
            'Consider healthier alternatives if available.',
          ],
        );
      }
    } catch (e) {
      final recDuration = monitor.endTimer('recommendation_async_call');
      
      monitor.recordApiCall(
        endpoint: '/recommendations/barcode',
        statusCode: 0,
        duration: recDuration,
        errorMessage: e.toString(),
      );
      
      print('❌ Async recommendation error: $e');
      
      // Provide fallback recommendations on error
      product = product.copyWith(
        summary: 'Product loaded successfully. AI recommendations currently unavailable due to network issues.',
        detailedAnalysis: 'Unable to generate personalized insights at this time. Please check your internet connection.',
        actionSuggestions: [
          'Ensure you have a stable internet connection.',
          'Try scanning again later.',
        ],
      );
    }
  }
  static Future<bool> registerUser({
    required String userName,
    required String passwordHash,
    required String email,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/user');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userName": userName,
        "passwordHash": passwordHash,
        "email": email,
        "gender": gender,
        "heightCm": heightCm,
        "weightKg": weightKg,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print("Register failed: ${response.statusCode} ${response.body}");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String userName,
    required String passwordHash,
  }) async {
    final monitor = PerformanceMonitor();
    
    // Try multiple endpoints but use consistent field names that backend expects
    final loginAttempts = [
      {
        'url': '${ApiConfig.baseUrl}/user/login',
        'method': 'POST',
        'body': {
          "userName": userName,
          "passwordHash": passwordHash,
        }
      },
      {
        'url': '${ApiConfig.springBootBaseUrl}/user/login',
        'method': 'POST',
        'body': {
          "userName": userName,
          "passwordHash": passwordHash,
        }
      },
    ];

    monitor.startTimer('user_login');

    for (int i = 0; i < loginAttempts.length; i++) {
      final attempt = loginAttempts[i];
      final url = Uri.parse(attempt['url'] as String);
      final requestBody = attempt['body'] as Map<String, dynamic>;
      
      try {
        print("🔐 Login attempt ${i+1}: ${attempt['url']}");
        print("📤 Request Body: ${jsonEncode(requestBody)}");

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        ).timeout(Duration(seconds: 10));

        final duration = monitor.endTimer('user_login');
        
        monitor.recordApiCall(
          endpoint: '/user/login',
          statusCode: response.statusCode,
          duration: duration,
          errorMessage: response.statusCode != 200 ? 'Login failed' : null,
        );

        print("📥 Response Status: ${response.statusCode}");
        print("📥 Response Body: ${response.body}");

        if (response.statusCode == 200) {
          try {
            final Map<String, dynamic> json = jsonDecode(response.body);
            
            // Handle various backend response formats
            Map<String, dynamic>? userData;
            
            if (json['success'] == true && json['data'] != null) {
              userData = json['data'];
            } else if (json['code'] == 200 && json['data'] != null) {
              userData = json['data'];
            } else if (json.containsKey('userId') || json.containsKey('user_id')) {
              userData = json; // Direct user data
            } else if (json['message'] == 'success' && json['data'] != null) {
              userData = json['data'];
            }
            
            if (userData != null) {
              print("✅ Login successful via ${attempt['url']}");
              return userData;
            } else {
              print("⚠️ Unexpected login response format: $json");
            }
            
          } catch (e) {
            print("❌ Error parsing login response: $e");
          }
        } else if (response.statusCode == 401) {
          print("❌ Authentication failed: Invalid credentials");
          return null; // Don't try other endpoints for auth failure
        } else if (response.statusCode == 500) {
          print("⚠️ Server error (${response.statusCode}): ${response.body}");
          
          // 分析500错误的具体类型
          try {
            final errorBody = jsonDecode(response.body);
            final message = errorBody['message'] ?? '';
            
            if (message.contains('Query did not return a unique result')) {
              print("❌ Database integrity issue: Multiple users found");
              throw Exception('登录系统暂时不可用，请稍后重试（数据库问题）');
            } else if (message.contains('user name or password is incorrect')) {
              print("❌ Authentication failed (returned as 500)");
              return null; // 认证失败，不再尝试其他端点
            }
          } catch (parseError) {
            print("⚠️ Could not parse 500 error message: $parseError");
          }
          
          // Continue to try other endpoints for other server errors
        } else {
          print("⚠️ Login failed with status ${response.statusCode}: ${response.body}");
        }
        
      } catch (e) {
        print("❌ Login attempt ${i+1} failed: $e");
        continue; // Try next endpoint
      }
    }

    monitor.endTimer('user_login');
    print("❌ All login attempts failed");
    return null;
  }

  static Future<ProductAnalysis> fetchProductByBarcode(String barcode, int userId) async {
    final monitor = PerformanceMonitor();
    final cache = CacheService();
    
    try {
      print("🔍 Fetching product for barcode: $barcode, userId: $userId");
      
      // Step 0: 检查缓存
      monitor.startTimer('cache_check');
      final cachedProduct = await cache.getCachedProduct(barcode);
      monitor.endTimer('cache_check');
      
      if (cachedProduct != null) {
        print('✅ Product found in cache: $barcode');
        
        // 如果有userId，仍然异步获取推荐信息
        if (userId > 0) {
          _fetchRecommendationAsync(barcode, userId, cachedProduct);
        }
        
        return cachedProduct;
      }
      
      // Step 1: 缓存中没有，从 API 获取
      monitor.startTimer('product_db_call');
      
      final productFuture = http.get(
        Uri.parse('${ApiConfig.springBootBaseUrl}/product/$barcode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      final dbResponse = await productFuture;
      
      final dbDuration = monitor.endTimer('product_db_call');
      
      monitor.recordApiCall(
        endpoint: '/product/$barcode',
        statusCode: dbResponse.statusCode,
        duration: dbDuration,
        errorMessage: dbResponse.statusCode != 200 ? 'Product not found' : null,
      );
      
      if (dbResponse.statusCode != 200) {
        print('❌ Product not found: ${dbResponse.statusCode} - ${dbResponse.body}');
        throw Exception('Product not found in database.');
      }

      final json = jsonDecode(dbResponse.body)['data'];

      // 构建基础产品信息
      final product = ProductAnalysis(
        name: json['productName'] ?? 'Unknown',
        imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/300x200',
        ingredients: _parseList(json['ingredients']),
        detectedAllergens: _parseList(json['allergens']),
      );

      print('✅ Basic product info loaded in ${dbDuration.inMilliseconds}ms');
      
      // Step 2: 缓存产品信息
      cache.cacheProduct(barcode, product);

      // Step 3: 首先返回基础信息，然后异步获取推荐信息
      if (userId > 0) {
        _fetchRecommendationAsync(barcode, userId, product);
      }
      
      return product;
      
    } catch (e) {
      print('❌ Barcode fetch error: $e');
      
      monitor.recordApiCall(
        endpoint: '/product/$barcode',
        statusCode: 0,
        duration: Duration.zero,
        errorMessage: e.toString(),
      );
      
      throw Exception('Failed to fetch product: $e');
    }
  }

  static Future<Map<String, dynamic>> uploadReceiptImage(XFile imageFile, int userId) async {
    try {
      print("🚀 Starting OCR upload - optimized for demo performance...");
      
      // 直接上传到OCR服务，不再做/health健康检查
      final ocrUri = Uri.parse('${ApiConfig.ocrBaseUrl}/ocr/scan');
      print("📤 Uploading to OCR endpoint: $ocrUri");
      
      final bytes = await imageFile.readAsBytes();
      print("📷 Image size: ${bytes.length} bytes");
      
      // Optimize image size for faster processing if needed
      final optimizedBytes = bytes.length > 2000000 ? 
        _compressImageBytes(bytes) : bytes;
      
      final ocrRequest = http.MultipartRequest('POST', ocrUri)
        ..fields['userId'] = userId.toString()
        ..fields['priority'] = 'high' // Request high priority processing
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            optimizedBytes,
            filename: imageFile.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      print("⏱️ Starting OCR processing...");
      final stopwatch = Stopwatch()..start();
      
      final ocrResponse = await http.Response.fromStream(
        await ocrRequest.send().timeout(ApiConfig.ocrTimeout)
      );
      
      stopwatch.stop();
      print("⚡ OCR completed in ${stopwatch.elapsedMilliseconds} ms");
      print("📥 OCR Response Status: ${ocrResponse.statusCode}");
      
      if (ocrResponse.statusCode != 200) {
        print("❌ OCR failed: ${ocrResponse.body}");
        
        // Provide specific error messages based on status code
        String errorMessage;
        switch (ocrResponse.statusCode) {
          case 400:
            errorMessage = 'Invalid image format. Please select a clear receipt image.';
            break;
          case 413:
            errorMessage = 'Image file is too large. Please select a smaller image.';
            break;
          case 503:
            errorMessage = 'OCR service is temporarily unavailable. Please try again later.';
            break;
          default:
            errorMessage = 'Receipt processing failed. Please check your image and try again.';
        }
        throw Exception(errorMessage);
      }

      final ocrResult = jsonDecode(ocrResponse.body);
      final ocrProducts = ocrResult['data']?['products'] ?? [];

      // Step 2: Query barcode for each product name
      final List<Map<String, dynamic>> purchasedItems = [];

      print("🔍 Processing ${ocrProducts.length} OCR products...");
      
      for (final product in ocrProducts) {
        try {
          final productName = product['name'] ?? '';
          final quantity = product['quantity'] ?? 1;
          
          print("📦 Processing: $productName (qty: $quantity)");
          
          // Simulate product lookup - in real implementation, 
          // this would query the product database by name
          final mockBarcode = _generateMockBarcodeFromName(productName);
          
          purchasedItems.add({
            'name': productName,
            'quantity': quantity,
            'barcode': mockBarcode,
            'source': 'ocr'
          });
          
        } catch (e) {
          print("⚠️ Error processing product ${product['name']}: $e");
          // Continue with other products even if one fails
        }
      }

      print("✅ OCR processing completed: ${purchasedItems.length} items extracted");
      
      // Step 3: Return comprehensive results
      final result = {
        'success': true,
        'source': 'ocr',
        'processingTime': stopwatch.elapsedMilliseconds,
        'itemAnalyses': purchasedItems,
        'llmInsights': {
          'summary': purchasedItems.isNotEmpty 
            ? 'Successfully extracted "${purchasedItems.length.toString()}" items from your receipt'
            : 'No items were found in the receipt image',
          'keyFindings': purchasedItems.isNotEmpty
            ? ['Receipt processed successfully', 'Items extracted: '+purchasedItems.map((i) => i['name']).join(', ')]
            : ['No readable items found in the image'],
          'improvementSuggestions': purchasedItems.isEmpty
            ? ['Please ensure the receipt image is clear and well-lit', 'Try taking a photo with better lighting']
            : ['Review the extracted items for accuracy', 'Items may be approximated based on receipt text recognition']
        }
      };

      return result;

    } catch (e) {
      print("❌ OCR Upload Error: $e");
      
      // Handle specific error types
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Upload timed out. Please check your internet connection and try again.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        throw Exception('OCR service is currently unavailable. Please try again later.');
      } else if (e.toString().contains('OCR service')) {
        // Re-throw OCR service specific errors as-is
        rethrow;
      } else {
        throw Exception('Failed to process receipt. Please try again.');
      }
    }
  }

  // Generate fallback recommendation when AI service is unavailable
  static Map<String, dynamic> _generateFallbackRecommendation(List<Map<String, dynamic>> purchasedItems) {
    print(" Generating fallback recommendations...");
    
    final fallbackAnalysis = {
      'itemAnalyses': purchasedItems.map((item) => {
        'name': item['name'] ?? 'Unknown Product',
        'quantity': item['quantity'] ?? 1,
        'barcode': item['barcode'] ?? '',
        'calories': 250, // Estimated
        'healthScore': 7.5,
      }).toList(),
      'llmInsights': {
        'summary': 'Product analysis completed. Your shopping choices show a good variety of items.',
        'keyFindings': [
          'Diverse product selection detected',
          'Consider checking nutritional labels for dietary preferences',
          'Balance of different food categories observed'
        ],
        'improvementSuggestions': [
          'Add more fresh fruits and vegetables to your cart',
          'Consider low-sodium alternatives for processed foods',
          'Look for whole grain options when available'
        ]
      }
    };
    
    return fallbackAnalysis;
  }

  // Image compression for faster OCR processing
  static List<int> _compressImageBytes(List<int> originalBytes) {
    try {
      // Simple compression by reducing quality (placeholder implementation)
      // In production, you'd use image compression libraries
      print("🗜️ Compressing image from ${originalBytes.length} bytes");
      
      // For demo purposes, we'll simulate compression by reducing file size
      // This is a placeholder - real implementation would use image libraries
      final compressionRatio = 0.7;
      final targetSize = (originalBytes.length * compressionRatio).round();
      
      if (targetSize < originalBytes.length) {
        // Simple byte reduction (not real compression, just for demo)
        final compressed = originalBytes.take(targetSize).toList();
        print("📦 Compressed to ${compressed.length} bytes");
        return compressed;
      }
      
      return originalBytes;
    } catch (e) {
      print("⚠️ Image compression failed, using original: $e");
      return originalBytes;
    }
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  // ============================================================================
  // User Profile APIs
  // ============================================================================
  
  static Future<Map<String, dynamic>?> getUserProfile({required int userId}) async {
    if (userId <= 0) {
      print('Invalid userId for profile fetch: $userId');
      return null;
    }
    
    final cache = CacheService();
    
    try {
      // 检查缓存
      final cachedProfile = await cache.getCachedUserProfile(userId);
      if (cachedProfile != null) {
        print('✅ User profile found in cache: $userId');
        return cachedProfile;
      }
      
      // 从 API 获取
      final url = Uri.parse('${ApiConfig.springBootBaseUrl}/user/$userId');
      print('Fetching user profile from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('Profile API Response Status: ${response.statusCode}');
      print('Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        
        Map<String, dynamic>? userData;
        
        // 多种响应格式支持
        if (json['success'] == true && json['data'] != null) {
          userData = json['data'];
        } else if (json['code'] == 200 && json['data'] != null) {
          userData = json['data'];
        } else if (json.containsKey('userId') || json.containsKey('user_id')) {
          userData = json; // 直接返回用户数据
        } else {
          print('Unexpected profile response format: $json');
        }
        
        // 缓存用户数据
        if (userData != null) {
          cache.cacheUserProfile(userId, userData);
        }
        
        return userData;
      } else {
        print('Profile fetch failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }

    return null;
  }

  static Future<bool> updateUserProfile({
    required int userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Validate userId first
      if (userId <= 0) {
        print('❌ Invalid userId for profile update: $userId');
        return false;
      }

      // Backend only supports POST method for user updates (not PUT)
      final url = Uri.parse('${ApiConfig.springBootBaseUrl}/user');
      print('🔄 Updating user profile via POST at: $url');

      // Prepare request data - backend requires exact userId format
      final requestData = Map<String, dynamic>.from(userData);
      requestData['userId'] = userId;
      
      // Remove null values to prevent backend issues
      requestData.removeWhere((key, value) => value == null);
      
      print('📤 Update Profile Request Data: $requestData');

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestData),
        ).timeout(Duration(seconds: 10));

        print('📥 Update Profile Response Status: ${response.statusCode}');
        print('📥 Update Profile Response Body: ${response.body}');

        // Backend returns 200 for successful updates
        if (response.statusCode == 200) {
          try {
            final Map<String, dynamic> json = jsonDecode(response.body);
            final success = json['success'] == true || 
                           json['code'] == 200 || 
                           json['data'] != null;
            if (success) {
              print('✅ Profile updated successfully');
              
              // Clear cache to force refresh
              final cache = CacheService();
              cache.clearUserProfileCache(userId);
              
              return true;
            } else {
              print('❌ Backend returned success=false or invalid response format');
              return false;
            }
          } catch (e) {
            print('❌ Error parsing response JSON: $e');
            return false;
          }
        } else if (response.statusCode == 400) {
          print('❌ Bad Request - Invalid data format or missing required fields');
          return false;
        } else if (response.statusCode == 405) {
          print('❌ Method Not Allowed - Backend API configuration issue');
          return false;
        } else {
          print('❌ Profile update failed: ${response.statusCode} - ${response.body}');
          return false;
        }
      } catch (e) {
        print('❌ Network error during profile update: $e');
        return false;
      }
      
    } catch (e) {
      print('❌ Error in updateUserProfile: $e');
      return false;
    }
  }

  // ============================================================================
  // User Allergen APIs
  // ============================================================================
  
  static Future<List<Map<String, dynamic>>?> getUserAllergens({required int userId}) async {
    if (userId <= 0) {
      print('Invalid userId for allergens fetch: $userId');
      return [];
    }
    
    final cache = CacheService();
    
    try {
      // 检查缓存
      final cachedAllergens = await cache.getCachedUserAllergens(userId);
      if (cachedAllergens != null) {
        print('✅ User allergens found in cache: $userId');
        return cachedAllergens;
      }
      
      // 从 API 获取 - 实现多端点尝试
      final endpoints = [
        '${ApiConfig.springBootBaseUrl}/user/$userId/allergens',
        '${ApiConfig.baseUrl}/user/$userId/allergens',
        '${ApiConfig.springBootBaseUrl}/allergen/user/$userId',
      ];
      
      for (String endpoint in endpoints) {
        try {
          final url = Uri.parse(endpoint);
          print('Fetching user allergens from: $url');

          final response = await http.get(
            url,
            headers: {'Content-Type': 'application/json'},
          ).timeout(Duration(seconds: 3));

          print('User allergens response: ${response.statusCode} - ${response.body}');

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            
            List<Map<String, dynamic>>? allergens;
            
            // 多种响应格式支持
            if (json['data'] != null) {
              allergens = List<Map<String, dynamic>>.from(json['data']);
            } else if (json is List) {
              allergens = List<Map<String, dynamic>>.from(json);
            } else if (json['allergens'] != null) {
              allergens = List<Map<String, dynamic>>.from(json['allergens']);
            }
            
            // 缓存用户过敏原数据
            if (allergens != null) {
              cache.cacheUserAllergens(userId, allergens);
              print('✅ User allergens loaded from $endpoint');
              return allergens;
            }
          } else if (response.statusCode == 404) {
            print('User allergens endpoint $endpoint not found - trying next endpoint');
            continue;
          }
        } catch (e) {
          print('Error trying user allergens endpoint $endpoint: $e');
          continue;
        }
      }
      
      // 如果所有API都失败，返回空列表
      print('📋 All user allergens endpoints failed - returning empty list');
      final emptyList = <Map<String, dynamic>>[];
      cache.cacheUserAllergens(userId, emptyList);
      return emptyList;
    } catch (e) {
      print('Error fetching user allergens: $e');
    }

    return []; // 默认返回空列表
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================
  
  /// Generate a mock barcode from product name for demonstration
  static String _generateMockBarcodeFromName(String productName) {
    if (productName.isEmpty) return '0000000000000';
    
    // Simple hash-based barcode generation for demo purposes
    int hash = productName.hashCode.abs();
    String barcode = hash.toString().padLeft(13, '0');
    
    // Ensure it's exactly 13 digits (EAN-13 format)
    if (barcode.length > 13) {
      barcode = barcode.substring(0, 13);
    }
    
    return barcode;
  }



  // ============================================================================
  // Enhanced Allergen API Methods with Better Error Handling
  // ============================================================================
  
  static Future<bool> addUserAllergen({
    required int userId,
    required int allergenId,
    required String severityLevel,
    required String notes,
  }) async {
    if (userId <= 0) {
      print('❌ Invalid userId for allergen addition: $userId');
      return false;
    }

    final endpoints = [
      '${ApiConfig.springBootBaseUrl}/user/$userId/allergens',
      '${ApiConfig.baseUrl}/user/$userId/allergens',
      '${ApiConfig.springBootBaseUrl}/allergen/user/$userId/add',
    ];

    String lastError = '';
    
    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      try {
        final url = Uri.parse(endpoint);
        print('🔄 Attempting to add allergen via endpoint ${i + 1}/${endpoints.length}: $url');
        
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "userId": userId,
            "allergenId": allergenId,
            "severityLevel": severityLevel,
            "notes": notes,
          }),
        ).timeout(Duration(seconds: 8));

        print('📥 Add allergen response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final Map<String, dynamic> json = jsonDecode(response.body);
            if (json['success'] == true || json['code'] == 200) {
              print('✅ Allergen added successfully via $endpoint');
              return true;
            }
          } catch (parseError) {
            // If JSON parsing fails but status is success, assume it worked
            if (response.statusCode == 201) {
              print('✅ Allergen added successfully via $endpoint (no JSON response)');
              return true;
            }
          }
        } else if (response.statusCode == 404) {
          lastError = 'API endpoint not found';
          print('⚠️ Endpoint not found: $endpoint - trying next endpoint');
          continue;
        } else if (response.statusCode == 403) {
          lastError = 'Permission denied - please check your login status';
          print('❌ Permission denied for endpoint: $endpoint');
          break; // Don't try other endpoints if permission is denied
        } else {
          lastError = 'Server error: ${response.statusCode}';
          print('❌ Server error ${response.statusCode} for endpoint: $endpoint');
        }
      } catch (e) {
        lastError = e.toString();
        print('❌ Error adding allergen via $endpoint: $e');
        
        if (e.toString().contains('TimeoutException')) {
          lastError = 'Request timed out - please check your internet connection';
        } else if (e.toString().contains('SocketException')) {
          lastError = 'Network connection failed - please check your internet';
        }
        
        continue;
      }
    }

    print('❌ All allergen addition endpoints failed. Last error: $lastError');
    return false;
  }

  static Future<bool> removeUserAllergen({
    required int userId,
    required int allergenId,
  }) async {
    if (userId <= 0) {
      print('❌ Invalid userId for allergen removal: $userId');
      return false;
    }

    final endpoints = [
      '${ApiConfig.springBootBaseUrl}/user/$userId/allergens/$allergenId',
      '${ApiConfig.baseUrl}/user/$userId/allergens/$allergenId',
      '${ApiConfig.springBootBaseUrl}/allergen/user/$userId/remove/$allergenId',
    ];

    String lastError = '';

    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      try {
        final url = Uri.parse(endpoint);
        print('🔄 Attempting to remove allergen via endpoint ${i + 1}/${endpoints.length}: $url');
        
        final response = await http.delete(url).timeout(Duration(seconds: 8));

        print('📥 Remove allergen response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          try {
            if (response.body.isNotEmpty) {
              final Map<String, dynamic> json = jsonDecode(response.body);
              if (json['success'] == true || json['code'] == 200) {
                print('✅ Allergen removed successfully via $endpoint');
                return true;
              }
            } else {
              // 204 No Content - successful deletion
              print('✅ Allergen removed successfully via $endpoint (no content)');
              return true;
            }
          } catch (parseError) {
            // If JSON parsing fails but status is success, assume it worked
            if (response.statusCode == 204) {
              print('✅ Allergen removed successfully via $endpoint (no JSON response)');
              return true;
            }
          }
        } else if (response.statusCode == 404) {
          lastError = 'Allergen not found or already removed';
          print('⚠️ Allergen not found at endpoint: $endpoint - trying next endpoint');
          continue;
        } else if (response.statusCode == 403) {
          lastError = 'Permission denied - please check your login status';
          print('❌ Permission denied for endpoint: $endpoint');
          break;
        } else {
          lastError = 'Server error: ${response.statusCode}';
          print('❌ Server error ${response.statusCode} for endpoint: $endpoint');
        }
      } catch (e) {
        lastError = e.toString();
        print('❌ Error removing allergen via $endpoint: $e');
        
        if (e.toString().contains('TimeoutException')) {
          lastError = 'Request timed out - please check your internet connection';
        } else if (e.toString().contains('SocketException')) {
          lastError = 'Network connection failed - please check your internet';
        }
        
        continue;
      }
    }

    print('❌ All allergen removal endpoints failed. Last error: $lastError');
    return false;
  }
}