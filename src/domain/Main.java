package domain;

import java.time.LocalDate;
import java.util.List;

public class Main {
    public static void main(String[] args) {
        // 1. 저장소와 서비스를 연결하여 냉장고 시스템 가동!
        IngredientRepository repository = new MemoryIngredientRepository();
        IngredientService service = new IngredientService(repository);

        System.out.println("==========================================");
        System.out.println("    ✨ FreshKeeper 스마트 냉장고 가동 ✨");
        System.out.println("==========================================");

        // 2. 가상의 식재료 데이터 생성 및 등록
        // 오늘(2026년 6월 14일) 기준으로 유통기한을 다르게 줘서 테스트해봅니다.
        
        // 유통기한이 넉넉한 우유 (6월 25일까지)
        Ingredient milk = new Ingredient(null, "우유", LocalDate.of(2026, 6, 25), 1.0, "L", "냉장", null);
        
        // 유통기한이 딱 2일 남은 달걀 (6월 16일까지 -> '임박' 예상)
        Ingredient egg = new Ingredient(null, "달걀", LocalDate.of(2026, 6, 16), 10.0, "개", "냉장", null);
        
        // 유통기한이 어제까지였던 삼겹살 (6월 13일까지 -> '소진' 예상)
        Ingredient pork = new Ingredient(null, "삼겹살", LocalDate.of(2026, 6, 13), 500.0, "g", "냉동", null);

        System.out.println("\n[진행] 식재료 3종을 냉장고에 등록합니다...");
        service.register(milk);
        service.register(egg);
        service.register(pork);

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