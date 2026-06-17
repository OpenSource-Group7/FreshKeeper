import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import 'login_screen.dart';

class MyPageScreen extends StatefulWidget {
  MyPageScreen({super.key});
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username'));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("마이페이지",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5)),
        actions: [
          if (_username != null)
            IconButton(
                icon: const Icon(Icons.logout),
                tooltip: "로그아웃",
                onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // 프로필
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: kPrimary.withOpacity(0.1),
                child: const Icon(Icons.person, size: 50, color: kPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                _username != null ? "$_username 님" : "로그인이 필요합니다",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: kTextMain),
              ),
              const SizedBox(height: 4),
              Text(
                _username != null ? "로그인 상태" : "아래 버튼으로 로그인하세요",
                style: const TextStyle(color: kTextSub, fontSize: 14),
              ),
              if (_username == null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()))
                        .then((_) => _load()),
                    child: const Text("로그인 / 회원가입",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 20),

          // 메뉴
          Container(
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(children: [
              _menuTile(Icons.favorite, kError, "즐겨찾는 레시피"),
              const Divider(height: 1, color: kBorder),
              _menuTile(Icons.history, Colors.blueAccent, "유튜브 분석 히스토리"),
              const Divider(height: 1, color: kBorder),
              _menuTile(Icons.notifications_outlined, kWarning, "알림 설정"),
              const Divider(height: 1, color: kBorder),
              _menuTile(Icons.settings_outlined, kTextSub, "설정"),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _menuTile(IconData icon, Color color, String title) => ListTile(
    leading: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.w500, color: kTextMain, fontSize: 15)),
    trailing: const Icon(Icons.chevron_right, color: kTextSub),
    onTap: () {},
  );
}