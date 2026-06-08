import asyncio
import pandas as pd
from RecipeExtractor import RecipeExtractor  
from InventoryManager import InventoryManager  

class IngredientCalculator:

    def calculate_missing_ingredients(self, recipe_df, inventory_df):
        recipe_df = recipe_df.groupby(["재료명", "단위"], as_index=False)["필요량"].sum()

        comparison = pd.merge(recipe_df, inventory_df,on=["재료명", "단위"], how="left").fillna(0)
        comparison["구매필요량"] = (comparison["필요량"] - comparison["총재고"]).clip(lower=0)
        
        return comparison[comparison["구매필요량"] > 0][["재료명", "구매필요량", "단위"]]

def test_calculate_missing_ingredients():
    extractor = RecipeExtractor()
    recipe_data = [
            {"재료": "현미쌀", "수량": 2.5, "단위": "kg"},
            {"재료": "닭가슴살", "수량": 1.5, "단위": "kg"},
            {"재료": "양파", "수량": 2.0, "단위": "개"}
        ]
    df = pd.DataFrame(recipe_data)
    df[{"수량","단위"}] = df.apply(extractor.convert_unit,axis=1)
    recipe_df = df.rename(columns={"재료":"재료명", "수량":"필요량"})
    calculator = IngredientCalculator()

    return calculator.calculate_missing_ingredients(recipe_df)
    

if __name__ == "__main__":
    missing_list = test_calculate_missing_ingredients()
    print("\n=== 사야 할 재료 목록 ===")
    print(missing_list.to_string(index=False) if not missing_list.empty else "재료 충분")