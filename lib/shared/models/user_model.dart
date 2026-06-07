class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.githubConnected,
    required this.createdAt,
    this.avatar,
    this.githubUsername,
  });

  final String id;
  final String email;
  final String name;
  final String? avatar;
  final bool githubConnected;
  final String? githubUsername;
  final String createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final githubAccount = json['githubAccount'];
    final githubUsername = json['githubUsername']?.toString() ??
        (githubAccount is Map ? githubAccount['username']?.toString() : null);

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['username'] ?? 'User').toString(),
      avatar: json['avatar']?.toString(),
      githubConnected: json['githubConnected'] == true || githubAccount != null,
      githubUsername: githubUsername,
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatar': avatar,
        'githubConnected': githubConnected,
        'githubUsername': githubUsername,
        'createdAt': createdAt,
      };

  UserModel copyWith({
    String? name,
    bool? githubConnected,
    String? githubUsername,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      avatar: avatar,
      githubConnected: githubConnected ?? this.githubConnected,
      githubUsername: githubUsername ?? this.githubUsername,
      createdAt: createdAt,
    );
  }
}