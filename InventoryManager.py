import pandas as pd
import psycopg2
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

class InventoryManager:
    def __init__(self):
        self.db_params = {
            "host": "ep-nameless-dust-aomikbfl-pooler.c-2.ap-southeast-1.aws.neon.tech",
            "database": "neondb",
            "user": os.environ.get("PGUSER"),
            "password": os.environ.get("PGPASSWORD"),
            "port": "5432",
            "sslmode": "require"
        }

    # 단위 변환 함수
    def convert_units(self, row):
        name = row["ingredient_name"]
        unit = row["unit"]
        qty = row["quantity"]
        
        if unit == "kg":
            return pd.Series([qty * 1000.0, "g"])
        elif unit == "L":
            return pd.Series([qty * 1000.0, "ml"])
        return pd.Series([qty, unit])

    #데이터 추출 및 표 형태로 출력
    def get_inventory(self):
        try:
            conn = psycopg2.connect(**self.db_params)
            cur = conn.cursor()
            query = "SELECT id, ingredient_name, quantity, unit, expiration_date " \
            "FROM public.ingredients;"
            cur.execute(query)
            
            rows = cur.fetchall()
            colnames = [desc[0] for desc in cur.description]
            cur.close()
            conn.close()

            df = pd.DataFrame(rows, columns=colnames)
            df["quantity"] = pd.to_numeric(df["quantity"])
            df["expiration_date"] = pd.to_datetime(df["expiration_date"])
            df[["std_quantity", "std_unit"]] = df.apply(self.convert_units, axis=1)

            current_date = datetime.now()
            fresh_df = df[df["expiration_date"] >= current_date]

            inventory_summary = fresh_df.groupby(["ingredient_name", "std_unit"])["std_quantity"].sum().reset_index()
            inventory_summary = inventory_summary.rename(
                columns={"ingredient_name": "재료명", "std_quantity": "총재고", "std_unit": "단위"})
            inventory_summary = inventory_summary[["재료명", "총재고", "단위"]]
            return inventory_summary 
        #에러 출력
        except Exception as e:
            print(f"에러 발생: {e}")
            return None

def main():
    print("=" * 50)
    print("Neon DB 재고 조회 테스트")
    print("=" * 50)

    manager = InventoryManager()

    print("\n[1] DB 연결 및 재고 데이터 조회 중...")
    inventory = manager.get_inventory()

    if inventory is not None:
        print("\n[2] 조회 성공 ")
        print(f"    총 재료 종류: {len(inventory)}개\n")
        print(inventory.to_string(index=False))
    else:
        print("\n[2] 조회 실패  - 에러 로그를 확인하세요.")

if __name__ == "__main__":
    main()