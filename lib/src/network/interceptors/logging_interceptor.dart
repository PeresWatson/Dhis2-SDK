import 'package:dio/dio.dart';
import '../../logging/sdk_logger.dart';
import '../../logging/log_level.dart';

/// Interceptor that logs all HTTP requests and responses.
/// 
/// Provides detailed logging for debugging purposes with configurable
/// verbosity levels.
class LoggingInterceptor extends Interceptor {
  final SdkLogger _logger;
  final bool logRequestBody;
  final bool logResponseBody;
  final bool logHeaders;
  final int maxBodyLength;

  LoggingInterceptor({
    SdkLogger? logger,
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.logHeaders = false,
    this.maxBodyLength = 1000,
  }) : _logger = logger ?? SdkLogger();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('╔══════════════════════════════════════════════════════════');
    buffer.writeln('║ REQUEST');
    buffer.writeln('╠══════════════════════════════════════════════════════════');
    buffer.writeln('║ ${options.method} ${options.uri}');
    
    if (logHeaders && options.headers.isNotEmpty) {
      buffer.writeln('║ Headers:');
      options.headers.forEach((key, value) {
        // Mask sensitive headers
        final maskedValue = _maskSensitiveHeader(key, value.toString());
        buffer.writeln('║   $key: $maskedValue');
      });
    }
    
    if (logRequestBody && options.data != null) {
      buffer.writeln('║ Body:');
      final bodyString = _truncateBody(options.data.toString());
      buffer.writeln('║   $bodyString');
    }
    
    buffer.writeln('╚══════════════════════════════════════════════════════════');
    
    _logger.debug(buffer.toString(), tag: 'HTTP');
    
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('╔══════════════════════════════════════════════════════════');
    buffer.writeln('║ RESPONSE');
    buffer.writeln('╠══════════════════════════════════════════════════════════');
    buffer.writeln('║ ${response.statusCode} ${response.statusMessage}');
    buffer.writeln('║ ${response.requestOptions.method} ${response.requestOptions.uri}');
    buffer.writeln('║ Duration: ${_calculateDuration(response.requestOptions)}');
    
    if (logHeaders && response.headers.map.isNotEmpty) {
      buffer.writeln('║ Headers:');
      response.headers.forEach((key, values) {
        buffer.writeln('║   $key: ${values.join(", ")}');
      });
    }
    
    if (logResponseBody && response.data != null) {
      buffer.writeln('║ Body:');
      final bodyString = _truncateBody(response.data.toString());
      buffer.writeln('║   $bodyString');
    }
    
    buffer.writeln('╚══════════════════════════════════════════════════════════');
    
    _logger.debug(buffer.toString(), tag: 'HTTP');
    
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('╔══════════════════════════════════════════════════════════');
    buffer.writeln('║ ERROR');
    buffer.writeln('╠══════════════════════════════════════════════════════════');
    buffer.writeln('║ ${err.type}');
    buffer.writeln('║ ${err.requestOptions.method} ${err.requestOptions.uri}');
    buffer.writeln('║ Message: ${err.message}');
    
    if (err.response != null) {
      buffer.writeln('║ Status: ${err.response?.statusCode}');
      if (logResponseBody && err.response?.data != null) {
        buffer.writeln('║ Response Body:');
        final bodyString = _truncateBody(err.response?.data.toString() ?? '');
        buffer.writeln('║   $bodyString');
      }
    }
    
    buffer.writeln('╚══════════════════════════════════════════════════════════');
    
    _logger.error(buffer.toString(), tag: 'HTTP', error: err);
    
    handler.next(err);
  }

  String _truncateBody(String body) {
    if (body.length <= maxBodyLength) {
      return body;
    }
    return '${body.substring(0, maxBodyLength)}... [truncated]';
  }

  String _maskSensitiveHeader(String key, String value) {
    final sensitiveHeaders = ['authorization', 'cookie', 'set-cookie'];
    if (sensitiveHeaders.contains(key.toLowerCase())) {
      if (value.length > 10) {
        return '${value.substring(0, 10)}...[masked]';
      }
      return '[masked]';
    }
    return value;
  }

  String _calculateDuration(RequestOptions options) {
    // This is a simplified duration - for accurate timing,
    // you would need to store the start time in request extras
    return 'N/A';
  }
}

/// A more compact logging interceptor for production use.
class CompactLoggingInterceptor extends Interceptor {
  final SdkLogger _logger;

  CompactLoggingInterceptor({SdkLogger? logger}) 
      : _logger = logger ?? SdkLogger();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _logger.info(
      '→ ${options.method} ${options.uri}',
      tag: 'HTTP',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.info(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      tag: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _logger.error(
      '✗ ${err.response?.statusCode ?? err.type} ${err.requestOptions.uri}',
      tag: 'HTTP',
      error: err,
    );
    handler.next(err);
  }
}
