import 'package:dio/dio.dart';
import 'dart:convert';
import '../../constants.dart';

class ApiService {
  final Dio _dio = Dio();
  static String? _accessToken;
  static const _headers = {"Content-Type": "application/json"};

  // 1. 회원가입 API 연동
  Future<bool> register(String username, String password, String nickname) async {
    try {
      final response = await _dio.post(
        "$baseUrl/register",
        options: Options(headers: _headers),
        data: {
          "username": username,
          "password": password,
          "nickname": nickname,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("회원가입 에러: $e");
      return false;
    }
  }

  // 2. 로그인 API 연동
  Future<String?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        "$baseUrl/login",
        options: Options(headers: _headers),
        data: {
          "username": username,
          "password": password,
        },
      );
      if (response.statusCode == 200) {
        _accessToken = response.data["access_token"];
        return _accessToken;
      }
      return null;
    } catch (e) {
      print("로그인 에러: $e");
      return null;
    }
  }

  // 3. 레시피 검색 API 연동
  Future<List<dynamic>> searchRecipes(String dish) async {
    try {
      final response = await _dio.get(
        "$baseUrl/search-recipes",
        queryParameters: {"dish": dish},
      );
      if (response.statusCode == 200) {
        if (response.data is Map && response.data["youtube_results"] != null) {
          return response.data["youtube_results"] ?? [];
        }
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("레시피 검색 에러: $e");
      return [];
    }
  }

  // 4. 재료 기반 요리 추천 API 연동
  Future<Map<String, dynamic>?> recommendRecipes() async {
    try {
      final response = await _dio.get(
        "$baseUrl/recommend-recipe",
        options: Options(
          headers: {
            ..._headers,
            "Authorization": "Bearer $_accessToken",
          },
        ),
      );
      if (response.statusCode == 200) {
        if (response.data is Map && response.data["recommendations"] != null) {
          return response.data["recommendations"] as Map<String, dynamic>?;
        }
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("재료 기반 요리 추천 에러: $e");
      return null;
    }
  }
}