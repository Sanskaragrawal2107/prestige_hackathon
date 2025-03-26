import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isInitializing = true;
  app_models.User? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  app_models.User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        // Using Supabase auth directly
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null && !session.isExpired) {
          // Create user directly from auth data
          final supabaseUser = session.user;
          if (supabaseUser != null) {
            _user = app_models.User(
              id: supabaseUser.id,
              name: supabaseUser.userMetadata?['name'] ?? supabaseUser.email?.split('@')[0] ?? 'User',
              email: supabaseUser.email ?? '',
              isVerified: supabaseUser.emailConfirmedAt != null,
              createdAt: supabaseUser.createdAt,
            );
          }
        }
      }
    } catch (e) {
      print('Auth initialization error: ${e.toString()}');
      // Don't set error here, just leave user as null
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the API service to register
      final response = await ApiService.register(name, email, password);

      if (response['message'] == 'User registered successfully') {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['detail'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the API service to login
      final response = await ApiService.login(email, password);

      if (response['access_token'] != null) {
        // Get user from auth session
        final supabaseUser = Supabase.instance.client.auth.currentUser;
        if (supabaseUser != null) {
          _user = app_models.User(
            id: supabaseUser.id,
            name: supabaseUser.userMetadata?['name'] ?? supabaseUser.email?.split('@')[0] ?? 'User',
            email: supabaseUser.email ?? '',
            isVerified: supabaseUser.emailConfirmedAt != null,
            createdAt: supabaseUser.createdAt,
          );
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = 'Failed to get user data';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error = response['detail'] ?? 'Authentication failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear token and sign out from Supabase
      await ApiService.logout();
      await Supabase.instance.client.auth.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
