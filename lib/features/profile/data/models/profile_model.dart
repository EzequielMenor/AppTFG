/// Modelo de datos que representa las preferencias editables del perfil.
///
/// Campos:
/// - [displayName]: nombre visible (opcional, se usa el email como fallback).
/// - [weightUnit]: unidad de peso preferida (`"kg"` o `"lb"`).
/// - [email]: email del usuario (lectura, no editable por esta vía).
class ProfileModel {
  final String? displayName;
  final String weightUnit;
  final String email;

  const ProfileModel({
    this.displayName,
    this.weightUnit = 'kg',
    required this.email,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    displayName: json['displayName'] as String?,
    weightUnit: json['weightUnit'] as String? ?? 'kg',
    email: json['email'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    if (displayName != null) 'displayName': displayName,
    'weightUnit': weightUnit,
    'email': email,
  };

  ProfileModel copyWith({
    String? displayName,
    String? weightUnit,
    String? email,
  }) {
    return ProfileModel(
      displayName: displayName ?? this.displayName,
      weightUnit: weightUnit ?? this.weightUnit,
      email: email ?? this.email,
    );
  }

  @override
  String toString() =>
      'ProfileModel(displayName: $displayName, weightUnit: $weightUnit, email: $email)';
}
