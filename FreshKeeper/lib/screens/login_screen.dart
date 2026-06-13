import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController(); // 회원가입용

  bool isRegisterMode = false; // 로그인/회원가입 모드 스위치
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://localhost:8000")); // 웹 환경 기준 주소

  void _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("아이디와 비밀번호를 입력해주세요.");
      return;
    }

    try {
      if (isRegisterMode) {
        //회원가입
        if (nickname.isEmpty) return _showSnackBar("닉네임을 입력해주세요.");
        final response = await _dio.post("/register", data: {
          "username": username,
          "password": password,
          "nickname": nickname,
        });
        _showSnackBar(response.data["message"] ?? "회원가입 성공!");
        setState(() => isRegisterMode = false); // 가입 성공 시 로그인 모드로 복귀
      } else {
        //로그인 가동
        final response = await _dio.post("/login", data: {
          "username": username,
          "password": password,
        });

        // JWT 토큰 획득 성공 시 메인 화면으로 이동
        if (response.statusCode == 200) {
          String token = response.data["access_token"];


          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        }
      }
    } catch (e) {
      _showSnackBar("인증 실패: 아이디 혹은 비밀번호를 확인하세요.");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1B5E20); // 팀의 초록색 테마 컬러

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "FreshKeeper",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "아이디"),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호"),
              ),
              if (isRegisterMode)
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: "닉네임"),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _handleAuth,
                child: Text(isRegisterMode ? "회원가입" : "로그인", style: const TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => isRegisterMode = !isRegisterMode),
                child: Text(isRegisterMode ? "이미 계정이 있으신가요? 로그인하기" : "처음이신가요? 회원가입하기", style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}