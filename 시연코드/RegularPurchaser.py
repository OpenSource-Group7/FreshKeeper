import pandas as pd
import psycopg2
from InventoryManager import InventoryManager

class RegularPurchaser(InventoryManager):
    def __init__(self):
        super().__init__()

    def get_list(self, user_id):
        try:
            conn = psycopg2.connect(**self.db_params)
            query = """SELECT ingredient_name, MAX(unit) AS unit, COUNT(*) AS purchase_count, AVG(quantity) AS avg_purchase_qty 
            FROM ingredients
            WHERE 
                user_id = %s
                AND purchase_date >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY ingredient_name
            HAVING COUNT(*) >= 3
            ORDER BY purchase_count DESC;
            """
            df = pd.read_sql_query(query, conn, params=(user_id,))
            conn.close()

            # 1. 컬럼 이름 변경 (수량 이름표를 '수량'으로 통일)
            df = df.rename(columns={
                "ingredient_name": "재료명",
                "purchase_count": "구매횟수",
                "avg_purchase_qty": "평균구매량",
                "unit": "단위"
            })

            # 2. 단위 변환 로직 (kg->g, L->ml)
            def convert_unit(row):
                qty = row["평균구매량"]
                unit = str(row["단위"]).lower()
                
                if unit == "kg" or unit == "KG" or unit == "Kg":
                    return qty * 1000, 'g'
                elif unit == "L"or unit == "l":
                    return qty * 1000, 'ml'
                return qty, unit

            # 변환 적용
            converted = df.apply(convert_unit, axis=1, result_type='expand')
            df["평균구매량"] = converted[0].round(2)
            df["단위"] = converted[1]

            return df
        
        except Exception as e:
            print(f"조회 실패: {e}")
            return pd.DataFrame()

def main():
    rp_analyzer = RegularPurchaser()
    
    print("--- 정기 구매 분석을 시작합니다 ---")
    
    result = rp_analyzer.get_list("fresh")
    
    if not result.empty:
        print(f"\n총 {len(result)}개의 정기 구매 대상 품목이 확인되었습니다.\n")
        print(result.to_string(index=False))
    else:
        print("\n최근 30일 이내에 3회 이상 구매한 품목이 없습니다.")


if __name__ == "__main__":
    main()