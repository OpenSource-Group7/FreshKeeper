import 'package:flutter/material.dart';
import 'search_screen.dart'; // 기존에 완성한 레시피 검색 스크린 경로에 맞게 지정

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // 🌟 로그인 완료 후 진입했을 때 '레시피 확인(인덱스 1)'이 켜지도록 초기값 세팅
  int _currentIndex = 1;

  // 하단 탭을 누를 때 띄워줄 화면들의 목록
  final List<Widget> _pages = [
    const Center(child: Text("📦 재고 목록 페이지 (팀원 작업 중)")), // index 0
    const RecipeSearchScreen(),                                 // index 1: 우리가 만든 화면!
    const Center(child: Text("🛒 쇼핑 목록 페이지 (팀원 작업 중)")), // index 2
    const Center(child: Text("👤 마이페이지 (팀원 작업 중)")),       // index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1B5E20), // 활성화된 탭 색상
        unselectedItemColor: Colors.grey,                  // 비활성화된 탭 색상
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: "재고 목록"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "레시피 확인"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "쇼핑 목록"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}