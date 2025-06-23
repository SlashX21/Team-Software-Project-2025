import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://your-java-backend.com';

  static Future<String?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['token'];
    }
    return null;
  }

  static Future<bool> register(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return response.statusCode == 200;
  }

  static Future<String?> scanBarcode(File imageFile) async {
    final uri = Uri.parse('$baseUrl/api/barcode');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final resString = await response.stream.bytesToString();
      final jsonData = json.decode(resString);
      return jsonData['barcode'];
    }
    return null;
  }

  static Future<List<String>> uploadReceipt(File imageFile) async {
    final uri = Uri.parse('$baseUrl/api/ocr');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final resString = await response.stream.bytesToString();
      final jsonData = json.decode(resString);
      return List<String>.from(jsonData['products']);
    }
    return [];
  }
}