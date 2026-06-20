import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecipeRecommendScreen extends StatefulWidget {
  const RecipeRecommendScreen({super.key});

  @override
  State<RecipeRecommendScreen> createState() => _RecipeRecommendScreenState();
}

class _RecipeRecommendScreenState extends State<RecipeRecommendScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> recommendations = [];
  bool isRecommendLoading = false;
  bool isRecommendPressed = false;

  String? _selectedDish;
  List<dynamic> youtubeResults = [];
  bool isYoutubeLoading = false;

  List<String> myIngredients = [];

  void _fetchRecommendations() async {
    setState(() {
      isRecommendLoading = true;
      isRecommendPressed = true;
      _selectedDish = null;
      youtubeResults = [];
      myIngredients = [];
    });

    Map<String, dynamic>? results = await _apiService.recommendRecipes();

    setState(() {
      if (results != null) {
        recommendations = results["recommendations"] ?? [];
        if (results["my_ingredients"] != null) {
          myIngredients = List<String>.from(results["my_ingredients"]);
        } else {
          myIngredients = [];
        }
      } else {
        recommendations = [];
        myIngredients = [];
      }
      isRecommendLoading = false;
    });
  }

  void _fetchYoutubeRecipes(String dishName) async {
    setState(() {
      _selectedDish = dishName;
      isYoutubeLoading = true;
      youtubeResults = [];
    });

    List<dynamic> results = await _apiService.searchRecipes(dishName);

    setState(() {
      youtubeResults = results;
      isYoutubeLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1B5E20);

    return Scaffold(
      appBar: AppBar(title: const Text("레시피 추천")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isRecommendPressed) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flatware, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "현재 냉장고 속 재료들로\n최고의 레시피를 알려드립니다",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _fetchRecommendations,
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: const Text("현재 재료 기반 요리 추천받기", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ]
            else if (isRecommendLoading) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 16),
                      const Text("냉장고 재료 매칭 및 요리 분석 중...", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ]
            else ...[
                Text(
                  "추천 요리 목록",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 4),
                const Text("요리를 클릭하면 아래에 즉시 레시피가 나타납니다.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),

                Column(
                  children: recommendations.isEmpty
                      ? [const Center(child: Text("추천할 수 있는 요리가 없습니다."))]
                      : List.generate(recommendations.length, (index) {
                    final item = recommendations[index];
                    final String dishName = item["dish"] ?? "알 수 없는 요리";
                    final double matchRate = (item["match_rate"] ?? 0.0) * 100;
                    final bool isSelected = _selectedDish == dishName;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isSelected ? primaryColor : Colors.transparent, width: 2),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(dishName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text("재료 매칭률: ${matchRate.toStringAsFixed(1)}%"),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                          color: primaryColor,
                          size: isSelected ? 24 : 16,
                        ),
                        onTap: () => _fetchYoutubeRecipes(dishName),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: _fetchRecommendations,
                  child: Text("새로고침 (다시 추천받기)", style: TextStyle(color: primaryColor, fontSize: 13)),
                ),
                const Divider(height: 32, thickness: 1),

                Expanded(
                  child: _selectedDish == null
                      ? const Center(child: Text("위의 추천 요리 중 하나를 선택해 주세요.", style: TextStyle(color: Colors.grey)))
                      : isYoutubeLoading
                      ? Center(child: CircularProgressIndicator(color: primaryColor))
                      : youtubeResults.isEmpty
                      ? const Center(child: Text("검색된 유튜브 레시피가 없습니다."))
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📺 '$_selectedDish' 관련 유튜브 레시피",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: youtubeResults.length,
                          itemBuilder: (context, index) {
                            final video = youtubeResults[index];
                            final title = video["title"] ?? "제목 없음";
                            final thumbnailUrl = video["thumbnail_url"] ?? "";
                            final List<dynamic> needed = video["needed_ingredients"] ?? [];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 4, spreadRadius: 1),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (thumbnailUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        thumbnailUrl,
                                        width: 110,
                                        height: 65,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(width: 110, height: 65, color: Colors.grey),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: needed.map((item) {
                                            bool hasIt = myIngredients.contains(item);
                                            Color chipColor = hasIt ? Colors.green : Colors.red;

                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: chipColor.withOpacity(0.06),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: chipColor.withOpacity(0.15)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(hasIt ? Icons.check : Icons.close, color: chipColor, size: 10),
                                                  const SizedBox(width: 2),
                                                  Text(item, style: TextStyle(color: chipColor, fontSize: 10, fontWeight: FontWeight.bold)),
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
              ]
          ],
        ),
      ),
    );
  }
}