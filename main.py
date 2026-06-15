from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import get_db
import models, loginAndRegister, searchYoutubeRecipes
from loginAndRegister import get_current_user


# 앱 시작 시 테이블이 없는경우 PostgreSQL에 테이블 자동 생성
models.init_db()

app = FastAPI()

app.add_middleware(     #프론트엔드 테스트 chrome web으로할때 차단 방지
    CORSMiddleware,
    allow_origins=["*"], # 모든 브라우저(플러터 웹 포함)의 접근을 허용하겠다는 뜻
    allow_credentials=True,
    allow_methods=["*"], # GET, POST 등 모든 방식 허용
    allow_headers=["*"], # 모든 헤더 허용
)

#네이버 검색 계획 폐기

#회원가입
@app.post("/register")
def register_user(user_data: loginAndRegister.UserRegister, db: Session = Depends(get_db)):
    return loginAndRegister.register_new_user(user_data, db)

#로그인 (JWT 반환)
@app.post("/login")
def login_user(user_data: loginAndRegister.UserLogin, db: Session = Depends(get_db)):
    return loginAndRegister.login_user_logic(user_data, db)

#요리 이름 추출
@app.get("/recommend-recipe")
def recommend_recipe(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    recommended_list = searchYoutubeRecipes.recommend_dishes_from_refrigerator(current_user.id, db)
    return {"status": "success", "recommendations": recommended_list}

#레시피 검색
@app.get("/search-recipes")
def search_recipes(dish: str, db: Session = Depends(get_db)):
    return searchYoutubeRecipes.search_and_process_recipes(dish, db)