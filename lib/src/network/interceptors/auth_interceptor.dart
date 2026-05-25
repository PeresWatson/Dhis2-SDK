import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';
import '../../logging/sdk_logger.dart';

/// Interceptor that handles authentication headers for all requests.
/// 
/// Automatically adds the appropriate authentication header based on
/// the current authentication state (Basic Auth or OAuth Bearer token).
class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final SdkLogger _logger;

  AuthInterceptor({
    required AuthService authService,
    SdkLogger? logger,
  })  : _authService = authService,
        _logger = logger ?? SdkLogger();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final credentials = await _authService.getStoredCredentials();
      
      if (credentials != null) {
        final authHeader = credentials.toAuthHeader();
        options.headers['Authorization'] = authHeader;
        
        _logger.debug(
          'Added auth header to request',
          tag: 'AuthInterceptor',
          data: {'url': options.uri.toString()},
        );
      } else {
        _logger.warning(
          'No credentials available for request',
          tag: 'AuthInterceptor',
          data: {'url': options.uri.toString()},
        );
      }
      
      handler.next(options);
    } catch (e) {
      _logger.error(
        'Error adding auth header',
        tag: 'AuthInterceptor',
        error: e,
      );
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      _logger.warning(
        'Received 401 Unauthorized - credentials may be invalid',
        tag: 'AuthInterceptor',
        data: {'url': err.requestOptions.uri.toString()},
      );
      
      // Attempt to refresh OAuth token if applicable
      final credentials = await _authService.getStoredCredentials();
      if (credentials != null && credentials.isOAuth) {
        _logger.info(
          'Attempting OAuth token refresh',
          tag: 'AuthInterceptor',
        );
        
        final refreshed = await _authService.refreshOAuthToken();
        if (refreshed) {
          // Retry the original request with new token
          try {
            final newCredentials = await _authService.getStoredCredentials();
            if (newCredentials != null) {
              err.requestOptions.headers['Authorization'] = 
                  newCredentials.toAuthHeader();
              
              final dio = Dio();
              final response = await dio.fetch(err.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (retryError) {
            _logger.error(
              'Retry after token refresh failed',
              tag: 'AuthInterceptor',
              error: retryError,
            );
          }
        }
      }
    }
    
    handler.next(err);
  }
}

/// Interceptor that adds common headers to all requests.
class CommonHeadersInterceptor extends Interceptor {
  final String? userAgent;
  final Map<String, String>? additionalHeaders;

  CommonHeadersInterceptor({
    this.userAgent,
    this.additionalHeaders,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Set content type
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    
    // Set user agent
    if (userAgent != null) {
      options.headers['User-Agent'] = userAgent;
    } else {
      options.headers['User-Agent'] = 'DHIS2-Flutter-SDK/1.0.0';
    }
    
    // Add any additional headers
    if (additionalHeaders != null) {
      options.headers.addAll(additionalHeaders!);
    }
    
    handler.next(options);
  }
}
