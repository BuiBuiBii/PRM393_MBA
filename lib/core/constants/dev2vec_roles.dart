/// Role Dev2Vec chuẩn — khớp BE `GET /roles/catalog`.
class Dev2VecRole {
  const Dev2VecRole({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static const backend = Dev2VecRole(id: 'backend', name: 'Backend Developer');
  static const frontend = Dev2VecRole(id: 'frontend', name: 'Frontend Developer');
  static const mobile = Dev2VecRole(id: 'mobile', name: 'Mobile Developer');
  static const devops = Dev2VecRole(id: 'devops', name: 'DevOps Engineer');
  static const dataScientist = Dev2VecRole(id: 'data_scientist', name: 'Data Scientist');

  static const List<Dev2VecRole> catalog = [
    backend,
    frontend,
    mobile,
    devops,
    dataScientist,
  ];

  static Dev2VecRole? findById(String? roleId) {
    if (roleId == null || roleId.isEmpty) return null;
    for (final role in catalog) {
      if (role.id == roleId) return role;
    }
    return null;
  }

  static Dev2VecRole? findByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final role in catalog) {
      if (role.name == name) return role;
    }
    return null;
  }

  factory Dev2VecRole.fromJson(Map<String, dynamic> json) {
    return Dev2VecRole(
      id: (json['roleId'] ?? json['id'] ?? '').toString(),
      name: (json['roleName'] ?? json['name'] ?? '').toString(),
    );
  }
}
