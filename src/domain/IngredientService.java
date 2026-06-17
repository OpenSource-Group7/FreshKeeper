package domain;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class IngredientService {

    private final IngredientRepository ingredientRepository;

    // 생성자를 통해 저장소(Repository)를 주입받음
    public IngredientService(IngredientRepository ingredientRepository) {
        this.ingredientRepository = ingredientRepository;
    }

    /**
     * 1. 식재료 등록하기
     * 등록하기 전에 유통기한을 체크해서 상태(status)를 자동으로 판단해 저장합니다.
     */
    public Ingredient register(Ingredient ingredient) {
        // 유통기한 상태 자동 업데이트 로직 실행
        updateIngredientStatus(ingredient);
        return ingredientRepository.save(ingredient);
    }

    /**
     * 2. 냉장고의 모든 식재료 조회하면서 상태 실시간 갱신하기
     */
    public List<Ingredient> getAllIngredients() {
        List<Ingredient> ingredients = ingredientRepository.findAll();
        // 혹시 날짜가 지났을 수 있으니 전체 조회할 때 상태를 한 번 더 최신화해줌
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
        // 유통기한과 오늘 날짜의 차이 계산 (남은 일수)
        long daysLeft = ChronoUnit.DAYS.between(today, ingredient.getExpirationDate());

        if (daysLeft < 0 || ingredient.getQuantity() <= 0) {
            ingredient.setStatus("소진"); // 유통기한이 지났거나 수량이 0 이하일 때
        } else if (daysLeft <= 3) {
            ingredient.setStatus("임박"); // 유통기한이 3일 이하로 남았을 때
        } else {
            ingredient.setStatus("충분"); // 유통기한이 4일 이상 넉넉히 남았을 때
        }
    }
}