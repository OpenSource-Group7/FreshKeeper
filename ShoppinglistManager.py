import pandas as pd
import math


from IngredientCalculator import IngredientCalculator
from RegularPurchaser import RegularPurchaser
from RecipeExtractor import RecipeExtractor

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



# ShoppingListManager 클래스 정의

class ShoppingListManager:

    def __init__(self):
        self.calculator = IngredientCalculator()
        self.regular_purchaser = RegularPurchaser()
        self.shopping_list: dict[str, dict] = {}

    def create_shopping_list(
        self, recipe_list: list[dict], inventory_df: pd.DataFrame, extractor: "RecipeExtractor"
    ) -> None:
        
        self.shopping_list.clear()

        
        missing_ingredients_df = self.calculator.calculate_missing_ingredients(
            recipe_list, inventory_df, extractor
        )

        
        regular_purchase_df = self.regular_purchaser.get_list()

        
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