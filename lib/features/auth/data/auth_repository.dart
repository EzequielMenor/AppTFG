import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Hacer login con email y password
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Registrar nuevo usuario
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Cerrar sesion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Comprobar si hay usuario actualmente
  User? get currentUser => _supabase.auth.currentUser;

  // Escuchar cambios de estado en tiempo real (si expira el token, etc)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
