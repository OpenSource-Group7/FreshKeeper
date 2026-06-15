package domain;

import java.time.LocalDate;
import java.util.List;

public class Main {
    public static void main(String[] args) {
        // 1. 저장소와 서비스를 연결하여 냉장고 시스템 가동
        IngredientRepository repository = new MemoryIngredientRepository();
        IngredientService service = new IngredientService(repository);

        System.out.println("==========================================");
        System.out.println("    ✨ FreshKeeper 스마트 냉장고 가동 ✨");
        System.out.println("==========================================");

        /* [기존 가상 데이터 등록 주석 처리]
        Ingredient milk = new Ingredient(null, "우유", LocalDate.of(2026, 6, 25), 1.0, "L", "냉장", null);
        Ingredient egg = new Ingredient(null, "달걀", LocalDate.of(2026, 6, 16), 10.0, "개", "냉장", null);
        Ingredient pork = new Ingredient(null, "삼겹살", LocalDate.of(2026, 6, 13), 500.0, "g", "냉동", null);
        service.register(milk);
        service.register(egg);
        service.register(pork);
        */

        // 2. 영수증 OCR 인식 및 자동 등록 시스템 가동
        ClovaOcrService ocrService = new ClovaOcrService();
        
        String imagePath = "C:/Users/kaeun/OneDrive/바탕 화면/receipt.png"; 
        
        System.out.println("\n[진행] 영수증 사진 분석을 시작합니다... (네이버 CLOVA OCR 통신 중)");
        List<String> detectedItems = ocrService.extractIngredientsFromReceipt(imagePath);
        
        System.out.println("\n[결과] 영수증에서 다음 식재료들이 인식되었습니다:");
        if (detectedItems.isEmpty()) {
            System.out.println("⚠️ 인식된 한글 단어가 없습니다. 영수증 사진을 확인해 주세요.");
        } else {
            for (String item : detectedItems) {
                System.out.println("👉 인식된 단어: " + item);
                
                // 인식된 단어로 식재료 객체를 만듭니다. (유통기한은 오늘로부터 기본 7일 뒤로 설정!)
                Ingredient newIng = new Ingredient(
                    null,              // ID는 자동 생성
                    item,              // 영수증에서 읽은 식재료명
                    LocalDate.now().plusDays(7), // 유통기한 (기본 일주일 뒤)
                    1.0,               // 기본 수량 1.0
                    "개",              // 기본 단위
                    "냉장",            // 기본 보관 방법
                    null               // 상태는 register할 때 자동 판별됨
                );
                
                service.register(newIng);
            }
        }

        // 3. 전체 조회 및 자동 판별 시스템 확인
        System.out.println("\n==========================================");
        System.out.println("        🛒 현재 냉장고 식재료 목록");
        System.out.println("==========================================");
        
        List<Ingredient> allIngredients = service.getAllIngredients();
        for (Ingredient ing : allIngredients) {
            System.out.printf("- [%s] %s | 수량: %.1f%s | 유통기한: %s | 상태: **%s**\n",
                    ing.getCategory(), ing.getName(), ing.getQuantity(), ing.getUnit(), ing.getExpirationDate(), ing.getStatus());
        }

        // 4. 특정 상태(임박) 상품만 쏙 골라보기 기능 테스트
        System.out.println("\n==========================================");
        System.out.println("        ⚠️ 유통기한 임박 식재료 알림");
        System.out.println("==========================================");
        
        List<Ingredient> urgentIngredients = service.getIngredientsByStatus("임박");
        if (urgentIngredients.isEmpty()) {
            System.out.println("유통기한이 임박한 식재료가 없습니다.");
        } else {
            for (Ingredient ing : urgentIngredients) {
                System.out.printf("빠른 시일 내에 소비하세요 -> %s (유통기한: %s)\n", ing.getName(), ing.getExpirationDate());
            }
        }
        System.out.println("==========================================");
    }
}