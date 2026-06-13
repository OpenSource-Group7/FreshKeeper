import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<dynamic> searchResults = [];
  bool isLoading = false;

  //임시 사용자가 가지고 있는 냉장고 재료 목록 (나중에 유저 데이터로 연결)
  List<String> myIngredients = [
    "돼지고기", "대파", "양파", "달걀", "밥", "참치", "식용유",
    "참기름", "배추김치", "고춧가루", "청양고추", "배추", "스팸",
    "생수", "소금", "설탕", "간장", "김치", "두부", "식초",
    "고추장", "멸치", "마늘", "기름", "양념"
  ];

  void _executeSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    List<dynamic> results = await _apiService.searchRecipes(_searchController.text);

    setState(() {
      searchResults = results;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF1B5E20); // 초록색 테마
    final alertColor = const Color(0xFFB51925); // 빨간색 테마

    return Scaffold(
      appBar: AppBar(
        title: const Text("레시피 검색", style: TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: "궁금한 요리를 입력하세요 (예: 김치찌개)"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.search, color: primaryColor, size: 30),
                  onPressed: _executeSearch,
                )
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE1E3E4)),
              ),
              child: Text(
                "💡 나의 보유 재료: ${myIngredients.join(', ')}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF40493D)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : searchResults.isEmpty
                  ? const Center(child: Text("검색 결과가 없습니다."))
                  : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final video = searchResults[index];
                  List<dynamic> neededRaw = video['needed_ingredients'] ?? [];
                  List<String> neededIngredients = neededRaw.map((e) => e.toString()).toList();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Color(0xFFE1E3E4), width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              video['thumbnail_url'] ?? 'https://via.placeholder.com/120x90',
                              width: 120,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  video['title'] ?? '제목 없음',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 🌟 [파란색 화살표 위치] 자막 기반 필요 재료 대조 칩 영역
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: Color(0xFFE1E3E4)),
                              const SizedBox(height: 6),
                              const Text("이 영상의 레시피 필요 재료", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),

                              // 가로로 이쁘게 흐르는 정렬 방식 보완 완료
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: neededIngredients.map((item) {
                                  // 사용자가 가지고 있는 재료인지 체크!
                                  bool hasIt = myIngredients.contains(item);
                                  Color chipColor = hasIt ? primaryColor : alertColor;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: chipColor.withOpacity(0.08), // 저채도 틴트
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: chipColor.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min, // 글자 크기만큼만 가로 차지하도록 고정!
                                      children: [
                                        Icon(hasIt ? Icons.check : Icons.close, color: chipColor, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                            item,
                                            style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.bold)
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}