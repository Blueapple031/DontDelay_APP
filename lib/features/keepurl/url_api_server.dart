import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'url_connection_service.dart';
import 'url_model.dart';

typedef UrlApiAddHandler = Future<UrlAddResult> Function({
  required String url,
  required String title,
  required String source,
  String memo,
});

class UrlApiServer {
  UrlApiServer({
    required UrlConnectionService connectionService,
    required UrlApiAddHandler Function() resolveOnAddUrl,
  })  : _connectionService = connectionService,
        _resolveOnAddUrl = resolveOnAddUrl;

  final UrlConnectionService _connectionService;
  final UrlApiAddHandler Function() _resolveOnAddUrl;

  HttpServer? _server;
  UrlConnectionConfig? _config;
  String? _startError;

  UrlConnectionConfig? get config => _config;
  bool get isRunning => _server != null;
  String? get startError => _startError;

  Future<void> start() async {
    if (_server != null) return;

    _config = await _connectionService.loadOrCreate();
    final router = Router()
      ..get('/api/health', _handleHealth)
      ..post('/api/urls', _handlePostUrl);

    final handler = Pipeline()
        .addMiddleware(_corsMiddleware)
        .addHandler(router.call);

    try {
      _server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4,
        _config!.port,
      );
      _startError = null;
      debugPrint(
        'URL API server listening on http://127.0.0.1:${_config!.port}',
      );
    } catch (e) {
      _startError = e.toString();
      debugPrint('URL API server failed to start: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Response _handleHealth(Request request) {
    return _jsonResponse(
      200,
      {
        'app': 'DontDelay',
        'version': '1.0.0',
        'port': _config?.port ?? UrlConnectionConfig.defaultPort,
      },
    );
  }

  Future<Response> _handlePostUrl(Request request) async {
    final token = _extractBearer(request);
    if (token == null || token != _config?.token) {
      return _jsonResponse(401, {'message': 'unauthorized'});
    }

    String body;
    try {
      body = await request.readAsString();
    } catch (_) {
      return _jsonResponse(400, {'message': 'invalid body'});
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return _jsonResponse(400, {'message': 'invalid json'});
    }

    final url = data['url'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final source = data['source'] as String? ?? 'extension';
    final memo = data['memo'] as String? ?? '';

    if (!UrlItem.isValidSavableUrl(url)) {
      return _jsonResponse(400, {'message': 'invalid url'});
    }

    try {
      final result = await _resolveOnAddUrl()(
        url: url,
        title: title,
        source: source,
        memo: memo,
      );

      switch (result) {
        case UrlAddResult.saved:
          return _jsonResponse(201, {'message': 'saved'});
        case UrlAddResult.duplicate:
          return _jsonResponse(409, {'message': 'duplicate'});
        case UrlAddResult.invalid:
          return _jsonResponse(400, {'message': 'invalid url'});
      }
    } catch (e) {
      return _jsonResponse(500, {'message': e.toString()});
    }
  }

  String? _extractBearer(Request request) {
    final auth = request.headers['Authorization'] ??
        request.headers['authorization'];
    if (auth == null || !auth.startsWith('Bearer ')) return null;
    return auth.substring(7);
  }

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: json.encode(body),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    );
  }

  Middleware get _corsMiddleware {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: {
          ...response.headers,
          ..._corsHeaders,
        });
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  };
}
