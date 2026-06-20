from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from database import Base, engine  # database.py에서 베이스와 엔진을 빌려오기

# 1. 사용자 정보 테이블
class User(Base):
    __tablename__ = "users"     # 실제 PostgreSQL에 생성될 테이블 이름

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)  # 로그인 ID
    hashed_password = Column(String, nullable=False)                    # 암호화된 비밀번호
    nickname = Column(String, nullable=False)                           # 사용자 닉네임
    havingIngredients = Column(String, nullable=True)                   #가진 요리 재료
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# 2. 공공데이터 레시피 테이블
class RecipeTable(Base):
    __tablename__ = "recipes"
    
    id = Column(Integer, primary_key=True, index=True)
    dish = Column(String, nullable=False)        # 요리 이름
    ingredients = Column(String, nullable=False) # 재료들

# 3. 정제된 요리 재료 마스터 테이블
class IngredientTable(Base):
    __tablename__ = "ingredients_master"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False, index=True)

# 데이터베이스의 모든 테이블을 자동으로 생성해주는 안전장치 함수
def init_db():
    Base.metadata.create_all(bind=engine)