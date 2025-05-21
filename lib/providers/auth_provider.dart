import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  User? _currentUser;
  String? _token;
  final ApiService _apiService = ApiService();

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;

  // Check if current user has admin role
  Future<bool> isAdmin() async {
    if (_currentUser == null) {
      await initialize();
    }
    // print("Checking if user is admin. User role: ${_currentUser?.role}");
    // Compare against the full role string from the backend/JWT
    return _currentUser?.role?.toUpperCase() == 'ADMIN'; // Use normalized role
  }

  // Check if current user has professor role
  Future<bool> isProfessor() async {
    if (_currentUser == null) {
      await initialize();
    }
    // print("Checking if user is professor. User role: ${_currentUser?.role}");
    // Compare against the full role string from the backend/JWT
    return _currentUser?.role?.toUpperCase() ==
        'PROFESSOR'; // Use normalized role
  }

  // Check if current user has student role
  Future<bool> isStudent() async {
    if (_currentUser == null) {
      await initialize();
    }
    // print("Checking if user is student. User role: ${_currentUser?.role}");
    // Default to student if no role specified
    return _currentUser?.role == null ||
        _currentUser?.role?.toUpperCase() == 'STUDENT'; // Use normalized role
  }

  // Get user role
  String? get userRole => _currentUser?.role;

  // Initialize the provider
  Future<void> initialize() async {
    // Set loading state initially, but notify at the end
    _isLoading = true;
    // notifyListeners(); // Removed intermediate notify

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        // Check if token is expired
        if (JwtDecoder.isExpired(token)) {
          await _apiService.clearToken();
          _token = null;
          _currentUser = null;
        } else {
          _token = token;
          // Extract user info from token
          final decodedToken = JwtDecoder.decode(token);

          // Debug the token data
          // print("Token data: ${decodedToken.toString()}");

          // Try different possible key names for the user ID
          String? userId = decodedToken['sub'] ??
              decodedToken['id'] ??
              decodedToken['userId'] ??
              decodedToken['user_id'];

          if (userId == null || userId.isEmpty) {
            // print("Warning: Could not extract user ID from token");
          }

          // Look for role in different possible fields
          String? userRole = decodedToken['role'] ??
              decodedToken['authorities']?.toString() ??
              decodedToken['scope']?.toString() ??
              decodedToken['roles']?.toString();

          if (userRole != null) {
            // Check for Spring Security format like "[ROLE_ADMIN]" or "ROLE_ADMIN"
            if (userRole.contains('ADMIN')) {
              userRole = 'ADMIN';
            } else if (userRole.contains('PROFESSOR')) {
              userRole = 'PROFESSOR';
            } else if (userRole.contains('STUDENT')) {
              userRole = 'STUDENT';
            }
            // print(
            //     "AuthProvider (initialize): Extracted role from token: $userRole"); // Added Log
          } else {
            // print(
            //     "AuthProvider (initialize): Warning: Could not extract role from token"); // Added Log
          }

          // Create user from token data
          _currentUser = User(
            id: userId ?? '',
            username: decodedToken['username'] ?? '',
            fullName: decodedToken['fullName'] ?? decodedToken['name'] ?? '',
            email: decodedToken['email'] ?? '',
            role: userRole,
            emailVerified: true, // If they have a token, they're verified
          );

          // print(
          //     "Initialized user with ID: ${_currentUser?.id} and role: ${_currentUser?.role}");
        }
      }
    } catch (e) {
      // Handle error - ensure state is cleared on error too
      // print('Error initializing auth: $e');
      _token = null;
      _currentUser = null;
    } finally {
      _isLoading = false; // Set final loading state
      notifyListeners(); // Notify once at the end
    }
  }

  // Login user
  Future<bool> login(String username, String password) async {
    // Set loading state initially, but notify at the end
    _isLoading = true;
    // notifyListeners(); // Removed intermediate notify
    bool success = false; // Track success locally

    try {
      final response = await _apiService.login(username, password);

      if (response['success'] && response['data']['token'] != null) {
        _token = response['data']['token'];

        // Decode the token to extract user ID
        final decodedToken = JwtDecoder.decode(_token!);
        // print("Full decoded token: $decodedToken");

        // Try different possible key names for the user ID
        String? userId = decodedToken['sub'] ??
            decodedToken['id'] ??
            decodedToken['userId'] ??
            decodedToken['user_id'] ??
            response['data']['id'] ??
            response['data']['userId'];

        if (userId == null || userId.isEmpty) {
          // print("Warning: Could not extract user ID from token or response");
        } else {
          // print("Login successful, extracted user ID: $userId");
        }

        // Extract role from token
        String? rawRole = decodedToken['role'] ??
            decodedToken['authorities']?.toString() ??
            decodedToken['scope']?.toString() ??
            decodedToken['roles']?.toString();

        String? normalizedRole; // Variable for the normalized role

        if (rawRole != null) {
          // Perform normalization
          if (rawRole.contains('ADMIN')) {
            normalizedRole = 'ADMIN';
          } else if (rawRole.contains('PROFESSOR')) {
            normalizedRole = 'PROFESSOR';
          } else if (rawRole.contains('STUDENT')) {
            normalizedRole = 'STUDENT';
          } else {
            normalizedRole = rawRole; // Keep original if no match
          }
          // print(
          //     "AuthProvider (login): Extracted raw role: $rawRole, Normalized to: $normalizedRole");
        } else {
          // print(
          //     "AuthProvider (login): No role found in token, checking response data...");
          normalizedRole = response['data'][
              'role']; // Use response role directly (assuming it's already simple)
          // print(
          //     "AuthProvider (login): Role from response data: $normalizedRole");
        }

        // Extract user details from response
        _currentUser = User(
          id: userId ?? '', // Use extracted ID
          username: response['data']['username'] ?? '',
          fullName: response['data']['fullName'] ?? '',
          email: response['data']['email'] ?? '',
          role: normalizedRole, // Assign the CORRECTLY normalized role
          emailVerified: true, // If login successful, assume verified
        );

        // print("User logged in with role: ${_currentUser?.role}");
        success = true; // Mark as successful
      } else {
        // Ensure state is cleared on failed login attempt
        _token = null;
        _currentUser = null;
        success = false;
      }
    } catch (e) {
      // print('Login error: $e');
      _token = null; // Clear state on error
      _currentUser = null;
      success = false;
    } finally {
      _isLoading = false; // Set final loading state
      notifyListeners(); // Notify once at the end
      return success; // Return the result
    }
  }

  // Register user
  Future<Map<String, dynamic>> register(
      String username, String password, String fullName, String email) async {
    // Set loading state initially, but notify at the end
    _isLoading = true;
    // notifyListeners(); // Removed intermediate notify

    try {
      final response =
          await _apiService.register(username, password, fullName, email);
      return response;
    } catch (e) {
      // print('Registration error: $e');
      return {
        'success': false,
        'message': 'Network error, please try again later',
      };
    } finally {
      _isLoading = false; // Set final loading state
      notifyListeners(); // Notify once at the end
    }
  }

  // Verify email
  Future<bool> verifyEmail(String email, String code) async {
    // Set loading state initially, but notify at the end
    _isLoading = true;
    // notifyListeners(); // Removed intermediate notify
    bool success = false; // Track success locally

    try {
      final response = await _apiService.verifyEmail(email, code);

      if (response['success'] && response['data']['token'] != null) {
        _token = response['data']['token'];

        // Extract user details from response
        _currentUser = User(
          id: '', // ID might not be in response
          username: response['data']['username'] ?? '',
          fullName: response['data']['fullName'] ?? '',
          email: response['data']['email'] ?? '',
          role: null, // Role might be in token
          emailVerified: true,
        );

        success = true;
      } else {
        _token = null; // Clear state on failure
        _currentUser = null;
        success = false;
      }
    } catch (e) {
      // print('Email verification error: $e');
      _token = null; // Clear state on error
      _currentUser = null;
      success = false;
    } finally {
      _isLoading = false; // Set final loading state
      notifyListeners(); // Notify once at the end
      return success; // Return the result
    }
  }

  // Logout
  Future<void> logout() async {
    // Set loading state initially, but notify at the end
    _isLoading = true;
    // notifyListeners(); // Removed intermediate notify

    try {
      // print("AuthProvider: clearing token from API service");
      await _apiService.clearToken();

      // print("AuthProvider: setting token and current user to null");
      _token = null;
      _currentUser = null;

      // print("AuthProvider: logout completed successfully");
    } catch (e) {
      // print('AuthProvider: Logout error: $e');
      // Even if there's an error, we should still clear local state
      _token = null;
      _currentUser = null;
    } finally {
      _isLoading = false; // Set final loading state
      // Ensure state is definitely null before notifying
      _token = null;
      _currentUser = null;
      // print("AuthProvider: notified listeners of logout");
      notifyListeners(); // Notify once at the end
    }
  }

  // Login with email
  Future<bool> loginWithEmail(String email, String password) async {
    // Set loading state initially, but notify at the end
    _isLoading = true;
    // notifyListeners(); // Removed intermediate notify
    bool success = false; // Track success locally

    try {
      final response = await _apiService.loginWithEmail(email, password);

      if (response['success'] && response['data']['token'] != null) {
        _token = response['data']['token'];

        // Decode the token to extract user ID
        final decodedToken = JwtDecoder.decode(_token!);

        // Try different possible key names for the user ID
        String? userId = decodedToken['sub'] ??
            decodedToken['id'] ??
            decodedToken['userId'] ??
            decodedToken['user_id'] ??
            response['data']['id'] ??
            response['data']['userId'];

        if (userId == null || userId.isEmpty) {
          print("Warning: Could not extract user ID from token or response");
        } else {
          print("Login successful, extracted user ID: $userId");
        }

        // Extract role from token
        String? rawRole = decodedToken['role'] ??
            decodedToken['authorities']?.toString() ??
            decodedToken['scope']?.toString() ??
            decodedToken['roles']?.toString();

        String? normalizedRole; // Variable for the normalized role

        if (rawRole != null) {
          // Perform normalization
          if (rawRole.contains('ADMIN')) {
            normalizedRole = 'ADMIN';
          } else if (rawRole.contains('PROFESSOR')) {
            normalizedRole = 'PROFESSOR';
          } else if (rawRole.contains('STUDENT')) {
            normalizedRole = 'STUDENT';
          } else {
            normalizedRole = rawRole; // Keep original if no match
          }
          print(
              "AuthProvider (loginWithEmail): Extracted raw role: $rawRole, Normalized to: $normalizedRole");
        } else {
          print(
              "AuthProvider (loginWithEmail): No role found in token, checking response data...");
          normalizedRole =
              response['data']['role']; // Use response role directly
          print(
              "AuthProvider (loginWithEmail): Role from response data: $normalizedRole");
        }

        // Extract user details from response, using the NORMALIZED role
        _currentUser = User(
          id: userId ?? '',
          username: response['data']['username'] ?? '',
          fullName: response['data']['fullName'] ?? '',
          email: response['data']['email'] ?? '',
          role: normalizedRole, // Assign the CORRECTLY normalized role
          emailVerified: true, // If login successful, assume verified
        );
        print("User logged in with email, role: ${_currentUser?.role}");

        success = true;
      } else {
        _token = null; // Clear state on failure
        _currentUser = null;
        success = false;
      }
    } catch (e) {
      print('Login with email error: $e');
      _token = null; // Clear state on error
      _currentUser = null;
      success = false;
    } finally {
      _isLoading = false; // Set final loading state
      notifyListeners(); // Notify once at the end
      return success; // Return the result
    }
  }

  // Check if a string is an email
  bool isEmail(String input) {
    // Simple email regex pattern
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(input);
  }

  // Smart login - determine if input is username or email
  Future<bool> smartLogin(String usernameOrEmail, String password) async {
    if (isEmail(usernameOrEmail)) {
      // print("Login attempt with email: $usernameOrEmail");
      return loginWithEmail(usernameOrEmail, password);
    } else {
      // print("Login attempt with username: $usernameOrEmail");
      return login(usernameOrEmail, password);
    }
  }

  // Change password for authenticated user
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response =
          await _apiService.changePassword(currentPassword, newPassword);
      final bool success = response['success'] ?? false;

      if (!success) {
        throw response['message'] ?? 'Failed to change password';
      }

      return true;
    } catch (e) {
      // print('Error changing password: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initiate password reset
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.forgotPassword(email);
      return response['success'] ?? false;
    } catch (e) {
      // print('Forgot password error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password with code
  Future<bool> resetPassword(
      String email, String resetCode, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _apiService.resetPassword(email, resetCode, newPassword);
      return response['success'] ?? false;
    } catch (e) {
      // print('Reset password error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend verification code
  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.resendVerificationCode(email);
      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Unknown error occurred'
      };
    } catch (e) {
      // print('Resend verification code error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend password reset code
  Future<Map<String, dynamic>> resendPasswordResetCode(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.forgotPassword(email);
      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Unknown error occurred'
      };
    } catch (e) {
      // print('Resend password reset code error: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify password reset code
  Future<bool> verifyPasswordResetCode(String email, String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.verifyResetCode(email, code);
      return response['success'] ?? false;
    } catch (e) {
      // print('Verify reset code error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
