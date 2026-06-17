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
  final DateTime _currentDate = DateTime.now();

  List<Ingredient> _rawDatabaseItems = [];
  List<Ingredient> _processedDisplayItems = [];
  String _selectedCategory = '전체';
  bool _isLoading = false;

  String _realRawReceiptText = "인식된 영수증 데이터가 없습니다.";
  List<String> _lastDetectedNames = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchIngredientsFromBackend();
  }

  Future<void> fetchIngredientsFromBackend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/ingredients');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> backendData = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _rawDatabaseItems = backendData.map((json) => Ingredient(
            id: json['id'],
            name: json['name'] ?? '알 수 없는 식재료',
            expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : DateTime.now(),
            useByDate: json['useByDate'] != null ? DateTime.parse(json['useByDate']) : DateTime.now(),
            quantity: (json['quantity'] ?? 1).toDouble(),
            unit: json['unit'] ?? '개',
            category: json['category'] ?? '냉장',
            status: json['status'] ?? 'NORMAL',
            progress: (json['progress'] ?? 0.5).toDouble(),
          )).toList();
        });

        _executeBackendPipeline();
      } else {
        throw Exception("서버 응답 에러: ${response.statusCode}");
      }
    } catch (e) {
      print("네온 DB 데이터 연동 실패 로그: $e");
      setState(() {
        _rawDatabaseItems = [
          Ingredient(id: 999, name: '마늘', expiryDate: DateTime(2026, 06, 16), useByDate: DateTime(2026, 07, 22), quantity: 5, unit: '개', category: '냉장', status: 'NORMAL', progress: 0.5),
        ];
        _executeBackendPipeline();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> deleteIngredientFromBackend(int id) async {
    try {
      final url = Uri.parse('http://10.0.2.2:8080/api/ingredients/$id');
      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("네온 DB에서 식재료 ID $id 삭제 완료");
        return true;
      }
      return false;
    } catch (e) {
      print("서버 오프라인 상태 - 로컬 메모리 삭제 모드로 가동: $e");
      return true;
    }
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
          : RefreshIndicator(
        onRefresh: fetchIngredientsFromBackend,
        child: Padding(
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

                    return Dismissible(
                      key: Key(item.id.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: const Text("식재료 소진 확인", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              content: Text("'${item.name}'을(를) 냉장고에서 완전히 삭제하시겠습니까?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("취소", style: TextStyle(color: Color(0xFF707A6C))),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("삭제", style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        final int originalIndex = _rawDatabaseItems.indexOf(item);
                        final Ingredient deletedItem = item;

                        setState(() {
                          _rawDatabaseItems.removeWhere((element) => element.id == item.id);
                          _processedDisplayItems.removeWhere((element) => element.id == item.id);
                        });

                        if (item.id != null) {
                          await deleteIngredientFromBackend(item.id!);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("'${deletedItem.name}' 소진 완료!"),
                            action: SnackBarAction(
                              label: "삭제 취소",
                              textColor: const Color(0xFF5CB35C),
                              onPressed: () {
                                setState(() {
                                  _rawDatabaseItems.insert(originalIndex, deletedItem);
                                  _executeBackendPipeline();
                                });
                              },
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("삭제", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.delete_forever, color: Colors.white),
                          ],
                        ),
                      ),
                      child: Card(
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
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
    DateTime selectedUserDate = DateTime.now();

    String initialName = _lastDetectedNames.isNotEmpty ? _lastDetectedNames.first : '';
    TextEditingController nameController = TextEditingController(text: initialName);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFFFFFFF),
            title: const Row(
              children: [
                Icon(Icons.kitchen, color: Color(0xFF0E6E20)),
                SizedBox(width: 10),
                Text("식재료 추가 확인", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF191C1D))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "인식된 식재료 정보를 확인해 주세요. 정보가 다르다면 직접 수정할 수 있습니다.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF707A6C), height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "식재료 이름",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF191C1D), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "예: 우유, 마늘, 양파",
                      hintStyle: const TextStyle(color: Color(0xFF9EA49A), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F5),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE1E3E4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0E6E20), width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF191C1D)),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "유통기한 / 소비기한",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF191C1D), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE1E3E4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${selectedUserDate.year}년 ${selectedUserDate.month.toString().padLeft(2, '0')}월 ${selectedUserDate.day.toString().padLeft(2, '0')}일",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF191C1D)),
                          ),
                          const Icon(Icons.calendar_month, color: Color(0xFF0E6E20)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소", style: TextStyle(color: Color(0xFF707A6C), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  final String finalName = nameController.text.trim();

                  if (finalName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("식재료 이름을 입력해 주세요!")),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  setState(() {
                    _rawDatabaseItems.add(
                      Ingredient(
                        id: DateTime.now().millisecondsSinceEpoch,
                        name: finalName,
                        expiryDate: selectedUserDate,
                        useByDate: selectedUserDate,
                        quantity: finalName.contains('우유') ? 900 : 1,
                        unit: finalName.contains('우유') ? 'ml' : '개',
                        category: '냉장',
                        status: 'NORMAL',
                        progress: 0.5,
                      ),
                    );
                    _executeBackendPipeline();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'$finalName'이(가) 냉장고 재고 목록에 추가되었습니다.")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E6E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
