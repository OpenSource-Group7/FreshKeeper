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

    def _match_ingredient_name(self, recipe_name: str, inventory_df: pd.DataFrame) -> str:
        # 1. 완전 일치
        if recipe_name in inventory_df["재료명"].values:
            return recipe_name
        
        # 2. 재고명이 레시피명을 포함 ("서울 우유".contains("우유") → True)
        contains = inventory_df[inventory_df["재료명"].str.contains(recipe_name, na=False)]
        if not contains.empty:
            return contains.iloc[0]["재료명"]
        
        # 3. 레시피명이 재고명을 포함 ("우유" in "서울 우유" → True)
        for inv_name in inventory_df["재료명"]:
            if inv_name in recipe_name:
                return inv_name
        
        # 매칭 없으면 원본 반환
        return recipe_name

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

        # merge 전에 레시피 재료명을 재고 재료명에 맞게 매핑
        recipe_final["재료명"] = recipe_final["재료명"].apply(
            lambda x: self._match_ingredient_name(x, inventory_final)
        )

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


async def main():
    # 초기화
    inventory_manager = InventoryManager()
    extractor = RecipeExtractor()
    calculator = IngredientCalculator()

    # 재고 불러오기
    inventory_df = inventory_manager.get_inventory()
    if inventory_df is None:
        print("재고 데이터를 불러오지 못했습니다.")
        return

    print("=== 현재 재고 ===")
    print(inventory_df.to_string(index=False))
    print()

    # 레시피 입력
    recipe_url = input("레시피 URL을 입력하세요: ").strip()
    if not recipe_url:
        print("URL이 입력되지 않았습니다.")
        return

    # 자막 추출 (일반 함수 → await 없음)
    transcript = extractor.extract_recipe(recipe_url)
    if not transcript:
        print("자막을 추출하지 못했습니다.")
        return

    # 재료 추출 (async 함수 → await 필요)
    recipe_list = await extractor.extract_data(transcript)
    if not recipe_list:
        print("레시피 재료를 추출하지 못했습니다.")
        return

    print("=== 추출된 레시피 재료 ===")
    print(pd.DataFrame(recipe_list).to_string(index=False))
    print()

    # 부족 재료 계산
    missing_df = calculator.calculate_missing_ingredients(recipe_list, inventory_df, extractor)

    if missing_df.empty:
        print("모든 재료가 충분합니다!")
    else:
        print("=== 구매 필요 재료 ===")
        print(missing_df.to_string(index=False))


if __name__ == "__main__":
    asyncio.run(main())