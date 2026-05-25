import 'package:dio/dio.dart';
import '../../logging/sdk_logger.dart';
import '../../exceptions/network_exception.dart';

/// Interceptor that handles automatic request retrying on transient failures.
/// 
/// Implements exponential backoff with configurable retry counts and delays.
class RetryInterceptor extends Interceptor {
  final SdkLogger _logger;
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Set<int> retryStatusCodes;
  final Set<DioExceptionType> retryExceptionTypes;

  /// Header key to track retry count
  static const String retryCountHeader = 'X-Retry-Count';

  RetryInterceptor({
    SdkLogger? logger,
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    Set<int>? retryStatusCodes,
    Set<DioExceptionType>? retryExceptionTypes,
  })  : _logger = logger ?? SdkLogger(),
        retryStatusCodes = retryStatusCodes ?? {408, 429, 500, 502, 503, 504},
        retryExceptionTypes = retryExceptionTypes ?? {
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        };

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = _getRetryCount(err.requestOptions);
    
    if (retryCount >= maxRetries) {
      _logger.warning(
        'Max retries ($maxRetries) reached for ${err.requestOptions.uri}',
        tag: 'RetryInterceptor',
      );
      handler.next(err);
      return;
    }

    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final delay = _calculateDelay(retryCount);
    
    _logger.info(
      'Retrying request (${retryCount + 1}/$maxRetries) after ${delay.inMilliseconds}ms',
      tag: 'RetryInterceptor',
      data: {'url': err.requestOptions.uri.toString()},
    );

    await Future.delayed(delay);

    try {
      // Clone the request options and increment retry count
      final newOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          retryCountHeader: (retryCount + 1).toString(),
        },
      );

      final dio = Dio();
      final response = await dio.fetch(newOptions);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        // Pass to next iteration of retry logic
        onError(e, handler);
      } else {
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: e,
            type: DioExceptionType.unknown,
          ),
        );
      }
    }
  }

  int _getRetryCount(RequestOptions options) {
    final retryHeader = options.headers[retryCountHeader];
    if (retryHeader != null) {
      return int.tryParse(retryHeader.toString()) ?? 0;
    }
    return 0;
  }

  bool _shouldRetry(DioException err) {
    // Check exception type
    if (retryExceptionTypes.contains(err.type)) {
      return true;
    }

    // Check status code
    final statusCode = err.response?.statusCode;
    if (statusCode != null && retryStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  Duration _calculateDelay(int retryCount) {
    final multiplier = backoffMultiplier;
    final delayMs = initialDelay.inMilliseconds * 
        (multiplier == 1 ? 1 : (1 << retryCount)); // Exponential backoff
    
    // Add jitter to prevent thundering herd
    final jitter = (delayMs * 0.1 * (DateTime.now().millisecond / 1000)).round();
    
    return Duration(milliseconds: delayMs + jitter);
  }
}

/// Extension to add retry-specific options to RequestOptions
extension RequestOptionsRetryExtension on RequestOptions {
  RequestOptions copyWith({
    String? method,
    String? path,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, dynamic>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    return RequestOptions(
      method: method ?? this.method,
      path: path ?? this.path,
      baseUrl: baseUrl,
      queryParameters: queryParameters ?? this.queryParameters,
      data: data ?? this.data,
      headers: headers ?? this.headers,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      extra: extra,
      responseType: responseType,
      contentType: contentType,
      validateStatus: validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      persistentConnection: persistentConnection,
      listFormat: listFormat,
    );
  }
}
