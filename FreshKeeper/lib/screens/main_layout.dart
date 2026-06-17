import 'package:flutter/material.dart';
import 'recommend_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // 로그인 완료 후 진입했을 때 '재료기반 요리 추천(인덱스 1)'이 켜지도록 초기값 세팅
  int _currentIndex = 1;

  String? _selectedDishName;

  void _onDishSelectedFromRecommend(String dishName) {
    setState(() {
      _selectedDishName = dishName; // 요리 이름 저장
      _currentIndex = 2;            // 레시피 검색 탭(인덱스 2)으로 즉시 이동
    });
  }

  // 하단 탭을 누를 때 띄워줄 화면들의 목록
  final List<Widget> _pages = [
    const Center(child: Text("📦 재고 목록 페이지 (팀원 작업 중)")), // index 0
    const RecipeRecommendScreen(), // index 1. 재료기반추천
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
            if (index != 2) {
              _selectedDishName = null;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1B5E20), // 활성화된 탭 색상
        unselectedItemColor: Colors.grey,                  // 비활성화된 탭 색상
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: "재고 목록"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "레시피 추천"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "쇼핑 목록"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}