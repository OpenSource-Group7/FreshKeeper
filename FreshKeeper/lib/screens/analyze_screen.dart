import 'package:flutter/material.dart';

class RecipeAnalyzeScreen extends StatefulWidget {
  const RecipeAnalyzeScreen({super.key});

  @override
  State<RecipeAnalyzeScreen> createState() => _RecipeAnalyzeScreenState();
}

class _RecipeAnalyzeScreenState extends State<RecipeAnalyzeScreen> {
  final _urlController = TextEditingController();

  // UI 확인용 임시 더미 데이터 (버튼 누르면 나타나도록 설정)
  String? detectedDish;
  List<String> ingredients = [];
  String? previewText;

  @override
  Widget build(BuildContext context) {
    // 1. 팀원의 포인트 그린 테마 자동 연동
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("링크 레시피 분석", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: "유튜브 또는 네이버 블로그 주소를 입력하세요",
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 버튼 클릭 시 테마에 맞게 렌더링되는지 확인하기 위한 더미 세팅
                  setState(() {
                    detectedDish = "돼지고기 김치찌개";
                    ingredients = ["돼지고기", "배추김치", "두부", "대파", "다진마늘", "고춧가루"];
                    previewText = "안녕하세요! 오늘은 집에서 정말 쉽게 끓일 수 있는 깊은 맛의 돼지고기 김치찌개 레시피를 가져왔습니다. 먼저 냄비에 식용유를 살짝 두르고...";
                  });
                },
                child: const Text("레시피 분석하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),

            // 결과창 레이아웃
            if (detectedDish != null) ...[
              const Text("분석된 요리", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(detectedDish!, style: TextStyle(fontSize: 24, color: primaryColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              const Text("추출된 진짜 재료", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),

              // 2. 가이드라인 반영: 낮은 채도의 그린 배경 틴트를 넣은 상태 칩(Status Chips)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ingredients.map((item) => Chip(
                  label: Text(item, style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                  backgroundColor: primaryColor.withOpacity(0.1), // 가이드라인 저채도 배경 구현
                  side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // 8px 라운드
                )).toList(),
              ),
              const SizedBox(height: 24),

              const Text("본문/자막 미리보기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F5), // 팀원 가이드의 surface-container-low 컬러
                  borderRadius: BorderRadius.circular(8), // 8px 라운드
                  border: Border.all(color: const Color(0xFFE7E8E9), width: 1),
                ),
                child: Text(
                  previewText ?? "",
                  style: const TextStyle(color: Color(0xFF40493D), height: 1.5), // 가이드의 on-surface-variant 컬러 적용
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}