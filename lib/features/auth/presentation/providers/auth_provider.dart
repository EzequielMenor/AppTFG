import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  // Inicializar estado escuchando a Supabase y mapeando a UserModel
  void _init() {
    _repository.authStateChanges.listen((data) {
      final supabaseUser = data.session?.user;
      _user = supabaseUser != null
          ? UserModel.fromSupabaseUser(supabaseUser)
          : null;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.signIn(email, password);
      _setLoading(false);
      return true; // Éxito
    } catch (e) {
      _setLoading(false);
      _handleError(e);
      return false; // Fallo
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.signUp(email, password);
      _setLoading(false);
      return true; // Éxito
    } catch (e) {
      _setLoading(false);
      _handleError(e);
      return false; // Fallo
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handleError(Object e) {
    print("================================");
    print("💥💥 ERROR SUPABASE: $e");
    print("================================");
    if (e is AuthException) {
      _errorMessage = e.message; // Mensaje traducido de Supabase
    } else {
      _errorMessage = "Ha ocurrido un error inesperado. Revisa tu conexión.";
    }
    notifyListeners();
  }
}
