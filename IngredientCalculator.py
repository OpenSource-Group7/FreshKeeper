import asyncio
import pandas as pd
from RecipeExtractor import RecipeExtractor  
from InventoryManager import InventoryManager  

class IngredientCalculator:

    COUNT_TO_GRAM = {
        "사과": 150, "배": 400, "감": 180, "귤": 100, "오렌지": 200, "레몬": 120, "바나나": 120,
        "양파": 200, "감자": 180, "고구마": 200, "당근": 100, "토마토": 150, "오이": 250, "가지": 200,
        "계란": 60, "달걀": 60, "대파": 300, "파": 300, "쪽파": 200, "마늘": 50, "고추": 20, "두부": 300
    }

    def calculate_missing_ingredients(
        self, recipe_list: list[dict], inventory_df: pd.DataFrame, extractor: RecipeExtractor
    ) -> pd.DataFrame:
        
        if not recipe_list:
            return pd.DataFrame(columns=["재료명", "구매필요량", "단위"])

        recipe_df = pd.DataFrame(recipe_list)
        recipe_df["수량"] = pd.to_numeric(recipe_df["수량"], errors="coerce").fillna(0.0)

        recipe_normalized = self._normalize_units(recipe_df, "수량", extractor)
        inventory_normalized = self._normalize_units(inventory_df, "총재고", extractor)

        recipe_final = recipe_normalized.groupby(["재료명", "단위"], as_index=False)["필요량"].sum()
        inventory_final = inventory_normalized.groupby(["재료명", "단위"], as_index=False)["총재고"].sum()

        comparison = pd.merge(recipe_final, inventory_final, on=["재료명", "단위"], how="left").fillna(0)
        comparison["구매필요량"] = (comparison["필요량"] - comparison["총재고"]).clip(lower=0)

        return comparison[comparison["구매필요량"] > 0][["재료명", "구매필요량", "단위"]]

    def _normalize_units(self, df: pd.DataFrame, qty_col: str, extractor: RecipeExtractor) -> pd.DataFrame:
        normalized_rows = []
        name_key = "재료" if "재료" in df.columns else "재료명"

        for _, row in df.iterrows():
            name = str(row[name_key])
            qty = float(row[qty_col])
            unit = str(row["단위"])

            if name in self.COUNT_TO_GRAM and unit in ["개", "대", "단", "통", "모"]:
                qty *= self.COUNT_TO_GRAM[name]
                unit = "g"

            temp_series = pd.Series([qty, unit], index=["수량", "단위"])
            converted = extractor.convert_unit(temp_series)

            normalized_rows.append(
                {"재료명": name, "수량": float(converted.iloc[0]), "단위": str(converted.iloc[1])}
            )

        res_df = pd.DataFrame(normalized_rows)
        return res_df.rename(columns={"수량": "필요량" if qty_col == "수량" else "총재고"})
if __name__ == "__main__":
    import asyncio

    async def main():
        # 1. 재고 목록 가져오기
        inventory_df = InventoryManager().get_inventory()
        
        # 2. 유튜브 자막으로 레시피 재료 추출
        extractor = RecipeExtractor()
        url = "https://www.youtube.com/watch?v=-BYPCJNm5uo"
        text = extractor.extract_recipe(url)
        recipe_data = await extractor.extract_data(text)
        
        # 3. 부족 재료 계산
        calculator = IngredientCalculator()
        result = calculator.calculate_missing_ingredients(recipe_data, inventory_df, extractor)
        
        print("\n=== 사야 할 재료 목록 ===")
        print(result.to_string(index=False) if not result.empty else "재료 충분")

    asyncio.run(main())