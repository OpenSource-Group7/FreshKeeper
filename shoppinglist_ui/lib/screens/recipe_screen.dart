import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

// ── 레시피 탭 전체 (TabController) ──────────────────────────────────────────
class RecipeTabScreen extends StatefulWidget {
  RecipeTabScreen({super.key});
  @override
  State<RecipeTabScreen> createState() => _RecipeTabScreenState();
}

class _RecipeTabScreenState extends State<RecipeTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("레시피",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5)),
        bottom: TabBar(
          controller: _tab,
          labelColor: kPrimary,
          unselectedLabelColor: kTextSub,
          indicatorColor: kPrimary,
          tabs: const [
            Tab(text: "추천 레시피"),
            Tab(text: "링크 분석"),
            Tab(text: "레시피 검색"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _RecommendedRecipesTab(),
          _RecipeAnalyzeTab(),
          RecipeSearchScreen(),
        ],
      ),
    );
  }
}

// ── 추천 레시피 탭 ───────────────────────────────────────────────────────────
class _RecommendedRecipesTab extends StatefulWidget {
  @override
  State<_RecommendedRecipesTab> createState() => _RecommendedRecipesTabState();
}

class _RecommendedRecipesTabState extends State<_RecommendedRecipesTab> {
  List<RecipeModel> _recipes = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/recipes'));
      if (res.statusCode == 200) {
        List data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          _recipes = data
              .map((e) => RecipeModel(
            title: e['요리명'] ?? '',
            duration: e['소요시간'] ?? '',
            ingredients: List<String>.from(e['필요재료'] ?? []),
          ))
              .toList();
        });
        return;
      }
    } catch (_) {}
    _dummy();
  }

  void _dummy() {
    setState(() {
      _recipes = [
        RecipeModel(title: "김치찌개", duration: "25분",
            ingredients: ["김치 1/4포기", "돼지고기 200g", "두부 1모", "대파 1/2대"]),
        RecipeModel(title: "초간단 계란볶음밥", duration: "10분",
            ingredients: ["밥 1공기", "계란 2개", "대파 1/3대", "간장 1스푼"]),
        RecipeModel(title: "양파 수프", duration: "30분",
            ingredients: ["양파 2개", "버터 20g", "밀가루 1스푼", "치킨스톡 500ml"]),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _recipes.length,
      itemBuilder: (_, i) {
        final r = _recipes[i];
        return Card(
          color: kSurface,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: kBorder)),
          child: ExpansionTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.menu_book, color: Color(0xFFFF9800), size: 24),
            ),
            title: Text(r.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: kTextMain)),
            subtitle: Text("⏱ ${r.duration}",
                style: const TextStyle(color: kTextSub, fontSize: 13)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Divider(color: kBorder),
                  const SizedBox(height: 8),
                  const Text("🍳 필요 재료",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: kPrimary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: r.ingredients
                        .map((ing) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEDEEEF),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(ing,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF40493D))),
                    ))
                        .toList(),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 링크 분석 탭 ─────────────────────────────────────────────────────────────
class _RecipeAnalyzeTab extends StatefulWidget {
  @override
  State<_RecipeAnalyzeTab> createState() => _RecipeAnalyzeTabState();
}

class _RecipeAnalyzeTabState extends State<_RecipeAnalyzeTab> {
  final _urlController = TextEditingController();
  String? detectedDish;
  List<String> ingredients = [];
  String? previewText;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: "유튜브 또는 네이버 블로그 주소를 입력하세요",
            hintStyle: const TextStyle(color: kTextSub),
            filled: true,
            fillColor: const Color(0xFFF3F4F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() {
                detectedDish = "돼지고기 김치찌개";
                ingredients = ["돼지고기", "배추김치", "두부", "대파", "다진마늘", "고춧가루"];
                previewText =
                "안녕하세요! 오늘은 집에서 쉽게 끓일 수 있는 깊은 맛의 돼지고기 김치찌개 레시피를 가져왔습니다...";
              });
            },
            child: const Text("레시피 분석하기",
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 30),
        if (detectedDish != null) ...[
          const Text("분석된 요리",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextSub)),
          const SizedBox(height: 4),
          Text(detectedDish!,
              style: const TextStyle(
                  fontSize: 24, color: kPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text("추출된 재료",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextSub)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ingredients
                .map((item) => Chip(
              label: Text(item,
                  style: const TextStyle(
                      color: kPrimary, fontWeight: FontWeight.w600)),
              backgroundColor: kPrimary.withOpacity(0.1),
              side: BorderSide(color: kPrimary.withOpacity(0.3), width: 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ))
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text("본문 미리보기",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextSub)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7E8E9)),
            ),
            child: Text(previewText ?? "",
                style: const TextStyle(color: Color(0xFF40493D), height: 1.5)),
          ),
        ],
      ]),
    );
  }
}

// ── 레시피 검색 탭 ───────────────────────────────────────────────────────────
class RecipeSearchScreen extends StatefulWidget {
  RecipeSearchScreen({super.key});
  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<dynamic> searchResults = [];
  bool isLoading = false;

  final List<String> myIngredients = [
    "돼지고기", "대파", "양파", "달걀", "밥", "참치", "식용유",
    "참기름", "배추김치", "고춧가루", "청양고추", "배추", "스팸",
    "생수", "소금", "설탕", "간장", "김치", "두부", "식초",
    "고추장", "멸치", "마늘", "기름", "양념",
  ];

  void _search() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => isLoading = true);
    final results = await _apiService.searchRecipes(_searchController.text);
    setState(() {
      searchResults = results;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "궁금한 요리를 입력하세요 (예: 김치찌개)",
                hintStyle: const TextStyle(color: kTextSub),
                filled: true,
                fillColor: const Color(0xFFF3F4F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.search, color: kPrimary, size: 30),
              onPressed: _search),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: Text(
            "💡 나의 보유 재료: ${myIngredients.join(', ')}",
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF40493D)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : searchResults.isEmpty
              ? const Center(
              child: Text("검색 결과가 없습니다.", style: TextStyle(color: kTextSub)))
              : ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (_, index) {
              final video = searchResults[index];
              final List<String> needed =
              (video['needed_ingredients'] ?? [])
                  .map<String>((e) => e.toString())
                  .toList();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: kBorder)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12)),
                              child: Image.network(
                                video['thumbnail_url'] ??
                                    'https://via.placeholder.com/120x90',
                                width: 120, height: 90, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 120, height: 90,
                                    color: const Color(0xFFF3F4F5),
                                    child: const Icon(Icons.play_circle,
                                        color: kTextSub)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  video['title'] ?? '제목 없음',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14, color: kTextMain),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ]),
                      if (needed.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: kBorder),
                                const SizedBox(height: 6),
                                const Text("필요 재료",
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: kTextSub)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6, runSpacing: 6,
                                  children: needed.map((item) {
                                    final has = myIngredients.contains(item);
                                    final c = has ? kPrimary : kError;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: c.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: c.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                              has ? Icons.check : Icons.close,
                                              color: c, size: 12),
                                          const SizedBox(width: 4),
                                          Text(item,
                                              style: TextStyle(
                                                  color: c,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ]),
                        ),
                    ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}