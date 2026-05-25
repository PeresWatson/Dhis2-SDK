import 'package:flutter/foundation.dart';
import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';

/// Provider for managing the DHIS2 SDK instance across the app.
class SdkProvider extends ChangeNotifier {
  Dhis2Sdk? _sdk;
  bool _isLoading = false;
  String? _error;

  /// The SDK instance (null if not initialized)
  Dhis2Sdk? get sdk => _sdk;

  /// Whether the SDK is initialized
  bool get isInitialized => _sdk != null;

  /// Whether the user is authenticated
  bool get isAuthenticated => _sdk?.isAuthenticated ?? false;

  /// Whether an operation is in progress
  bool get isLoading => _isLoading;

  /// Current error message (null if no error)
  String? get error => _error;

  /// Current user (null if not authenticated)
  User? get currentUser => _sdk?.currentUser;

  /// Authentication state
  AuthState get authState => _sdk?.authState ?? AuthState.initial();

  /// Initialize the SDK and authenticate
  Future<bool> initialize({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create configuration
      final config = Dhis2Config(
        baseUrl: baseUrl,
        credentials: Credentials.basic(username, password),
      );

      // Initialize SDK
      _sdk = await Dhis2Sdk.initialize(
        config: config,
        options: const SdkOptions(
          enableConnectivityMonitoring: true,
          logLevel: LogLevel.debug,
        ),
      );

      // Authenticate
      final result = await _sdk!.auth.authenticate();
      
      if (result.isFailure) {
        _error = result.error?.toString() ?? 'Authentication failed';
        _sdk = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Listen to auth state changes
      _sdk!.authStateStream.listen((state) {
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _sdk = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout and dispose SDK
  Future<void> logout() async {
    if (_sdk != null) {
      await _sdk!.logout();
      await _sdk!.dispose();
      _sdk = null;
      notifyListeners();
    }
  }

  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sdk?.dispose();
    super.dispose();
  }
}
