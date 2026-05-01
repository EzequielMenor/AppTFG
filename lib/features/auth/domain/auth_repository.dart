import 'package:supabase_flutter/supabase_flutter.dart';

/// Interfaz abstracta del repositorio de autenticación.
///
/// Define el contrato que debe cumplir cualquier implementación de
/// autenticación, permitiendo inyección de dependencias y testing
/// sin acoplarse a Supabase directamente.
///
/// Implementada por [AuthRepository] en `data/`.
abstract class IAuthRepository {
  Future<AuthResponse> signIn(String email, String password);
  Future<AuthResponse> signUp(String email, String password);
  Future<void> signOut();
  User? get currentUser;
  Stream<AuthState> get authStateChanges;
}
