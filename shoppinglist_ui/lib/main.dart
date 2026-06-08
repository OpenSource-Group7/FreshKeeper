import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(primarySwatch: Colors.green),
  home: MainNavigationScreen(),
));

const String baseUrl = "http://127.0.0.1:8000";

class ShoppingItem {
  String name;
  String quantity;
  String unit;
  bool isChecked;
  ShoppingItem({required this.name, required this.quantity, required this.unit, this.isChecked = false});
}

class InventoryItem {
  String name;
  String quantity;
  String unit;
  String expiryDate;
  InventoryItem({required this.name, required this.quantity, required this.unit, required this.expiryDate});
}

class Recipe {
  String title;
  String duration;
  List<String> ingredients;
  Recipe({required this.title, required this.duration, required this.ingredients});
}

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2;
  final List<Widget> _children = [
    InventoryListScreen(),
    RecipeListScreen(),
    ShoppingListScreen(),
    MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: "재고 목록"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: "레시피 확인"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: "쇼핑 목록"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}

class InventoryListScreen extends StatefulWidget {
  @override
  _InventoryListScreenState createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  List<InventoryItem> _inventory = [];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventory'));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _inventory = data.map((e) => InventoryItem(
            name: e['재료명'] ?? '',
            quantity: (e['수량'] ?? '0').toString(),
            unit: e['단위'] ?? '',
            expiryDate: e['유통기한'] ?? '미지정',
          )).toList();
        });
      } else { _loadDummyInventory(); }
    } catch (e) { _loadDummyInventory(); }
  }

  void _loadDummyInventory() {
    setState(() {
      _inventory = [
        InventoryItem(name: "계란", quantity: "6", unit: "개", expiryDate: "2026-06-15"),
        InventoryItem(name: "대파", quantity: "1", unit: "단", expiryDate: "2026-06-08"),
        InventoryItem(name: "양파", quantity: "3", unit: "개", expiryDate: "2026-06-20"),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("우리집 냉장고 (재고)", style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        actions: [IconButton(icon: Icon(Icons.refresh, color: Colors.green[900]), onPressed: _fetchInventory)],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(15),
        itemCount: _inventory.length,
        itemBuilder: (context, index) {
          final item = _inventory[index];
          return Card(
            elevation: 1,
            margin: EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green[50], child: Icon(Icons.restaurant, color: Colors.green)),
              title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("유통기한: ${item.expiryDate}"),
              trailing: Text("${item.quantity} ${item.unit}", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          );
        },
      ),
    );
  }
}

class RecipeListScreen extends StatefulWidget {
  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<Recipe> _recipes = [];

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recipes'));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _recipes = data.map((e) => Recipe(
            title: e['요리명'] ?? '',
            duration: e['소요시간'] ?? '',
            ingredients: List<String>.from(e['필요재료'] ?? []),
          )).toList();
        });
      } else { _loadDummyRecipes(); }
    } catch (e) { _loadDummyRecipes(); }
  }

  void _loadDummyRecipes() {
    setState(() {
      _recipes = [
        Recipe(title: "김치찌개", duration: "25분", ingredients: ["김치 1/4포기", "돼지고기 200g", "두부 1모", "대파 1/2대"]),
        Recipe(title: "초간단 계란볶음밥", duration: "10분", ingredients: ["밥 1공기", "계란 2개", "대파 1/3대", "간장 1스푼"]),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("추천 레시피", style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(15),
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ExpansionTile(
              leading: Icon(Icons.menu_book, color: Colors.orange),
              title: Text(recipe.title, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("소요 시간: ${recipe.duration}"),
              children: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🍳 필요 재료", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                      SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: recipe.ingredients.map((ing) => Chip(
                          label: Text(ing, style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey[100],
                        )).toList(),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  String _selectedUnit = "개";
  final List<String> _unitList = ["개", "kg", "g", "ml", "모", "팩"];
  List<ShoppingItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // 삭제 확인 다이얼로그 헬퍼 함수
  void _showDeleteConfirmDialog({required VoidCallback onConfirm, String message = "정말 삭제하시겠습니까?"}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("삭제 확인"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/shopping-list'));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _items = data.map((e) {
            return ShoppingItem(
              name: (e['재료명'] ?? '이름없음').toString(),
              quantity: (e['최종수량'] ?? '0').toString(),
              unit: (e['단위'] ?? '').toString(),
            );
          }).toList();
        });
      }
    } catch (e) { print("데이터 매칭 에러: $e"); }
  }

  Future<void> _addItem() async {
    if (_nameController.text.isNotEmpty && _qtyController.text.isNotEmpty) {
      await http.post(
        Uri.parse('$baseUrl/shopping-list/add'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"재료": _nameController.text, "수량": double.parse(_qtyController.text), "단위": _selectedUnit}),
      );
      _nameController.clear();
      _qtyController.clear();
      _fetchItems();
    }
  }

  Future<void> _generateListFromUrl() async {
    if (_urlController.text.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-shopping-list?youtube_url=${Uri.encodeComponent(_urlController.text)}'),
      );
      if (response.statusCode == 200) {
        _fetchItems();
        _urlController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("레시피가 분석되었습니다!")));
      }
    } catch (e) { print("URL 분석 실패: $e"); }
  }

  Future<void> _deleteItem(String name) async {
    await http.delete(Uri.parse('$baseUrl/shopping-list/$name'));
    _fetchItems();
  }

  Future<void> _updateItem(String name, String newQty) async {
    await http.put(Uri.parse('$baseUrl/shopping-list/$name?new_quantity=$newQty'));
    _fetchItems();
  }

  void _showEditDialog(int index) {
    TextEditingController _editQtyController = TextEditingController(text: _items[index].quantity);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("수량 수정"),
        content: TextField(controller: _editQtyController, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
          ElevatedButton(onPressed: () { _updateItem(_items[index].name, _editQtyController.text); Navigator.pop(context); }, child: Text("확인")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("쇼핑리스트", style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        leading: Icon(Icons.menu, color: Colors.green[900]),
        actions: [Padding(padding: EdgeInsets.only(right: 15), child: Icon(Icons.search, color: Colors.green[900]))],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Container(height: 120, width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade800]), borderRadius: BorderRadius.circular(15)), alignment: Alignment.bottomLeft, padding: EdgeInsets.all(20), child: Text("오늘의 장보기", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
            SizedBox(height: 15),

            Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.shade100)), child: Column(children: [Row(children: [Icon(Icons.video_library, color: Colors.red), SizedBox(width: 5), Text("유튜브 레시피 분석", style: TextStyle(fontWeight: FontWeight.bold))]), TextField(controller: _urlController, decoration: InputDecoration(hintText: "유튜브 URL 입력")), SizedBox(height: 10), SizedBox(width: double.infinity, height: 45, child: ElevatedButton(onPressed: _generateListFromUrl, child: Text("자동으로 재료 추가"), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white)))])),
            SizedBox(height: 15),

            Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [Row(children: [Icon(Icons.shopping_cart, color: Colors.green), SizedBox(width: 5), Text("품목 추가하기", style: TextStyle(fontWeight: FontWeight.bold))]), TextField(controller: _nameController, decoration: InputDecoration(hintText: "무엇을 살까요?")), SizedBox(height: 10), Row(children: [Expanded(flex: 2, child: TextField(controller: _qtyController, decoration: InputDecoration(hintText: "수량"), keyboardType: TextInputType.number)), SizedBox(width: 10), Expanded(flex: 1, child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: _selectedUnit, items: _unitList.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setState(() => _selectedUnit = v!)))),]), SizedBox(height: 15), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _addItem, child: Text("리스트에 담기"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),])),
            SizedBox(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("구매 목록 (${_items.length})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton(onPressed: () => _showDeleteConfirmDialog(
                  message: "모든 항목을 삭제하시겠습니까?",
                  onConfirm: () => setState(() => _items.clear())
              ), child: Text("전체 삭제", style: TextStyle(color: Colors.green)))
            ]),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    onTap: () => _showEditDialog(index),
                    leading: Checkbox(
                      value: item.isChecked,
                      onChanged: (v) => setState(() => item.isChecked = v!),
                    ),
                    title: Text(item.name),
                    subtitle: Text("${item.quantity} ${item.unit}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmDialog(
                          onConfirm: () => _deleteItem(item.name)
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MyPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("마이페이지", style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(radius: 45, backgroundColor: Colors.green[100], child: Icon(Icons.person, size: 50, color: Colors.green[700])),
                  SizedBox(height: 10),
                  Text("스마트 요리사 님", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("cook_master@example.com", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(leading: Icon(Icons.favorite, color: Colors.red), title: Text("즐겨찾는 레시피"), trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(leading: Icon(Icons.history, color: Colors.blue), title: Text("유튜브 분석 히스토리"), trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(leading: Icon(Icons.settings, color: Colors.grey), title: Text("설정 및 알림"), trailing: Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}