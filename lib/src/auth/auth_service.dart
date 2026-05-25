/// Authentication Service
/// 
/// Handles all authentication operations for the SDK including
/// login, logout, session management, and credential storage.
/// 
/// ## Purpose
/// 
/// - Authenticate users with DHIS2
/// - Manage session lifecycle
/// - Store credentials securely
/// - Track authentication state
/// - Verify permissions
/// 
/// ## Data Flow
/// 
/// ```
/// login() → Validate → API Call → Store Credentials → Update State
///                                        ↓
///                              SecureStorage (encrypted)
/// ```
/// 
/// ## Security
/// 
/// - Credentials stored with flutter_secure_storage
/// - Passwords never logged
/// - Automatic session validation
/// - Secure token management
/// 
/// ## Extension Points
/// 
/// - Add custom auth listeners
/// - Implement SSO/OAuth flows
/// - Add biometric authentication
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/base/base_service.dart';
import '../core/base/result.dart';
import '../core/config/dhis2_config.dart';
import '../core/constants/api_endpoints.dart';
import '../exceptions/auth_exception.dart';
import '../exceptions/dhis2_exception.dart';
import '../logging/sdk_logger.dart';
import '../network/http_client.dart';
import 'auth_state.dart';
import 'models/credentials.dart';
import 'models/user.dart';

/// Keys for secure storage.
abstract class _StorageKeys {
  static const String username = 'dhis2_sdk_username';
  static const String password = 'dhis2_sdk_password';
  static const String token = 'dhis2_sdk_token';
  static const String authType = 'dhis2_sdk_auth_type';
  static const String serverUrl = 'dhis2_sdk_server_url';
}

/// Authentication service for DHIS2.
/// 
/// Example:
/// ```dart
/// final authService = AuthService(
///   config: config,
///   logger: logger,
///   httpClient: httpClient,
/// );
/// 
/// // Login
/// final result = await authService.login(
///   username: 'admin',
///   password: 'district',
/// );
/// 
/// result.fold(
///   onSuccess: (user) => print('Logged in as ${user.displayName}'),
///   onFailure: (error) => print('Login failed: ${error.message}'),
/// );
/// 
/// // Check state
/// if (authService.isAuthenticated) {
///   print('Current user: ${authService.currentUser?.displayName}');
/// }
/// ```
class AuthService extends BaseService {
  /// HTTP client for API calls.
  final Dhis2HttpClient _httpClient;

  /// Secure storage for credentials.
  final FlutterSecureStorage _secureStorage;

  /// Stream controller for auth state changes.
  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  /// Current authentication state.
  AuthState _currentState = const AuthInitial();

  /// Current authenticated user.
  User? _currentUser;

  /// Stored credentials (in memory for current session).
  Credentials? _credentials;

  /// Creates a new AuthService.
  AuthService({
    required Dhis2Config config,
    required SdkLogger logger,
    required Dhis2HttpClient httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        super(config: config, logger: logger);

  /// Stream of authentication state changes.
  /// 
  /// Subscribe to react to login/logout events.
  Stream<AuthState> get stateStream => _stateController.stream;

  /// Current authentication state.
  AuthState get state => _currentState;

  /// Current authenticated user, if any.
  User? get currentUser => _currentUser;

  /// Whether there is an authenticated user.
  bool get isAuthenticated => _currentState is Authenticated;

  /// Current credentials (in memory only).
  Credentials? get credentials => _credentials;

  @override
  Future<void> initialize() async {
    await super.initialize();
    
    // Try to restore session from secure storage
    await _tryRestoreSession();
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await super.dispose();
  }

  /// Updates the authentication state.
  void _updateState(AuthState newState) {
    _currentState = newState;
    _stateController.add(newState);
    logger.debug('Auth state changed: ${newState.runtimeType}');
  }

  /// Authenticates with username and password.
  /// 
  /// Returns [Result.success] with [User] on success,
  /// or [Result.failure] with [AuthException] on failure.
  Future<Result<User, AuthException>> login({
    required String username,
    required String password,
    bool rememberCredentials = true,
  }) async {
    ensureInitialized();
    logger.info('Attempting login for user: $username');
    _updateState(const Authenticating('Validating credentials...'));

    // Validate input
    if (username.isEmpty) {
      final error = AuthException.invalidCredentials();
      _updateState(AuthenticationFailed(message: error.message, code: error.code));
      return Result.failure(error);
    }

    if (password.isEmpty) {
      final error = AuthException.invalidCredentials();
      _updateState(AuthenticationFailed(message: error.message, code: error.code));
      return Result.failure(error);
    }

    // Create credentials
    final credentials = Credentials.basic(username: username, password: password);

    return _authenticate(credentials, rememberCredentials);
  }

  /// Authenticates with a Personal Access Token (PAT).
  Future<Result<User, AuthException>> loginWithToken({
    required String username,
    required String token,
    bool rememberCredentials = true,
  }) async {
    ensureInitialized();
    logger.info('Attempting token login for user: $username');
    _updateState(const Authenticating('Validating token...'));

    if (token.isEmpty) {
      final error = AuthException.invalidToken();
      _updateState(AuthenticationFailed(message: error.message, code: error.code));
      return Result.failure(error);
    }

    final credentials = Credentials.token(username: username, token: token);
    return _authenticate(credentials, rememberCredentials);
  }

  /// Core authentication logic.
  Future<Result<User, AuthException>> _authenticate(
    Credentials credentials,
    bool remember,
  ) async {
    try {
      _updateState(const Authenticating('Connecting to server...'));

      // Set credentials on HTTP client
      _httpClient.setCredentials(credentials);

      // Fetch user details to verify credentials
      _updateState(const Authenticating('Fetching user details...'));
      
      final response = await _httpClient.get(
        ApiEndpoints.meWithFields([
          'id',
          'username',
          'displayName',
          'firstName',
          'surname',
          'email',
          'phoneNumber',
          'authorities',
          'organisationUnits[id]',
          'dataViewOrganisationUnits[id]',
          'userRoles[id]',
          'userGroups[id]',
          'settings[keyUiLocale,keyDbLocale]',
          'created',
          'lastLogin',
        ]),
      );

      // Parse user
      final user = User.fromJson(response.data as Map<String, dynamic>);
      _currentUser = user;
      _credentials = credentials;

      // Save credentials if requested
      if (remember) {
        await _saveCredentials(credentials);
      }

      // Update state
      _updateState(Authenticated(
        user: user,
        authenticatedAt: DateTime.now(),
      ));

      logger.info('Login successful for user: ${user.displayName}');
      return Result.success(user);
    } on AuthException catch (e) {
      _httpClient.clearCredentials();
      _updateState(AuthenticationFailed(message: e.message, code: e.code));
      return Result.failure(e);
    } on Dhis2Exception catch (e) {
      _httpClient.clearCredentials();
      final authError = AuthException(
        message: e.message,
        code: e.code,
        cause: e,
      );
      _updateState(AuthenticationFailed(message: e.message, code: e.code));
      return Result.failure(authError);
    } catch (e, stackTrace) {
      _httpClient.clearCredentials();
      logger.error('Login failed with unexpected error', e, stackTrace);
      
      final authError = AuthException(
        message: 'Login failed: ${e.toString()}',
        code: 'AUTH_UNEXPECTED_ERROR',
        cause: e,
      );
      _updateState(AuthenticationFailed(
        message: authError.message,
        code: authError.code,
      ));
      return Result.failure(authError);
    }
  }

  /// Logs out the current user.
  /// 
  /// Clears credentials from memory and secure storage.
  Future<void> logout() async {
    ensureInitialized();
    logger.info('Logging out user: ${_currentUser?.username}');

    _currentUser = null;
    _credentials = null;
    _httpClient.clearCredentials();
    
    await _clearStoredCredentials();
    _updateState(const Unauthenticated('Logged out'));
  }

  /// Validates the current session is still active.
  /// 
  /// Returns true if session is valid, false otherwise.
  Future<Result<bool, AuthException>> validateSession() async {
    ensureInitialized();

    if (!isAuthenticated || _credentials == null) {
      return const Result.success(false);
    }

    try {
      logger.debug('Validating session...');
      
      // Simple check - try to fetch user info
      await _httpClient.get(ApiEndpoints.me);
      
      logger.debug('Session is valid');
      return const Result.success(true);
    } on AuthException catch (e) {
      if (e.code == 'AUTH_SESSION_EXPIRED' || e.code == 'API_UNAUTHORIZED') {
        _updateState(SessionExpired(previousUser: _currentUser));
        _currentUser = null;
      }
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AuthException(
        message: 'Session validation failed',
        code: 'AUTH_VALIDATION_FAILED',
        cause: e,
      ));
    }
  }

  /// Refreshes the current user data.
  Future<Result<User, AuthException>> refreshUser() async {
    ensureInitialized();

    if (!isAuthenticated) {
      return Result.failure(AuthException.notAuthenticated());
    }

    try {
      final response = await _httpClient.get(
        ApiEndpoints.meWithFields([
          'id',
          'username',
          'displayName',
          'firstName',
          'surname',
          'email',
          'authorities',
          'organisationUnits[id]',
          'dataViewOrganisationUnits[id]',
        ]),
      );

      final user = User.fromJson(response.data as Map<String, dynamic>);
      _currentUser = user;

      // Update state with new user data
      _updateState(Authenticated(
        user: user,
        authenticatedAt: (_currentState as Authenticated).authenticatedAt,
      ));

      return Result.success(user);
    } catch (e) {
      return Result.failure(AuthException(
        message: 'Failed to refresh user data',
        code: 'AUTH_REFRESH_FAILED',
        cause: e,
      ));
    }
  }

  /// Checks if user has a specific authority.
  bool hasAuthority(String authority) {
    return _currentUser?.hasAuthority(authority) ?? false;
  }

  /// Checks if user has any of the given authorities.
  bool hasAnyAuthority(List<String> authorities) {
    return _currentUser?.hasAnyAuthority(authorities) ?? false;
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Tries to restore session from secure storage.
  Future<void> _tryRestoreSession() async {
    try {
      final storedServerUrl = await _secureStorage.read(key: _StorageKeys.serverUrl);
      
      // Only restore if stored URL matches current config
      if (storedServerUrl != config.baseUrl) {
        logger.debug('Stored server URL does not match, skipping restore');
        await _clearStoredCredentials();
        return;
      }

      final username = await _secureStorage.read(key: _StorageKeys.username);
      final password = await _secureStorage.read(key: _StorageKeys.password);
      final token = await _secureStorage.read(key: _StorageKeys.token);
      final authTypeStr = await _secureStorage.read(key: _StorageKeys.authType);

      if (username == null || username.isEmpty) {
        logger.debug('No stored credentials found');
        return;
      }

      logger.info('Restoring session for user: $username');

      Credentials credentials;
      if (authTypeStr == 'token' && token != null) {
        credentials = Credentials.token(username: username, token: token);
      } else if (password != null) {
        credentials = Credentials.basic(username: username, password: password);
      } else {
        logger.debug('Incomplete stored credentials');
        return;
      }

      // Try to authenticate with stored credentials
      await _authenticate(credentials, false);
    } catch (e, stackTrace) {
      logger.error('Failed to restore session', e, stackTrace);
      // Don't throw - just stay unauthenticated
      _updateState(const Unauthenticated());
    }
  }

  /// Saves credentials to secure storage.
  Future<void> _saveCredentials(Credentials credentials) async {
    try {
      await _secureStorage.write(
        key: _StorageKeys.serverUrl,
        value: config.baseUrl,
      );
      await _secureStorage.write(
        key: _StorageKeys.username,
        value: credentials.username,
      );
      await _secureStorage.write(
        key: _StorageKeys.authType,
        value: credentials.authType.name,
      );

      if (credentials.authType == AuthType.basic) {
        await _secureStorage.write(
          key: _StorageKeys.password,
          value: credentials.password,
        );
        await _secureStorage.delete(key: _StorageKeys.token);
      } else {
        await _secureStorage.write(
          key: _StorageKeys.token,
          value: credentials.token,
        );
        await _secureStorage.delete(key: _StorageKeys.password);
      }

      logger.debug('Credentials saved to secure storage');
    } catch (e, stackTrace) {
      logger.error('Failed to save credentials', e, stackTrace);
      // Non-fatal - continue without persistence
    }
  }

  /// Clears credentials from secure storage.
  Future<void> _clearStoredCredentials() async {
    try {
      await _secureStorage.delete(key: _StorageKeys.username);
      await _secureStorage.delete(key: _StorageKeys.password);
      await _secureStorage.delete(key: _StorageKeys.token);
      await _secureStorage.delete(key: _StorageKeys.authType);
      // Note: Keep serverUrl for convenience
      logger.debug('Stored credentials cleared');
    } catch (e, stackTrace) {
      logger.error('Failed to clear stored credentials', e, stackTrace);
    }
  }
}
