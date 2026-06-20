import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../models/models.dart';

class InventoryScreen extends StatefulWidget {
  final String jwtToken;
  const InventoryScreen({super.key, required this.jwtToken});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String? _jwtToken;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchIngredientsFromBackend();
    });
  }

  Future<void> fetchIngredientsFromBackend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://127.0.0.1:8000/inventory-detail');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.jwtToken}"
        },
      ).timeout(const Duration(seconds: 30));

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> backendData =
        jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _rawDatabaseItems = backendData.map((json) => Ingredient(
            id: json['id'] ?? 0,
            name: json['ingredient_name'] ?? '알 수 없음',
            expiryDate: DateTime.parse(json['expiration_date']),
            useByDate: DateTime.parse(json['expiration_date']),
            purchaseDate: DateTime.parse(json['purchase_date'] ?? json['expiration_date']),
            quantity: (json['quantity'] ?? 1).toDouble(),
            unit: json['unit'] ?? '개',
            category: json['category'] ?? '냉장',
            status: 'NORMAL',
            progress: 0.5,
          )).toList();
        });

        _executeBackendPipeline();
      } else {
        throw Exception("서버 에러: ${response.statusCode}");
      }
    } catch (e) {
      print("API 실패: $e");

      setState(() {
        _rawDatabaseItems = [];
        _processedDisplayItems = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // 직접 추가용 백엔드 연동
  // ※ 실제 생성 API의 경로/필드명이 다르면 여기 url과 body의 key만
  //    맞는 값으로 바꿔주세요. (현재는 GET /inventory-detail 응답과
  //    동일한 snake_case 필드명 규칙을 그대로 사용했습니다)
  // ============================================================
  Future<bool> addIngredientToBackend(Ingredient ingredient) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/inventory');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.jwtToken}",
        },
        body: jsonEncode({
          "ingredient_name": ingredient.name,
          "expiration_date": ingredient.expiryDate.toIso8601String().split('T')[0],
          "quantity": ingredient.quantity,
          "unit": ingredient.unit,
          "category": ingredient.category,
          "status": "NORMAL"
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("서버 에러 내용: ${response.body}");
        return false;
      }

      return true;
    } catch (e) {
      print("NETWORK ERROR:");
      print(e.toString());
      return false;
    }
  }

  Future<bool> deleteIngredientFromBackend(int id) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/inventory/$id');
      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer ${widget.jwtToken}"},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      return false;
    } catch (e) {
      print("서버 오프라인 상태 - 로컬 메모리 삭제 진행: $e");
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

      final totalDays = computedUseBy.difference(item.purchaseDate).inDays <= 0
          ? 1
          : computedUseBy.difference(item.purchaseDate).inDays;
      final remainDays = computedUseBy.difference(_currentDate).inDays;

      double computedProgress =
      totalDays <= 0 ? 0.0 : (remainDays / totalDays).clamp(0.0, 1.0);
      computedProgress = computedProgress.clamp(0.0, 1.0);

      pipelineList.add(Ingredient(
        id: item.id,
        name: item.name,
        expiryDate: item.expiryDate,
        useByDate: computedUseBy,
        purchaseDate: item.purchaseDate,
        quantity: item.quantity,
        unit: item.unit,
        category: item.category,
        status: computedStatus,
        progress: computedProgress,
      ));
    }

    pipelineList.sort((a, b) => a.useByDate.compareTo(b.useByDate));

    _processedDisplayItems = pipelineList;

    setState(() {});
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
            _selectedCategory = '전체';
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
        _realRawReceiptText = "[백엔드 스프링부트 서버 연결 실패]\n\n이클립스 자바 백엔드 서버 구동을 확인해 주세요!";
        _lastDetectedNames = ['우유', '양파', '대파'];
      });

      _showOcrSimulationDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOcrSimulationDialog() {
    List<TextEditingController> controllers = _lastDetectedNames
        .map((name) => TextEditingController(text: name))
        .toList();

    List<DateTime> itemDates = List<DateTime>.generate(
      _lastDetectedNames.length,
          (_) => DateTime.now(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFFFFFFF),
            title: const Row(
              children: [
                Icon(Icons.receipt_long, color: Color(0xFF0E6E20)),
                SizedBox(width: 10),
                Text("스캔 품목별 정보 확인", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF191C1D))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "각 식재료의 이름과 알맞은 유통기한을 각각 설정해 주세요.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF707A6C), height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controllers.length,
                      itemBuilder: (context, i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEDEEEF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "품목 [${i + 1}]",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0E6E20)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: controllers[i],
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFFFF),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE1E3E4)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0E6E20), width: 1.5),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 14, color: Color(0xFF191C1D)),
                              ),
                              const SizedBox(height: 10),

                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: itemDates[i],
                                    firstDate: DateTime(2026, 01, 01),
                                    lastDate: DateTime(2027, 12, 31),
                                  );
                                  if (picked != null && picked != itemDates[i]) {
                                    setDialogState(() {
                                      itemDates[i] = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE1E3E4)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "유통기한: ${itemDates[i].year}-${itemDates[i].month.toString().padLeft(2, '0')}-${itemDates[i].day.toString().padLeft(2, '0')}",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF40493D)),
                                      ),
                                      const Icon(Icons.calendar_month, color: Color(0xFF0E6E20), size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소", style: TextStyle(color: Color(0xFF707A6C), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  List<String> finalSavedNames = [];

                  setState(() {
                    int tempId = DateTime.now().millisecondsSinceEpoch;
                    for (int i = 0; i < controllers.length; i++) {
                      String name = controllers[i].text.trim();
                      if (name.isNotEmpty) {
                        finalSavedNames.add(name);

                        _rawDatabaseItems.add(
                          Ingredient(
                            id: tempId++,
                            name: name,
                            expiryDate: itemDates[i],
                            useByDate: itemDates[i],
                            purchaseDate: DateTime.now(),
                            quantity: name.contains('우유') ? 900 : 1,
                            unit: name.contains('우유') ? 'ml' : '개',
                            category: name.contains('당근') || name.contains('양파') || name.contains('대파') ? '실온' : '냉장',
                            status: 'NORMAL',
                            progress: 0.6,
                          ),
                        );
                      }
                    }
                    _executeBackendPipeline();
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${finalSavedNames.length}개의 식재료가 각기 다른 유통기한으로 냉장고에 등록되었습니다! 🥦✨")),
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

  // ============================================================
  // 직접 추가 다이얼로그 (이름 / 수량+단위 / 보관 장소 / 유통기한)
  // ============================================================
  void _showManualAddDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController unitController = TextEditingController(text: '개');

    String selectedCategory = '냉장';
    DateTime selectedExpiryDate = DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFFFFFFF),
            title: const Row(
              children: [
                Icon(Icons.edit_note, color: Color(0xFF0E6E20)),
                SizedBox(width: 10),
                Text("식재료 직접 추가", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF191C1D))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "보관할 식재료의 이름, 수량, 보관 장소, 유통기한을 입력해 주세요.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF707A6C), height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    const Text("식재료 이름", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0E6E20))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "예: 당근, 서울우유 900ml",
                        hintStyle: const TextStyle(color: Color(0xFF9EA49A), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE1E3E4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0E6E20), width: 1.5),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF191C1D)),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("수량", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0E6E20))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFFFF),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE1E3E4)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0E6E20), width: 1.5),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 14, color: Color(0xFF191C1D)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("단위", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0E6E20))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: unitController,
                                decoration: InputDecoration(
                                  hintText: "개, ml, 팩 등",
                                  hintStyle: const TextStyle(color: Color(0xFF9EA49A), fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFFFF),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE1E3E4)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0E6E20), width: 1.5),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 14, color: Color(0xFF191C1D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text("보관 장소 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0E6E20))),
                    const SizedBox(height: 6),
                    Row(
                      children: ['냉장', '냉동', '실온'].map((type) {
                        final isSel = selectedCategory == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(type, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : const Color(0xFF191C1D))),
                            selected: isSel,
                            selectedColor: const Color(0xFF0E6E20),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onSelected: (bool selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedCategory = type;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text("유통기한", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0E6E20))),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiryDate,
                          firstDate: DateTime(2026, 01, 01),
                          lastDate: DateTime(2027, 12, 31),
                        );
                        if (picked != null && picked != selectedExpiryDate) {
                          setDialogState(() {
                            selectedExpiryDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE1E3E4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${selectedExpiryDate.year}-${selectedExpiryDate.month.toString().padLeft(2, '0')}-${selectedExpiryDate.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF40493D)),
                            ),
                            const Icon(Icons.calendar_month, color: Color(0xFF0E6E20), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text("취소", style: TextStyle(color: Color(0xFF707A6C), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                  final String name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("식재료 이름을 입력해 주세요.")),
                    );
                    return;
                  }

                  final double quantity = double.tryParse(quantityController.text.trim()) ?? 1;
                  final String unit = unitController.text.trim().isEmpty ? '개' : unitController.text.trim();
                  final DateTime purchaseDate = DateTime.now();

                  setDialogState(() {
                    isSaving = true;
                  });

                  final Ingredient newIngredient = Ingredient(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: name,
                    expiryDate: selectedExpiryDate,
                    useByDate: selectedExpiryDate,
                    purchaseDate: purchaseDate,
                    quantity: quantity,
                    unit: unit,
                    category: selectedCategory,
                    status: 'NORMAL',
                    progress: 1.0,
                  );

                  final bool savedOnServer = await addIngredientToBackend(newIngredient);

                  if (!context.mounted) return;

                  if (savedOnServer) {

                    setState(() {
                      _rawDatabaseItems.add(newIngredient);
                      _executeBackendPipeline();
                    });


                    fetchIngredientsFromBackend();
                  } else {

                    setState(() {
                      _rawDatabaseItems.add(newIngredient);
                      _executeBackendPipeline();
                    });
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        savedOnServer
                            ? "'$name'이(가) 냉장고에 추가되었습니다! 🥦✨"
                            : "서버 연결에 실패해 '$name'을(를) 임시로 로컬에만 추가했습니다.",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E6E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text("냉장고 반영", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
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
        onRefresh: () async {
          await fetchIngredientsFromBackend();
        },
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
                    final item = displayItems[index];final remainingDays = item.useByDate.difference(_currentDate).inDays;
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
                          final int originalIndex =
                          _rawDatabaseItems.indexWhere((e) => e.id == item.id);

                          final Ingredient deletedItem = item;

                          setState(() {
                            _rawDatabaseItems.removeWhere((e) => e.id == item.id);
                            _processedDisplayItems.removeWhere((e) => e.id == item.id);
                          });

                          // 서버 삭제
                          if (item.id != null) {
                            await deleteIngredientFromBackend(item.id!);
                          }

                          // 상태 재계산 (이거 없으면 "소진 메시지 잔상" 계속 남음)
                          _executeBackendPipeline();

                          // 기존 SnackBar 제거
                          ScaffoldMessenger.of(context).clearSnackBars();

                          // 취소 버튼 없는 깔끔한 메시지
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("'${deletedItem.name}' 삭제 완료"),
                              duration: const Duration(seconds: 2),
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
                                          '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}${item.unit}',
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _showManualAddDialog,
              backgroundColor: const Color(0xFFFFFFFF),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF0E6E20), width: 1.5),
              ),
              icon: const Icon(Icons.edit, color: Color(0xFF0E6E20)),
              label: const Text("직접 추가", style: TextStyle(color: Color(0xFF0E6E20), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              onPressed: _showImageSourceSelectionBottomSheet,
              backgroundColor: const Color(0xFF0E6E20),
              elevation: 2,
              icon: const Icon(Icons.document_scanner, color: Colors.white),
              label: const Text("영수증 OCR 스캔", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
}