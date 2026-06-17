import 'package:flutter/material.dart';
import '../services/api_service.dart'; //경로에 맞게 임포트
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool isRegisterMode = false;

  final ApiService _apiService = ApiService();

  void _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("아이디와 비밀번호를 입력해주세요.");
      return;
    }

    if (isRegisterMode) {
      // 1. 회원가입 로직 전환
      if (nickname.isEmpty) return _showSnackBar("닉네임을 입력해주세요.");
      bool success = await _apiService.register(username, password, nickname);
      if (success) {
        _showSnackBar("회원가입 성공! 로그인 해주세요.");
        setState(() => isRegisterMode = false);
      } else {
        _showSnackBar("회원가입 실패 (아이디 중복 등)");
      }
    } else {
      // 2. 로그인 로직 전환
      String? token = await _apiService.login(username, password);

      if (token != null) {
        _showSnackBar("로그인 성공!");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        }
      } else {
        _showSnackBar("아이디 또는 비밀번호가 올바르지 않습니다.");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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