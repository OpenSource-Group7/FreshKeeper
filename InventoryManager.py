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

   