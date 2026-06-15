import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

void main() => runApp(const FreshKeeperApp());

class FreshKeeperApp extends StatelessWidget {
  const FreshKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshKeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFF0E6E20),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0E6E20),
          primaryContainer: Color(0xFF5CB35C),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFEDEEEF),
          error: Color(0xFFBA1A1A),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class Ingredient {
  final int? id;
  final String name;
  final DateTime expiryDate;
  final DateTime useByDate;
  final double quantity;
  final String unit;
  final String category;
  final String status;
  final double progress;

  Ingredient({
    this.id,
    required this.name,
    required this.expiryDate,
    required this.useByDate,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.status,
    required this.progress,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InventoryScreen(),
    const DummyPlaceholder(title: "레시피 확인", icon: Icons.auto_awesome, info: "보유 중인 식재료 기반 맞춤형 유튜브/블로그 레시피 자동 매칭 내역"),
    const DummyPlaceholder(title: "쇼핑 목록", icon: Icons.shopping_bag, info: "부족한 식재료 분석 결과를 기반으로 산출된 마크다운 내보내기 리스트"),
    const DummyPlaceholder(title: "마이페이지", icon: Icons.person, info: "소프트 딜리트(Soft Delete) 축적 데이터 기반 소진 패턴 및 정기 구매 추천 설정"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE7E8E9), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFFFFFF),
          selectedItemColor: const Color(0xFF0E6E20),
          unselectedItemColor: const Color(0xFF707A6C),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
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

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DateTime _currentDate = DateTime(2026, 05, 21);

  late List<Ingredient> _rawDatabaseItems;
  List<Ingredient> _processedDisplayItems = [];
  String _selectedCategory = '전체';
  bool _isLoading = false;

  String _realRawReceiptText = "인식된 영수증 데이터가 없습니다.";
  List<String> _lastDetectedNames = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _rawDatabaseItems = [
      Ingredient(id: 61, name: '당근', expiryDate: DateTime(2026, 05, 22), useByDate: DateTime(2026, 05, 22), quantity: 2, unit: '개', category: '실온', status: 'NORMAL', progress: 0.95),
      Ingredient(id: 62, name: '서울우유 900ml', expiryDate: DateTime(2026, 04, 09), useByDate: DateTime(2026, 04, 09), quantity: 450, unit: 'ml', category: '냉장', status: 'NORMAL', progress: 0.65),
      Ingredient(id: 63, name: '양파', expiryDate: DateTime(2026, 06, 04), useByDate: DateTime(2026, 06, 04), quantity: 5, unit: '개', category: '실온', status: 'NORMAL', progress: 0.35),
      Ingredient(id: 64, name: '브로콜리', expiryDate: DateTime(2026, 06, 15), useByDate: DateTime(2026, 06, 15), quantity: 1, unit: '팩', category: '냉장', status: 'NORMAL', progress: 0.15),
    ];
    _executeBackendPipeline();
  }

  void _executeBackendPipeline() {
    List<Ingredient> pipelineList = [];

    for (var item in _rawDatabaseItems) {
      DateTime computedUseBy = item.useByDate;

      if (item.name.contains('서울우유') || item.name.contains('신선우유')) {
        computedUseBy = item.expiryDate.add(const Duration(days: 45));
      }

      String computedStatus = 'NORMAL';
      final remainingDays = computedUseBy.difference(_currentDate).inDays;

      if (remainingDays <= 1) {
        computedStatus = 'URGENT';
      } else if (remainingDays <= 3) {
        computedStatus = 'WARNING';
      } else {
        computedStatus = 'NORMAL';
      }

      pipelineList.add(Ingredient(
        id: item.id,
        name: item.name,
        expiryDate: item.expiryDate,
        useByDate: computedUseBy,
        quantity: item.quantity,
        unit: item.unit,
        category: item.category,
        status: computedStatus,
        progress: item.progress,
      ));
    }

    pipelineList.sort((a, b) => a.useByDate.compareTo(b.useByDate));

    setState(() {
      _processedDisplayItems = pipelineList;
    });
  }

  List<Ingredient> _getFilteredItems() {
    if (_selectedCategory == '전체') return _processedDisplayItems;
    return _processedDisplayItems.where((item) => item.category == _selectedCategory).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'URGENT':
        return const Color(0xFFBA1A1A);
      case 'WARNING':
        return const Color(0xFFFF9800);
      case 'NORMAL':
      default:
        return const Color(0xFF0E6E20);
    }
  }

  IconData _getIngredientIcon(String name) {
    if (name.contains('당근')) return Icons.eco;
    if (name.contains('우유')) return Icons.opacity;
    if (name.contains('양파')) return Icons.fiber_manual_record;
    if (name.contains('브로콜리')) return Icons.forest;
    if (name.contains('달걀') || name.contains('계란')) return Icons.egg;
    if (name.contains('삼겹살') || name.contains('고기')) return Icons.kebab_dining;
    if (name.contains('두부')) return Icons.layers;
    if (name.contains('콩나물') || name.contains('대파')) return Icons.grass;
    return Icons.fastfood;
  }

  void _showImageSourceSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0E6E20)),
                title: const Text('갤러리에서 영수증 가져오기'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndProcess(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0E6E20)),
                title: const Text('카메라로 영수증 촬영하기'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndProcess(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageAndProcess(ImageSource source) async {
    XFile? pickedFile;

    try {
      pickedFile = await _picker.pickImage(source: source);

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
      });

      final url = Uri.parse('http://10.0.2.2:8080/api/ingredients/ocr-scan');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"imagePath": pickedFile.name}),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          if (responseData is Map) {
            _realRawReceiptText = responseData['rawText'] ?? "추출된 영수증 텍스트 본문이 비어있습니다.";
            _lastDetectedNames = List<String>.from(responseData['detectedItems'] ?? []);
          } else if (responseData is List) {
            _realRawReceiptText = "스캔 완료 파일명: ${pickedFile!.name}\n\n[백엔드 최종 인식 품목]\n${responseData.join(', ')}";
            _lastDetectedNames = List<String>.from(responseData);
          }
        });

        _showOcrSimulationDialog();

      } else {
        throw Exception("서버 에러 응답 발생 (Status Code: ${response.statusCode})");
      }
    } catch (e) {
      setState(() {
        final String fileName = pickedFile != null ? pickedFile.name : "알 수 없는 파일";

        _realRawReceiptText = "[백엔드 스프링부트 서버 연결 실패]\n\n"
            "이클립스 자바 백엔드 서버가 구동 중인지 확인해 주세요!\n"
            "방금 가상 카메라로 촬영한 리얼 정보는 다음과 같습니다.\n\n"
            "• 촬영한 파일명: $fileName\n"
            "• 에러 로그 상세 정보: $e";

        _lastDetectedNames = [];
        if (fileName.contains('receipt') || fileName.contains('png') || fileName.contains('jpg')) {
          _lastDetectedNames.add('신선우유');
        }
      });

      _showOcrSimulationDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _getFilteredItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FreshKeeper",
          style: TextStyle(color: Color(0xFF191C1D), fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF191C1D)),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0E6E20)))
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: ['전체', '냉장', '냉동', '실온'].map((cat) => _buildCategoryChip(cat)).toList(),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: displayItems.isEmpty
                  ? const Center(child: Text("보유 중인 식재료가 없습니다.", style: TextStyle(color: Color(0xFF40493D))))
                  : ListView.builder(
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  final remainingDays = item.useByDate.difference(_currentDate).inDays;
                  final statusColor = _getStatusColor(item.status);

                  return Card(
                    color: const Color(0xFFFFFFFF),
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE1E3E4), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getIngredientIcon(item.name),
                                  color: statusColor.withOpacity(0.7),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF191C1D)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            remainingDays >= 0 ? 'D-$remainingDays' : 'D+${remainingDays.abs()}',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}${item.unit} 남음',
                                      style: const TextStyle(color: Color(0xFF707A6C), fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.useByDate.year}.${item.useByDate.month.toString().padLeft(2, '0')}.${item.useByDate.day.toString().padLeft(2, '0')}',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFEDEEEF),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceSelectionBottomSheet,
        backgroundColor: const Color(0xFF0E6E20),
        elevation: 2,
        icon: const Icon(Icons.document_scanner, color: Colors.white),
        label: const Text("영수증 OCR 스캔", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCategoryChip(String categoryName) {
    final isSelected = _selectedCategory == categoryName;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(categoryName),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = categoryName;
          });
        },
        selectedColor: const Color(0xFF0E6E20),
        backgroundColor: const Color(0xFFFFFFFF),
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF191C1D), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE1E3E4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showOcrSimulationDialog() {
    DateTime selectedUserDate = DateTime(2026, 05, 28);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("🧾 OCR 정제 & 사용자 UX 검증", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF191C1D))),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("[1] 유입된 비정형 영수증 텍스트", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB51925), fontSize: 13)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFF3F4F5),
                    child: Text(
                      _realRawReceiptText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF191C1D)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("[2] 백엔드 Regex 품목명 정제 결과", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0E6E20), fontSize: 13)),
                  Text(
                    _lastDetectedNames.isEmpty
                        ? "• 서버에서 필터링 완료된 식재료 품목이 없습니다."
                        : _lastDetectedNames.map((name) => "• 품목명 추출 완료 -> $name").join('\n'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF40493D)),
                  ),
                  const SizedBox(height: 12),
                  const Text("[3] 유통기한 수동 입력", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedUserDate,
                        firstDate: DateTime(2026, 01, 01),
                        lastDate: DateTime(2027, 12, 31),
                      );
                      if (picked != null && picked != selectedUserDate) {
                        setDialogState(() {
                          selectedUserDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(
                      "${selectedUserDate.year}-${selectedUserDate.month.toString().padLeft(2, '0')}-${selectedUserDate.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E6E20),
                      side: const BorderSide(color: Color(0xFF0E6E20)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("[4] 스프링 부트 DTO 최종 구조화 바인딩", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5000), fontSize: 13)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFFFDCBE).withOpacity(0.3),
                    child: Text(
                      "IngredientRequestDto {\n  품목명: '${_lastDetectedNames.isNotEmpty ? _lastDetectedNames.first : '없음'}',\n  유저입력날짜: '${selectedUserDate.year}-${selectedUserDate.month.toString().padLeft(2, '0')}-${selectedUserDate.day.toString().padLeft(2, '0')}'\n}",
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF542E00)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소", style: TextStyle(color: Color(0xFF707A6C))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    int currentId = 80;
                    for (String itemName in _lastDetectedNames) {
                      _rawDatabaseItems.add(
                        Ingredient(
                          id: currentId++,
                          name: itemName,
                          expiryDate: selectedUserDate,
                          useByDate: selectedUserDate,
                          quantity: itemName.contains('우유') ? 900 : 1,
                          unit: itemName.contains('우유') ? 'ml' : '개',
                          category: '냉장',
                          status: 'NORMAL',
                          progress: 0.5,
                        ),
                      );
                    }
                    _executeBackendPipeline();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${_lastDetectedNames.length}개의 식재료가 실제 재고 목록에 동적 바인딩되었습니다.")),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E6E20)),
                child: const Text("냉장고 반영", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }
}

class DummyPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final String info;

  const DummyPlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Color(0xFF191C1D), fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: const Color(0xFF0E6E20).withOpacity(0.4)),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF191C1D)),
              ),
              const SizedBox(height: 12),
              Text(
                info,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF40493D), height: 1.6),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0E6E20), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "7조 통합 단계 연결 대기 중",
                  style: TextStyle(color: Color(0xFF0E6E20), fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
