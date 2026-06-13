import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. 로컬 저장소 패키지 가져오기
import '../services/api_service.dart';
import 'home_screen.dart'; // 로그인 성공 후 이동할 홈 화면 가져오기

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _HomeScreenState {
  // 상태 클래스 이름이 일치해야 하므로 기본 구조를 유지합니다.
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final ApiService _apiService = ApiService(); // API 서비스 객체 생성

  // 🌟 [추가된 핵심 함수] 로그인 처리를 전담하는 함수
  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("아이디와 비밀번호를 모두 입력해주세요.")),
      );
      return;
    }

    // 백엔드 API 서버에 로그인 요청 (토큰 받아오기)
    String? token = await _apiService.login(username, password);

    if (token != null) {
      // 로그인 성공 시 shared_preferences 저장소에 회원 정보 쏙 저장하기!
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('token', token);

      // 메인 홈 화면으로 이동하면서, 이전 로그인 화면 기록은 싹 지우기
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } else {
      // 로그인 실패 시 브라우저 하단에 에러 알림창 띄우기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인 정보가 올바르지 않습니다. 다시 확인해주세요.")),
        );
      }
    }
  }

  // 🌟 [추가된 핵심 함수] 회원가입 처리를 전담하는 함수
  void _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (username.isEmpty || password.isEmpty || nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 빈칸을 채워주세요.")),
      );
      return;
    }

    // 백엔드 API 서버에 회원가입 요청
    bool isSuccess = await _apiService.register(username, password, nickname);

    if (isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입이 완료되었습니다! 로그인을 진행해주세요.")),
        );
      }
      // 가입 성공 후 로그인 모드로 자동 전환
      setState(() {
        isLogin = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입 실패! 이미 존재하는 아이디일 수 있습니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("계정 관리", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 버튼 흰색 고정
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "FreshKeeper",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "아이디"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "비밀번호"),
              ),
              if (!isLogin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: "닉네임"),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // 🌟 버튼을 눌렀을 때 현재 상태(로그인/회원가입)에 맞춰 진짜 백엔드 통신 함수 작동!
                    if (isLogin) {
                      _handleLogin();
                    } else {
                      _handleRegister();
                    }
                  },
                  child: Text(isLogin ? "로그인" : "회원가입"),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? "계정이 없으신가요? 회원가입" : "이미 계정이 있으신가요? 로그인",
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}