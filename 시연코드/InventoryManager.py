import pandas as pd
from datetime import datetime
import os
from dotenv import load_dotenv
import psycopg2
from datetime import date
load_dotenv()

class InventoryManager:
    def __init__(self):
        self.db_params = {
            "host": "ep-nameless-dust-aomikbfl-pooler.c-2.ap-southeast-1.aws.neon.tech",
            "database": "neondb",
            "user": os.getenv("PGUSER"),
            "password": os.getenv("PGPASSWORD"),
            "port": "5432",
            "sslmode": "require"
        }

    # 단위 변환 함수
    def convert_units(self, row):
        name = row["ingredient_name"]
        unit = row["unit"]
        qty = row["quantity"]
        
        if unit == "kg" or unit == "KG" or unit == "Kg":
            return pd.Series([qty * 1000.0, "g"])
        elif unit == "L"or unit == "l":
            return pd.Series([qty * 1000.0, "ml"])
        return pd.Series([qty, unit])

    #데이터 추출 및 표 형태로 출력
    def get_inventory(self, user_id):
        print("USER ID =", user_id)
        try:
            conn = psycopg2.connect(**self.db_params)
            cur = conn.cursor()
            query = """
            SELECT id, ingredient_name, quantity, unit, expiration_date
            FROM public.ingredients
            WHERE user_id = %s
            """
            cur.execute(query, (user_id,))
            rows = cur.fetchall()
            colnames = [desc[0] for desc in cur.description]
            cur.close()
            conn.close()

            df = pd.DataFrame(rows, columns=colnames)

            # 재고가 없는 경우 빈 결과 바로 반환
            if df.empty:
                return pd.DataFrame(columns=["재료명", "총재고", "단위"])

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
        except Exception as e:
            print(f"에러 발생: {e}")
            return pd.DataFrame(columns=["재료명", "총재고", "단위"])  # None 대신 빈 DataFrame
        
    def get_inventory_raw(self, user_id):
        print("RAW USER ID =", user_id)

        try:
            conn = psycopg2.connect(**self.db_params)
            cur = conn.cursor()

            query = """
            SELECT *
            FROM public.ingredients
            WHERE user_id = %s
            """

            cur.execute(query, (user_id,))
            rows = cur.fetchall()
            colnames = [desc[0] for desc in cur.description]

            cur.close()
            conn.close()

            df = pd.DataFrame(rows, columns=colnames)

            # 날짜 타입 변환 (있으면)
            if "expiration_date" in df.columns:
                df["expiration_date"] = pd.to_datetime(df["expiration_date"])

            if "purchase_date" in df.columns:
                df["purchase_date"] = pd.to_datetime(df["purchase_date"])
            now = pd.Timestamp.now()

            if "expiration_date" in df.columns:
                df = df[df["expiration_date"] >= now]

            return df

        except Exception as e:
            print(f"[RAW 조회 에러] {e}")
            return pd.DataFrame()
        
    def add_ingredient(self, ingredient_name, quantity, unit, category, status, expiration_date, user_id):
        try:
            conn = psycopg2.connect(**self.db_params)
            cur = conn.cursor()

            query = """
            INSERT INTO public.ingredients
            (ingredient_name, quantity, unit, category, status, expiration_date, purchase_date, user_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """

            cur.execute(query, (
                ingredient_name,
                quantity,
                unit,
                category,
                status,
                expiration_date,
                date.today(),
                user_id  
            ))

            new_id = cur.fetchone()[0]
            conn.commit()

            cur.close()
            conn.close()

            return new_id

        except Exception as e:
            print(f"[추가 에러] {e}")
            return None


    def delete_ingredient(self, user_id, ingredient_id):
        try:
            conn = psycopg2.connect(**self.db_params)
            cur = conn.cursor()
            query = """
            DELETE FROM public.ingredients
            WHERE id = %s AND user_id = %s
            """
            cur.execute(query, (ingredient_id, user_id))
            deleted_count = cur.rowcount
            conn.commit()
            cur.close()
            conn.close()
            return deleted_count > 0
        except Exception as e:
            print(f"[삭제 에러] {e}")
            return False
            
if __name__ == "__main__":
    manager = InventoryManager()

    print("DB 연결 테스트 시작...")

    result = manager.get_inventory("fresh")

    print("\n========== 결과 ==========")
    print(result)