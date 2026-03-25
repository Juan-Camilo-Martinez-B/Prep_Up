class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.occupation,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? occupation;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? occupation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      occupation: occupation ?? this.occupation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      displayName: (json['full_name'] as String?) ?? (json['displayName'] as String?) ?? '',
      phone: json['phone'] as String?,
      occupation: json['occupation'] as String?,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? (json['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse((json['updated_at'] as String?) ?? (json['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': displayName,
      'phone': phone,
      'occupation': occupation,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, phone: $phone, occupation: $occupation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserModel &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            email == other.email &&
            displayName == other.displayName &&
            phone == other.phone &&
            occupation == other.occupation &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, displayName, phone, occupation, createdAt, updatedAt);
  }
}
