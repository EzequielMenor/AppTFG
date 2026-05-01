import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de datos para el usuario autenticado.
///
/// Sigue el mismo patrón que los modelos en [analytics_models.dart]:
/// constructor `const` con campos final, `factory fromJson`, `toJson`.
///
/// Refleja los campos que devuelve el backend (`UserProfileDTO`):
///   id (UUID), email, username/displayName, role, createdAt.
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.role = 'user',
    this.createdAt,
  });

  /// Construye desde un [User] de Supabase Auth.
  ///
  /// El `displayName` intenta tomarlo de los metadatos del usuario
  /// (clave `username`) si el backend los sincronizó; en caso contrario
  /// se deja `null` y las screens usan el email como fallback.
  factory UserModel.fromSupabaseUser(User user) => UserModel(
    id: user.id,
    email: user.email ?? '',
    displayName: user.userMetadata?['username'] as String?,
    role: user.userMetadata?['role'] as String? ?? 'user',
    createdAt: DateTime.tryParse(user.createdAt),
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String? ?? json['username'] as String?,
    role: json['role'] as String? ?? 'user',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (displayName != null) 'displayName': displayName,
    'role': role,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  /// `true` si el usuario tiene rol de administrador.
  bool get isAdmin => role == 'admin';

  /// Nombre visible del usuario: `displayName` si existe, sino el prefijo
  /// del email (todo antes del `@`).
  String get username => displayName ?? email.split('@').first;

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: $role)';
}
