import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  // Inicializar estado escuchando a Supabase
  void _init() {
    _repository.authStateChanges.listen((data) {
      _user = data.session?.user;
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
