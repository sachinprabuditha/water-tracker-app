import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Client for the H2Go backend (the `water-tracker-api` service).
///
/// The base URL is set at build time:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// When it is empty, [configured] is false and every API-backed feature hides
/// itself, so the app stays fully usable without a backend.
///
/// See "Backend API contract" in README.md for the request/response shapes.
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = (baseUrl ?? const String.fromEnvironment('API_BASE_URL'))
            .replaceAll(RegExp(r'/+$'), ''),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  static const _timeout = Duration(seconds: 6);

  bool get configured => baseUrl.isNotEmpty;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Today's hydration tip, or null if the API is not configured, offline,
  /// or returns anything unexpected. Never throws.
  Future<String?> todayTip() async {
    if (!configured) return null;
    try {
      final res = await _http.get(_uri('/v1/tips/today')).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final text = body is Map ? body['text'] : null;
      if (text is! String || text.trim().isEmpty) return null;
      return text.trim();
    } catch (e) {
      debugPrint('Tip fetch failed: $e');
      return null;
    }
  }

  /// Sends feedback from the Settings screen. Returns true when the server
  /// accepted it. Never throws.
  Future<bool> sendFeedback({
    required String category,
    required String message,
  }) async {
    if (!configured) return false;
    try {
      final res = await _http
          .post(
            _uri('/v1/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'category': category,
              'message': message,
              'platform': defaultTargetPlatform.name,
            }),
          )
          .timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('Feedback send failed: $e');
      return false;
    }
  }
}
