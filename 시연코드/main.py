from fastapi import FastAPI, Depends
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from database import get_db
import models, loginAndRegister, searchYoutubeRecipes
from loginAndRegister import get_current_user
from models import User
from InventoryManager import InventoryManager
from RegularPurchaser import RegularPurchaser
from ShoppinglistManager import ShoppingListManager
from RecipeExtractor import RecipeExtractor
import pandas as pd
from datetime import datetime


class RecipeItem(BaseModel):
    재료: str
    수량: float
    단위: str

class IngredientCreate(BaseModel):
    ingredient_name: str
    quantity: float
    unit: str
    category: str
    expiration_date: str



# 앱 시작 시 테이블이 없는경우 PostgreSQL에 테이블 자동 생성
models.init_db()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

inventory_manager = InventoryManager()
rp = RegularPurchaser()
shopping_manager = ShoppingListManager()
recipe_extractor = RecipeExtractor()


@app.on_event("startup")
async def startup_event():
    try:
        await recipe_extractor.load_whitelist()
    except Exception as e:
        print(f"[경고] 화이트리스트 로드 실패: {e}")


@app.get("/")
def home():
    return {"message": "식재료 관리 및 쇼핑 리스트 시스템 정상 작동 중"}


# 회원가입
@app.post("/register")
def register_user(user_data: loginAndRegister.UserRegister, db: Session = Depends(get_db)):
    return loginAndRegister.register_new_user(user_data, db)


# 로그인 (JWT 반환)
@app.post("/login")
def login_user(user_data: loginAndRegister.UserLogin, db: Session = Depends(get_db)):
    return loginAndRegister.login_user_logic(user_data, db)


# 요리 추천
@app.get("/recommend-recipe")
def recommend_recipe(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    recommended_list = searchYoutubeRecipes.recommend_dishes_from_refrigerator(current_user.id, db)
    return {"status": "success", "recommendations": recommended_list}


# 레시피 검색
@app.get("/search-recipes")
def search_recipes(dish: str, db: Session = Depends(get_db)):
    return searchYoutubeRecipes.search_and_process_recipes(dish, db)


@app.get("/inventory")
def read_inventory(current_user: models.User = Depends(get_current_user)):
    return inventory_manager.get_inventory(current_user.username)


@app.get("/regular-purchase")
def regular_purchase(current_user: models.User = Depends(get_current_user)):
    df = rp.get_list(current_user.username)
    return df.to_dict(orient="records") if not df.empty else {"message": "대상 없음"}

@app.post("/generate-shopping-list")
async def generate_shopping_list(
    youtube_url: str,
    current_user: models.User = Depends(get_current_user)
):
    try:
        text = recipe_extractor.extract_recipe(youtube_url)
        recipe_data = await recipe_extractor.extract_data(text)

        inventory_df = inventory_manager.get_inventory(current_user.username)

        shopping_manager.create_shopping_list(
            recipe_data,
            inventory_df,
            recipe_extractor,
            user_id=current_user.username
        )

        return shopping_manager.get_final_list().to_dict(orient="records")

    except Exception as e:
        return {"error": f"쇼핑 리스트 생성 실패: {str(e)}"}

@app.get("/shopping-list")
def get_shopping_list():
    return shopping_manager.get_final_list().to_dict(orient="records")


@app.post("/shopping-list/add")
def add_to_shopping_list(item: RecipeItem):
    shopping_manager.add_item(item.재료, item.수량, item.단위)
    return {"message": "추가 완료"}

@app.put("/shopping-list/{item_name}")
def update_shopping_item(item_name: str, new_quantity: float):
    shopping_manager.update_item_quantity(item_name, new_quantity)
    return {"message": f"{item_name} 수정 완료"}


@app.delete("/shopping-list/{item_name}")
def delete_shopping_item(item_name: str):
    shopping_manager.remove_item(item_name)
    return {"message": f"{item_name} 삭제 완료"}

@app.delete("/shopping-list-clear")
def clear_shopping_list():
    shopping_manager.clear_list()
    return {"message": "쇼핑 리스트 전체 삭제 완료"}

@app.get("/inventory-detail")
def get_inventory(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    print("토큰 인증 성공:", current_user.username)

    try:
        user_name = current_user.username
        df = inventory_manager.get_inventory_raw(user_name)
        result = df.to_dict(orient="records")
        return result

    except Exception as e:
        print("에러 발생:", e)
        return {
            "username": current_user.username,
            "data": []
        }

import traceback

@app.post("/inventory")
def create_inventory_item(
    item: IngredientCreate,
    current_user: models.User = Depends(get_current_user)
):
    try:
        expiration_date = datetime.strptime(item.expiration_date, "%Y-%m-%d").date()
        new_id = inventory_manager.add_ingredient(
            ingredient_name=item.ingredient_name,
            quantity=item.quantity,
            unit=item.unit,
            category=item.category,
            status="NORMAL",
            expiration_date=item.expiration_date,
            user_id=current_user.username
        )

        if new_id is None:
            return {"error": "추가 실패"}

        return {"message": "추가 완료", "id": new_id}

    except Exception as e:
        print("INVENTORY ERROR")
        print(traceback.format_exc())   # << 이게 핵심
        return {"error": str(e)}


@app.delete("/inventory/{ingredient_id}")
def delete_inventory_item(
    ingredient_id: int,
    current_user: models.User = Depends(get_current_user)
):
    success = inventory_manager.delete_ingredient(current_user.username, ingredient_id)
    if not success:
        return {"error": "삭제 실패 (항목이 없거나 본인 소유가 아닙니다)"}
    return {"message": "삭제 완료"}





