class User {
  final String id;
  final String name;
  final String email;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 