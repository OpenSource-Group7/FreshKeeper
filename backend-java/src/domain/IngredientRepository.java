package domain;

import java.util.List;

public interface IngredientRepository {
    
    // 1. 새로운 식재료 저장하기 (등록)
    Ingredient save(Ingredient ingredient);
    
    // 2. 고유 식별자(ID)로 특정 식재료 하나만 찾기
    Ingredient findById(Long id);
    
    // 3. 내 냉장고에 있는 모든 식재료 목록 꺼내오기 (전체 조회)
    List<Ingredient> findAll();
    
    // 4. 유통기한 임박이나 소진 등 특정 상태(status)의 식재료만 필터링해서 찾기
    List<Ingredient> findByStatus(String status);
    
    // 5. 다 먹었거나 상한 식재료 ID로 삭제하기
    void deleteById(Long id);
}