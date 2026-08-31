import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Single entry point for every Gemini `generateContent` request.
///
/// Two modes, chosen by whether `GEMINI_PROXY_URL` is set in `.env`:
///
/// * **Proxied (recommended).** Calls a Supabase Edge Function that holds the
///   API key server-side — see `supabase/functions/gemini/`. Nothing secret
///   ships in the app.
/// * **Direct (demo fallback).** Calls Google with `GEMINI_API_KEY` taken from
///   the bundled `.env`. That key is extractable from the APK by anyone who
///   unzips it, and it is billable — acceptable for a local demo, not for a
///   build you hand out.
class GeminiClient {
  static const model = 'gemini-2.5-flash';

  static String get _proxyUrl => dotenv.env['GEMINI_PROXY_URL']?.trim() ?? '';

  /// Whether requests go through the server-side proxy rather than carrying a
  /// client-side API key.
  static bool get usesProxy => _proxyUrl.isNotEmpty;

  /// POSTs [body] as a `generateContent` request and returns the raw response.
  ///
  /// The response shape is identical in both modes — the proxy passes Gemini's
  /// JSON through untouched — so callers parse it the same way either way.
  static Future<http.Response> generateContent(
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 60),
  }) {
    if (usesProxy) {
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      return http
          .post(
            Uri.parse(_proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              // Edge Functions verify this JWT before running.
              'Authorization': 'Bearer $anonKey',
              'apikey': anonKey,
            },
            body: jsonEncode({'model': model, 'payload': body}),
          )
          .timeout(timeout);
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini is not configured: set GEMINI_PROXY_URL (preferred) or '
        'GEMINI_API_KEY in .env',
      );
    }

    return http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/'
            '$model:generateContent?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }
}
