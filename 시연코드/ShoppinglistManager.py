# ShoppingListManager.py
import pandas as pd
import math


from IngredientCalculator import IngredientCalculator
from RegularPurchaser import RegularPurchaser
from RecipeExtractor import RecipeExtractor

#단위 변환 테이블
GRAM_TO_COUNT = {
    "사과": 150, "배": 400, "감": 180, "귤": 100, "오렌지": 200, "레몬": 120, "바나나": 120,
    "양파": 200, "감자": 180, "고구마": 200, "당근": 100, "토마토": 150, "오이": 250, "가지": 200,
    "계란": 60, "달걀": 60, "대파": 300, "파": 300, "쪽파": 200, "마늘": 50, "고추": 20
}
GRAM_TO_PACK = {
    "닭가슴살": 200, "삼겹살": 600, "목살": 600, "항정살": 400, "갈비": 1000, "등심": 300,
    "소고기": 400, "돼지고기": 600, "닭고기": 1000, "베이컨": 150, "햄": 200, "소시지": 300, "어묵": 240
}
ML_TO_BOTTLE = {"물": 500, "생수": 500, "음료수": 500, "콜라": 500, "사이다": 500}
GRAM_TO_MO = {"두부": 300, "순두부": 350}


def convert_to_mart_unit(ingredient: str, qty: float, unit: str) -> tuple[float, str]:
    
    if qty <= 0:
        return 0.0, unit

    if ingredient in GRAM_TO_COUNT and unit == "g":
        return float(math.ceil(qty / GRAM_TO_COUNT[ingredient])), "개"
    if ingredient in GRAM_TO_PACK and unit == "g":
        return float(math.ceil(qty / GRAM_TO_PACK[ingredient])), "팩"
    if ingredient in ML_TO_BOTTLE and unit == "ml":
        return float(math.ceil(qty / ML_TO_BOTTLE[ingredient])), "병"
    if ingredient in GRAM_TO_MO and unit == "g":
        return float(math.ceil(qty / GRAM_TO_MO[ingredient])), "모"
        
    return qty, unit


# ------------------------------------------------------------------ #
# 🛒 ShoppingListManager 클래스 정의
# ------------------------------------------------------------------ #
class ShoppingListManager:

    def __init__(self, user_id=None):
        self.user_id = user_id
        self.calculator = IngredientCalculator()
        self.regular_purchaser = RegularPurchaser()
        self.shopping_list = {}

    def create_shopping_list(
        self, recipe_list: list[dict], inventory_df: pd.DataFrame, extractor: "RecipeExtractor", user_id=None
    ) -> None:
        self.shopping_list.clear()

        effective_user_id = user_id if user_id is not None else self.user_id

        missing_ingredients_df = self.calculator.calculate_missing_ingredients(
            recipe_list, inventory_df, extractor
        )

        regular_purchase_df = self.regular_purchaser.get_list(effective_user_id)

        
        if missing_ingredients_df is not None and not missing_ingredients_df.empty:
            for _, row in missing_ingredients_df.iterrows():
                name = str(row["재료명"])
                qty = float(row["구매필요량"])
                unit = str(row["단위"])
                
                qty, unit = convert_to_mart_unit(name, qty, unit)
                self._add_to_internal_list(name, qty, unit)

        
        if regular_purchase_df is not None and not regular_purchase_df.empty:
            for _, row in regular_purchase_df.iterrows():
                name = str(row["재료명"])
                qty = float(row["평균구매량"])
                unit = str(row["단위"]) if "단위" in row else ""

                qty, unit = convert_to_mart_unit(name, qty, unit)
                self._add_to_internal_list(name, qty, unit)

    def _add_to_internal_list(self, name: str, qty: float, unit: str) -> None:
        if name in self.shopping_list:
            self.shopping_list[name]["수량"] += qty
        else:
            self.shopping_list[name] = {"수량": qty, "단위": unit}

    #사용자 제어 기능

    def add_item(self, name: str, qty: float, unit: str = "") -> None:
        qty, unit = convert_to_mart_unit(name, qty, unit)
        self._add_to_internal_list(name, qty, unit)
        print(f"[수동 추가] {name} {qty} {unit}")

    def remove_item(self, name: str) -> None:
        if name in self.shopping_list:
            del self.shopping_list[name]
            print(f"[수동 삭제] '{name}' 항목 제거 완료")
        else:
            print(f"[삭제 실패] '{name}' 항목이 리스트에 없습니다.")

    def clear_list(self) -> None:
        self.shopping_list.clear()
        print("[전체 삭제] 쇼핑 리스트 초기화 완료")

    def update_item_quantity(self, name: str, new_qty: float) -> None:
        if name in self.shopping_list:
            old_qty = self.shopping_list[name]["수량"]
            self.shopping_list[name]["수량"] = new_qty
            print(f"[수동 수정] {name}: {old_qty} -> {new_qty} ({self.shopping_list[name]['단위']})")
        else:
            print(f"[수정 실패] '{name}' 항목이 리스트에 없습니다.")

    #출력 및 반환

    def get_final_list(self) -> pd.DataFrame:
        if not self.shopping_list:
            return pd.DataFrame(columns=["재료명", "최종수량", "단위"])

        records = []
        for name, info in self.shopping_list.items():
            is_mart_unit = info["단위"] in ["개", "팩", "병", "모"]
            records.append({
                "재료명": name,
                "최종수량": int(info["수량"]) if is_mart_unit else round(info["수량"], 2),
                "단위": info["단위"]
            })
        return pd.DataFrame(records)

    def print_list(self) -> None:
        final_df = self.get_final_list()
        print("\n" + "=" * 45)
        print("           마트 전용 통합 쇼핑 리스트")
        print("=" * 45)
        if final_df.empty:
            print("  쇼핑 리스트가 비어 있습니다.")
        else:
            print(final_df.to_string(index=False))
        print("=" * 45)

    


# # ================================================================== #
# # [전체 연동 테스트 구역]
# # ================================================================== #
# if __name__ == "__main__":
#     import asyncio  # 테스트 구역 안에서만 필요한 모듈은 여기로 이동
    
#     # 💡 테스트를 돌릴 때만 동적으로 외부 모듈을 임포트합니다. (상단 배치 제거)
#     from RecipeExtractor import RecipeExtractor
#     from InventoryManager import InventoryManager

#     async def test_run():
#         print("====================================================")
#         print(" 실제 부품 연동 파이프라인 테스트 시작 (ShoppingListManager 중심)")
#         print("====================================================")

#         extractor = RecipeExtractor()
#         inventory_manager = InventoryManager()
#         shopping_manager = ShoppingListManager()  # 상단 임포트 최소화로 깔끔하게 작동

#         print("구동 단계 0. 기초 데이터 로딩 중...")
#         await extractor.load_whitelist()

#         url = "https://www.youtube.com/watch?v=-BYPCJNm5uo"
#         print(f"\n구동 단계 1. 유튜브 자막 추출 및 데이터 수령 중... (URL: {url})")
#         text = extractor.extract_recipe(url)
        
#         recipe_list = []
#         if text:
#             recipe_list = await extractor.extract_data(text)
#             print(f" 레시피 리스트 수령 성공 ({len(recipe_list)}개 품목)")
#         else:
#             print(" 외부 자막 파싱 불가 상태이므로 연동 테스트용 데이터를 인입합니다.")
#             recipe_list = [
#                 {"재료": "소고기", "수량": "1.5", "단위": "kg"},
#                 {"재료": "양파", "수량": "3", "단위": "개"},
#                 {"재료": "간장", "수량": "300", "단위": "ml"},
#                 {"재료": "두부", "수량": "2", "단위": "모"}
#             ]

#         inventory_df = inventory_manager.get_inventory("fresh")
#         print(f" 냉장고 실재고 데이터 수령 완료 ({len(inventory_df)}개 품목)")

#         print(f"\n매니저 내부에서 계산기/정기구매 파이프라인을 작동시킵니다...")
#         shopping_manager.create_shopping_list(recipe_list, inventory_df, extractor,"fresh")
        
#         shopping_manager.print_list()

#         print(f"\n📝 사용자 직접 제어 기능(CRUD) 시뮬레이션...")
#         shopping_manager.add_item("사과", 450.0, "g")
#         shopping_manager.update_item_quantity("간장", 3.0)
#         shopping_manager.remove_item("양파")

#         print(f"\n🏁 실제 데이터 연동 및 수동 편집이 끝난 [최종 쇼핑 리스트]")
#         shopping_manager.print_list()

#     # 비동기 루프 구동
#     asyncio.run(test_run())