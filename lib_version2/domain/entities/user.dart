class User {
  final int? userId;
  final String userName;
  final String email;
  final String passwordHash;
  final int? age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String? activityLevel;
  final String? nutritionGoal;
  final double? dailyCaloriesTarget;
  final double? dailyProteinTarget;
  final double? dailyCarbTarget;
  final double? dailyFatTarget;
  final String? createdTime;

  User({
    this.userId,
    required this.userName,
    required this.email,
    required this.passwordHash,
    this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    this.activityLevel,
    this.nutritionGoal,
    this.dailyCaloriesTarget,
    this.dailyProteinTarget,
    this.dailyCarbTarget,
    this.dailyFatTarget,
    this.createdTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      userName: json['userName'],
      email: json['email'],
      passwordHash: json['passwordHash'],
      age: json['age'],
      gender: json['gender'],
      heightCm: (json['heightCm'] is int) ? (json['heightCm'] as int).toDouble() : (json['heightCm'] ?? 0.0),
      weightKg: (json['weightKg'] is int) ? (json['weightKg'] as int).toDouble() : (json['weightKg'] ?? 0.0),
      activityLevel: json['activityLevel'],
      nutritionGoal: json['nutritionGoal'],
      dailyCaloriesTarget: (json['dailyCaloriesTarget'] as num?)?.toDouble(),
      dailyProteinTarget: (json['dailyProteinTarget'] as num?)?.toDouble(),
      dailyCarbTarget: (json['dailyCarbTarget'] as num?)?.toDouble(),
      dailyFatTarget: (json['dailyFatTarget'] as num?)?.toDouble(),
      createdTime: json['createdTime'],
    );
  }
} 