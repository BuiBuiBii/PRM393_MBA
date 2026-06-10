class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.githubConnected,
    required this.createdAt,
    this.avatar,
    this.githubUsername,
    this.provider = 'local',
    this.role,
  });

  final String id;
  final String email;
  final String name;
  final String? avatar;
  final bool githubConnected;
  final String? githubUsername;
  final String createdAt;
  final String provider;
  final String? role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final githubAccount = json['githubAccount'];
    final provider = (json['provider'] ?? 'local').toString();
    final githubUsername = json['githubUsername']?.toString() ??
        (githubAccount is Map ? githubAccount['username']?.toString() : null);
    final githubConnected = json['githubConnected'] == true ||
        githubAccount != null ||
        provider == 'github' ||
        (githubUsername != null && githubUsername.isNotEmpty);

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['username'] ?? 'User').toString(),
      avatar: json['avatar']?.toString() ?? json['avatarUrl']?.toString(),
      githubConnected: githubConnected,
      githubUsername: githubUsername,
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      provider: provider,
      role: json['role']?.toString(),
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
        'provider': provider,
        if (role != null) 'role': role,
      };

  UserModel copyWith({
    String? name,
    String? avatar,
    bool? githubConnected,
    String? githubUsername,
    String? provider,
    String? role,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      githubConnected: githubConnected ?? this.githubConnected,
      githubUsername: githubUsername ?? this.githubUsername,
      createdAt: createdAt,
      provider: provider ?? this.provider,
      role: role ?? this.role,
    );
  }

  UserModel mergeMissingFrom(UserModel other) {
    return copyWith(
      avatar: avatar ?? other.avatar,
      githubConnected: githubConnected || other.githubConnected,
      githubUsername: githubUsername ?? other.githubUsername,
      provider: provider == 'local' && other.provider != 'local' ? other.provider : provider,
      role: role ?? other.role,
    );
  }

  bool get isAdmin => role == 'admin';
}