import pandas as pd
import psycopg2
from datetime import datetime

class InventoryManager:
    def __init__(self):
        self.db_params = {
            "host": "localhost",
            "database": "postgres",
            "user": "postgres",
            "password": "postgresql",
            "port": "5432",
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
