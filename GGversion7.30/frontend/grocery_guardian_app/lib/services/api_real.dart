import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/entities/product_analysis.dart';
import 'api_config.dart';

class RealApiService {
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
    final url = Uri.parse('${ApiConfig.baseUrl}/user/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userName": userName,
        "passwordHash": passwordHash,
      }),
    );

    print("Request Body: ${jsonEncode({
      "userName": userName,
      "passwordHash": passwordHash,
    })}");
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['code'] == 200 && json['data'] != null) {
        return json['data'];
      }
    }

    return null;
  }

  static Future<ProductAnalysis> fetchProductByBarcode(String barcode, int userId) async {
    // Step 1: Get basic product info from database
    final dbResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/product/$barcode'));

    if (dbResponse.statusCode != 200) {
      throw Exception('Product not found in database.');
    }

    final json = jsonDecode(dbResponse.body)['data'];

    // Build initial ProductAnalysis object
    final product = ProductAnalysis(
      name: json['productName'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/300x200',
      ingredients: _parseList(json['ingredients']),
      detectedAllergens: _parseList(json['allergens']),
    );

    // Step 2: If userId provided, get LLM analysis from recommendation system
    if (userId != null) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/recommendations/barcode');
        final recResponse = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'productBarcode': barcode,
          }),
        );

        if (recResponse.statusCode == 200) {
          final recData = jsonDecode(recResponse.body)['data'];
          final llm = recData['llmAnalysis'] ?? {};

          return product.copyWith(
            summary: llm['summary'] ?? '',
            detailedAnalysis: llm['detailedAnalysis'] ?? '',
            actionSuggestions: _parseList(llm['actionSuggestions']),
          );
        } else {
          print('Recommendation fetch failed: ${recResponse.statusCode}');
        }
      } catch (e) {
        print('Recommendation system error: $e');
      }
    }
    
    return product;
  }

  static Future<Map<String, dynamic>> uploadReceiptImage(XFile imageFile, int userId) async {
    // Step 1: Upload to OCR service
    final ocrUri = Uri.parse('${ApiConfig.baseUrl}/ocr/scan');
    final bytes = await imageFile.readAsBytes();
    final ocrRequest = http.MultipartRequest('POST', ocrUri)
      ..fields['userId'] = userId.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    final ocrResponse = await http.Response.fromStream(await ocrRequest.send());
    if (ocrResponse.statusCode != 200) {
      throw Exception('OCR upload failed: ${ocrResponse.statusCode}');
    }

    final ocrResult = jsonDecode(ocrResponse.body);
    final ocrProducts = ocrResult['data']?['products'] ?? [];

    // Step 2: Query barcode for each product name
    final List<Map<String, dynamic>> purchasedItems = [];

    for (final item in ocrProducts) {
      final name = item['name'];
      final quantity = item['quantity'] ?? 1;

      if (name != null && name.toString().trim().isNotEmpty) {
        try {
          final barcodeResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/product/name/${Uri.encodeComponent(name)}'),
          );

          if (barcodeResponse.statusCode == 200) {
            final barcodeData = jsonDecode(barcodeResponse.body)['data'];
            final barcode = barcodeData?['barCode']?.toString() ?? '';

            if (barcode.isNotEmpty) {
              purchasedItems.add({
                'barcode': barcode,
                'quantity': quantity,
              });
            }
          }
        } catch (e) {
          print('Exception while fetching barcode for $name: $e');
        }
      }
    }

    // Step 3: Send to recommendation system
    final recUri = Uri.parse('${ApiConfig.baseUrl}/recommendations/receipt');
    final recResponse = await http.post(
      recUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'purchasedItems': purchasedItems,
      }),
    );

    if (recResponse.statusCode == 200) {
      final recResult = jsonDecode(recResponse.body);
      return recResult['data']?['data'] ?? {};
    } else {
      throw Exception('Recommendation failed: ${recResponse.statusCode}');
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
    final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['code'] == 200 && json['data'] != null) {
          return json['data'];
        }
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
    final url = Uri.parse('${ApiConfig.baseUrl}/user');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json['code'] == 200;
      }
    } catch (e) {
      print('Error updating user profile: $e');
    }

    return false;
  }

  // ============================================================================
  // User Allergen APIs
  // ============================================================================
  
  static Future<List<Map<String, dynamic>>?> getUserAllergens({required int userId}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId/allergens');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['code'] == 200 && json['data'] != null) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (e) {
      print('Error fetching user allergens: $e');
    }

    return null;
  }

  static Future<bool> addUserAllergen({
    required int userId,
    required int allergenId,
    required String severityLevel,
    required String notes,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId/allergens');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "allergenId": allergenId,
          "severityLevel": severityLevel,
          "notes": notes,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json['code'] == 200;
      }
    } catch (e) {
      print('Error adding user allergen: $e');
    }

    return false;
  }

  static Future<bool> removeUserAllergen({
    required int userId,
    required int allergenId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/user/$userId/allergens/$allergenId');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return json['code'] == 200;
      }
    } catch (e) {
      print('Error removing user allergen: $e');
    }

    return false;
  }
}