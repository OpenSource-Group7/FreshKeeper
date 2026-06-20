package domain;

import java.util.ArrayList;
import java.util.List;

public class MemoryIngredientRepository implements IngredientRepository {

    // 가상의 데이터베이스 역할을 할 리스트 바구니
    private static List<Ingredient> store = new ArrayList<>();
    private static Long sequence = 0L; // 식재료가 추가될 때마다 1씩 증가할 고유 ID 번호표

    @Override
    public Ingredient save(Ingredient ingredient) {
        // 새 식재료가 들어오면 번호표(ID)를 발급해서 세팅하고 바구니에 저장
        ingredient.setId(++sequence);
        store.add(ingredient);
        return ingredient;
    }

    @Override
    public Ingredient findById(Long id) {
        // 바구니에서 ID가 일치하는 식재료 딱 하나만 찾아서 반환
        for (Ingredient ingredient : store) {
            if (ingredient.getId().equals(id)) {
                return ingredient;
            }
        }
        return null; // 못 찾으면 아무것도 안 줌
    }

    @Override
    public List<Ingredient> findAll() {
        // 냉장고 안의 모든 식재료 목록을 통째로 반환 (전체 조회)
        return new ArrayList<>(store);
    }

    @Override
    public List<Ingredient> findByStatus(String status) {
        // 충분 / 임박 / 소진 중 원하는 상태를 가진 식재료만 필터링해서 리스트로 반환
        List<Ingredient> result = new ArrayList<>();
        for (Ingredient ingredient : store) {
            if (ingredient.getStatus().equals(status)) {
                result.add(ingredient);
            }
        }
        return result;
    }

    @Override
    public void deleteById(Long id) {
        // ID 번호표를 찾아서 해당 식재료를 냉장고 바구니에서 삭제
        store.removeIf(ingredient -> ingredient.getId().equals(id));
    }
    
    // 테스트할 때 바구니를 싹 비우기 위한 청소 메서드
    public void clearStore() {
        store.clear();
        sequence = 0L;
    }
}