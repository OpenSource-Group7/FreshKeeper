package domain;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class IngredientService {

    private final IngredientRepository ingredientRepository;
    private final FoodSafetyApiService foodSafetyApiService;

    public IngredientService(IngredientRepository ingredientRepository, FoodSafetyApiService foodSafetyApiService) {
        this.ingredientRepository = ingredientRepository;
        this.foodSafetyApiService = foodSafetyApiService;
    }

    /**
     * 1. 식재료 등록하기
     * 등록하기 전에 식약처 Open API로 소비기한을 자동 계산하고 상태를 판단해 저장합니다.
     */
    public Ingredient register(Ingredient ingredient) {
        // 가은이가 만든 식약처 Open API 실시간 계산기 가동!
        LocalDate computedUseByDate = foodSafetyApiService.calculateUseByDate(
            ingredient.getName(), 
            ingredient.getExpirationDate()
        );
        
        // 엔티티 내부의 소비기한 세터(Setter) 메서드를 호출해 값을 저장
        ingredient.setUseByDate(computedUseByDate);

        // 유통기한 상태 자동 업데이트 로직 실행
        updateIngredientStatus(ingredient);
        return ingredientRepository.save(ingredient);
    }

    /**
     * 2. 냉장고의 모든 식재료 조회하면서 상태 실시간 갱신하기
     */
    public List<Ingredient> getAllIngredients() {
        List<Ingredient> ingredients = ingredientRepository.findAll();
        for (Ingredient ingredient : ingredients) {
            updateIngredientStatus(ingredient);
        }
        return ingredients;
    }

    /**
     * 3. 특정 상태(충분/임박/소진)의 식재료만 모아보기
     */
    public List<Ingredient> getIngredientsByStatus(String status) {
        return ingredientRepository.findByStatus(status);
    }

    /**
     * 4. 먹었거나 버린 식재료 삭제하기
     */
    public void removeIngredient(Long id) {
        ingredientRepository.deleteById(id);
    }

    /**
     * [핵심 로직] 유통기한 남은 날짜를 계산해 상태(status)를 자동으로 정해주는 메서드
     */
    private void updateIngredientStatus(Ingredient ingredient) {
        if (ingredient.getExpirationDate() == null) {
            ingredient.setStatus("충분");
            return;
        }

        LocalDate today = LocalDate.now();
        long daysLeft = ChronoUnit.DAYS.between(today, ingredient.getExpirationDate());

        if (daysLeft < 0 || ingredient.getQuantity() <= 0) {
            ingredient.setStatus("소진");
        } else if (daysLeft <= 3) {
            ingredient.setStatus("임박");
        } else {
            ingredient.setStatus("충분");
        }
    }
}
