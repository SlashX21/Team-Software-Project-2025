// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/user.dart';

Future<bool> registerUser({
  required String userName,
  required String passwordHash,
  required String email,
  required String gender,
  required double heightCm,
  required double weightKg,
}) async {
  final url = Uri.parse('http://127.0.0.1:8080/user');

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

  // final response = await http.post(
  //   url,
  //   headers: {'Content-Type': 'application/json'},
  //   body: jsonEncode({
  //     "userName": userName,
  //     "password": password,
  //     "email": email
  //   }),
  // );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return true;
  } else {
    print("Register failed: ${response.statusCode} ${response.body}");
    return false;
  }
}

// Future<Map<String, dynamic>?> loginUser({
//   required String userName,
//   required String passwordHash,
// }) async {
//   final url = Uri.parse('http://127.0.0.1:8080/login');

//   final response = await http.post(
//     url,74
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode({
//       "userName": userName,
//       "passwordHash": passwordHash,
//     }),
//   );

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> json = jsonDecode(response.body);
//     if (json['code'] == 200 && json['data'] != null) {
//       return json['data']; 
//     }
//   }

//   return null;
// }

Future<User?> loginUser({
  required String userName,
  required String passwordHash,
}) async {
  final url = Uri.parse('http://127.0.0.1:8080/user/login');

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
      return User.fromJson(json['data']);
    }
  }

  return null;
}

Future<User?> updateUser(User user) async {
  final url = Uri.parse('http://127.0.0.1:8080/user');
  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "userId": user.userId,
      "userName": user.userName,
      "email": user.email,
      "passwordHash": user.passwordHash,
      "age": user.age,
      "gender": user.gender,
      "heightCm": user.heightCm,
      "weightKg": user.weightKg,
      "activityLevel": user.activityLevel,
      "nutritionGoal": user.nutritionGoal,
      "dailyCaloriesTarget": user.dailyCaloriesTarget,
      "dailyProteinTarget": user.dailyProteinTarget,
      "dailyCarbTarget": user.dailyCarbTarget,
      "dailyFatTarget": user.dailyFatTarget,
      "createdTime": user.createdTime,
    }),
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    if (json['code'] == 200 && json['data'] != null) {
      return User.fromJson(json['data']);
    }
  }
  return null;
}