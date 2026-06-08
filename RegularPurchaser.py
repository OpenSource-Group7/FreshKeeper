import pandas as pd
import psycopg2
from InventoryManager import InventoryManager

class RegularPurchaser(InventoryManager):
    def __init__(self):
        super().__init__()

    def get_list(self):
        try:
            conn = psycopg2.connect(**self.db_params)
            query = """
            SELECT 
                ingredient_name, 
                MAX(unit) as unit,
                COUNT(*) as purchase_count,
                AVG(quantity) as avg_purchase_qty
            FROM public.ingredients
            WHERE purchase_date >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY ingredient_name
            HAVING COUNT(*) >= 3;
            """
            df = pd.read_sql_query(query, conn)
            conn.close()

            df = df.rename(columns={
                "ingredient_name": "재료명",
                "purchase_count": "구매횟수",
                "avg_purchase_qty": "평균구매량",
                "unit": "단위"
            })

            
            def convert_unit(row):
                qty = row["평균구매량"]
                unit = str(row["단위"]).lower()
                
                if unit == 'kg':
                    return qty * 1000, 'g'
                elif unit == 'l':
                    return qty * 1000, 'ml'
                return qty, unit

            
            converted = df.apply(convert_unit, axis=1, result_type='expand')
            df["평균구매량"] = converted[0].round(2)
            df["단위"] = converted[1]

            return df
        
        except Exception as e:
            print(f"조회 실패: {e}")
            return pd.DataFrame()