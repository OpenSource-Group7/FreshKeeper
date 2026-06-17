import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // 에뮬레이터에서 내 컴퓨터(로컬 서버)에 접속하기 위한 주소 (FastAPI 기본 포트 8000)
  final String baseUrl = kIsWeb
      ? "http://localhost:8000" // Chrome 브라우저로 실행했을 때
      : "http://10.0.2.2:8000";
  final Dio _dio = Dio();
  static String? _accessToken;

  // 1. 회원가입 API 연동
  Future<bool> register(String username, String password,
      String nickname) async {
    try {
      final response = await _dio.post(
        "$baseUrl/register",
        data: {
          "username": username,
          "password": password,
          "nickname": nickname,
        },
      );
      return response.statusCode == 200;
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
        data: {
          "username": username,
          "password": password,
        },
      );
      if (response.statusCode == 200) {
        _accessToken = response.data["access_token"]; // 토큰 저장
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
        return response.data["youtube_results"] ?? [];
      }
      return [];
    } catch (e) {
      print("레시피 검색 에러: $e");
      return [];
    }
  }

  // 4. 재료 기반 요리 추천
  Future<Map<String, dynamic>?> recommendRecipes() async {
    try {
      final response = await _dio.get(
        "$baseUrl/recommend-recipe",
        options: Options(
          headers: {
            "Authorization": "Bearer $_accessToken",
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.data["recommendations"] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("재료 기반 요리 추천 에러: $e");
      return null;
    }
  }
}