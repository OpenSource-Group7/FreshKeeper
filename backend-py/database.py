from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# 본인의 PostgreSQL 정보 입력 (ID, PW, 주소, DB이름)
DATABASE_URL = os.environ.get("DBLINK")
#"postgresql://neondb_owner:~~" 이런식으로 되어있는 url

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# API가 요청될 때마다 DB 세션을 열고 닫아주는 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()