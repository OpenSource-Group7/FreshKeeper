import 'package:flutter/material.dart';
import '../../constants.dart';
import 'inventory_screen.dart';
import 'recipe_screen.dart';
import 'shopping_screen.dart';
import 'my_page_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String jwtToken;
  const MainNavigationScreen({super.key, required this.jwtToken});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
  InventoryScreen(jwtToken: widget.jwtToken),
  RecipeRecommendScreen(),
  ShoppingListScreen(jwtToken: widget.jwtToken),
  MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE7E8E9)))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: kSurface,
          selectedItemColor: kPrimary,
          unselectedItemColor: kTextSub,
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: '재고 목록'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '레시피 확인'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '쇼핑 목록'),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '마이페이지'),
          ],
        ),
      ),
    );
  }
}