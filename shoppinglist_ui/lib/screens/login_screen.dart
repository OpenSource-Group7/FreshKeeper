import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../services/api_service.dart';
import 'main_navigation.dart';

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
  final ApiService _api = ApiService();

  void _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _snack("아이디와 비밀번호를 입력해주세요.");
      return;
    }

    if (isRegisterMode) {
      if (nickname.isEmpty) return _snack("닉네임을 입력해주세요.");
      bool ok = await _api.register(username, password, nickname);
      if (ok) {
        _snack("회원가입 완료! 로그인해주세요.");
        setState(() => isRegisterMode = false);
      } else {
        _snack("회원가입 실패. 이미 존재하는 아이디일 수 있습니다.");
      }
    } else {
      String? token = await _api.login(username, password);
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('token', token);
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => MainNavigationScreen()));
      } else {
        _snack("로그인 정보가 올바르지 않습니다.");
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.kitchen, color: kPrimary, size: 60),
              const SizedBox(height: 12),
              const Text("FreshKeeper",
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: kPrimary)),
              const SizedBox(height: 8),
              const Text("식재료 스마트 관리",
                  style: TextStyle(color: kTextSub, fontSize: 14)),
              const SizedBox(height: 40),
              _field(_usernameController, "아이디"),
              const SizedBox(height: 12),
              _field(_passwordController, "비밀번호", obscure: true),
              if (isRegisterMode) ...[
                const SizedBox(height: 12),
                _field(_nicknameController, "닉네임"),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _handleAuth,
                  child: Text(isRegisterMode ? "회원가입" : "로그인",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () {
                  _usernameController.clear();
                  _passwordController.clear();
                  _nicknameController.clear();
                  setState(() => isRegisterMode = !isRegisterMode);
                },
                child: Text(
                    isRegisterMode
                        ? "이미 계정이 있으신가요? 로그인하기"
                        : "처음이신가요? 회원가입하기",
                    style: const TextStyle(color: kPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF3F4F5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}