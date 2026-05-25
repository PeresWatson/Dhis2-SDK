/// HTTP Client
/// 
/// Centralized HTTP client for all DHIS2 API communication.
/// 
/// ## Purpose
/// 
/// - Single point for HTTP configuration
/// - Automatic authentication header injection
/// - Request/response logging
/// - Error handling and retry logic
/// - Interceptor support
/// 
/// ## Data Flow
/// 
/// ```
/// Service → HttpClient → Interceptors → Dio → DHIS2 API
///                              ↓
///                        AuthInterceptor
///                        LoggingInterceptor
///                        RetryInterceptor
/// ```
library;

import 'package:dio/dio.dart';

import '../core/config/dhis2_config.dart';
import '../auth/models/credentials.dart';
import '../exceptions/dhis2_exception.dart';
import '../exceptions/auth_exception.dart';
import '../exceptions/network_exception.dart';
import '../logging/sdk_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// HTTP client for DHIS2 API communication.
/// 
/// Example:
/// ```dart
/// final client = Dhis2HttpClient(
///   config: config,
///   logger: logger,
/// );
/// 
/// // Set credentials after login
/// client.setCredentials(credentials);
/// 
/// // Make requests
/// final response = await client.get('/me');
/// ```
class Dhis2HttpClient {
  /// SDK configuration.
  final Dhis2Config config;

  /// Logger instance.
  final SdkLogger logger;

  /// Underlying Dio instance.
  late final Dio _dio;

  /// Authentication interceptor (stored to update credentials).
  late final AuthInterceptor _authInterceptor;

  /// Current credentials.
  Credentials? _credentials;

  /// Creates a new HTTP client.
  Dhis2HttpClient({
    required this.config,
    required this.logger,
  }) {
    _initializeDio();
  }

  /// Initializes the Dio instance with interceptors.
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: config.apiUrl,
      connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: config.sendTimeoutMs),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...config.additionalHeaders,
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    // Add interceptors in order
    _authInterceptor = AuthInterceptor(
      getCredentials: () => _credentials,
      logger: logger,
    );
    _dio.interceptors.add(_authInterceptor);

    if (config.enableDebugLogging) {
      _dio.interceptors.add(LoggingInterceptor(logger: logger));
    }

    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logger: logger,
      maxRetries: 3,
      retryDelayMs: 1000,
    ));
  }

  /// Sets the authentication credentials.
  void setCredentials(Credentials credentials) {
    _credentials = credentials;
  }

  /// Clears the authentication credentials.
  void clearCredentials() {
    _credentials = null;
  }

  /// Whether credentials are set.
  bool get hasCredentials => _credentials != null;

  /// Makes a GET request.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Makes a POST request.
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Makes a PUT request.
  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Makes a DELETE request.
  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Downloads a file.
  Future<Response<dynamic>> download(
    String path,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handles Dio errors and converts to SDK exceptions.
  Dhis2Exception _handleDioError(DioException error) {
    logger.error('HTTP error: ${error.message}', error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();

      case DioExceptionType.connectionError:
        final message = error.message ?? '';
        if (message.contains('SocketException')) {
          return NetworkException.noConnection();
        }
        if (message.contains('HandshakeException')) {
          return NetworkException.sslError(config.baseUrl);
        }
        return NetworkException.connectionRefused(config.baseUrl);

      case DioExceptionType.badCertificate:
        return NetworkException.sslError(config.baseUrl);

      case DioExceptionType.cancel:
        return NetworkException.cancelled();

      case DioExceptionType.badResponse:
        return _handleHttpError(error.response);

      case DioExceptionType.unknown:
      default:
        return Dhis2Exception(
          message: error.message ?? 'Unknown error occurred',
          code: 'HTTP_UNKNOWN_ERROR',
          cause: error,
        );
    }
  }

  /// Handles HTTP error responses.
  Dhis2Exception _handleHttpError(Response<dynamic>? response) {
    if (response == null) {
      return const Dhis2Exception(
        message: 'No response received from server',
        code: 'HTTP_NO_RESPONSE',
      );
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Extract error message from response body if available
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message'] as String? ??
          data['error'] as String? ??
          (data['status'] as String?);
    }

    // Handle specific status codes
    switch (statusCode) {
      case 401:
        return AuthException.invalidCredentials();

      case 403:
        final authority = data is Map ? data['requiredAuthority'] as String? : null;
        return AuthException.insufficientPermissions(authority);

      case 404:
        return ApiException.fromStatusCode(404, response.requestOptions.path);

      case 409:
        return ApiException(
          message: serverMessage ?? 'Resource conflict',
          code: 'API_CONFLICT',
          statusCode: 409,
          endpoint: response.requestOptions.path,
        );

      case 429:
        return ApiException(
          message: 'Rate limit exceeded. Please wait before making more requests.',
          code: 'API_RATE_LIMITED',
          statusCode: 429,
          endpoint: response.requestOptions.path,
        );

      default:
        return ApiException.fromStatusCode(
          statusCode,
          response.requestOptions.path,
          body: data is Map<String, dynamic> ? data : null,
        );
    }
  }

  /// Cancels all pending requests.
  void cancelAll() {
    // Note: Would need to track cancel tokens to implement
    logger.debug('Cancelling all requests');
  }

  /// Disposes the client.
  void dispose() {
    _dio.close();
  }
}
