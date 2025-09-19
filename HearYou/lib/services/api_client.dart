import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

class ApiClient {
  static const String apiBase = AppConfig.apiBase;

  Future<Map<String, dynamic>> getJson(String path) async {
    final resp = await http.get(Uri.parse('$apiBase$path'));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('GET $path failed (${resp.statusCode})');
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('POST $path failed (${resp.statusCode})');
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) async {
    final resp = await http.patch(
      Uri.parse('$apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('PATCH $path failed (${resp.statusCode})');
  }
}


