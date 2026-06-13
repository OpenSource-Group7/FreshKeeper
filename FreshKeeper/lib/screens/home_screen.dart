import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. 임포트 추가
import 'auth_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? loggedInUser; // 로그인한 유저 아이디를 저장할 변수

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // 화면이 켜질 때 로그인 상태 체크!
  }

  // 로컬 저장소에서 로그인 정보를 읽어오는 함수
  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 'username' 키로 저장된 값이 있으면 가져오고, 없으면 null
      loggedInUser = prefs.getString('username');
    });
  }

  // 로그아웃 함수 (테스트 편의를 위해 추가)
  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('token');
    setState(() {
      loggedInUser = null; // 상단 UI가 즉시 "로그인을 해주세요"로 변경됨
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("FreshKeeper", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          // 로그인된 상태일 때만 우측 상단에 로그아웃 버튼 표시
          if (loggedInUser != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _handleLogout,
              tooltip: "로그아웃",
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 [요청사항 반영] 로그인 상태에 따른 문구 분기 처리!
            Text(
              loggedInUser != null ? "$loggedInUser님 반가워요! 👋" : "로그인을 해주세요 👋",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF191C1D)),
            ),
            const SizedBox(height: 8),
            Text(
              loggedInUser != null
                  ? ""
                  : "서비스를 이용하시려면 먼저 로그인을 진행해주세요.",
              style: const TextStyle(fontSize: 14, color: Color(0xFF40493D)),
            ),
            const SizedBox(height: 32),

            _buildMenuCard(
              context,
              title: "계정 관리",
              subtitle: loggedInUser != null ? "현재 로그인 상태입니다." : "로그인 및 회원가입 화면으로 이동",
              icon: Icons.account_circle_outlined,
              color: primaryColor,
              targetScreen: const AuthScreen(),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              title: "레시피 검색",
              subtitle: "유튜브에서 요리법을 빠르게 검색",
              icon: Icons.search_rounded,
              color: primaryColor,
              targetScreen: const RecipeSearchScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Widget targetScreen,
      }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: Color(0xFFE1E3E4), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // 화면에 다녀온 후 로그인 상태가 바뀌었을 수 있으므로 await 후 상태 갱신
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
          _checkLoginStatus(); // 돌아왔을 때 로그인 문구 새로고침 역할
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}