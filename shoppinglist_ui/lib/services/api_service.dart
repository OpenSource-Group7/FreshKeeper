import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants.dart';

class ApiService {
  static const _headers = {"Content-Type": "application/json"};

  Future<String?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: json.encode({"username": username, "password": password}),
      );
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes))["access_token"];
      }
    } catch (_) {}
    return null;
  }

  Future<bool> register(String username, String password, String nickname) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: json.encode({
          "username": username,
          "password": password,
          "nickname": nickname,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {}
    return false;
  }

  Future<List<dynamic>> searchRecipes(String query) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/search-recipes?q=${Uri.encodeComponent(query)}'),
      );
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }
}