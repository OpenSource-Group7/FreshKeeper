from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from InventoryManager import InventoryManager
from RegularPurchaser import RegularPurchaser
from ShoppinglistManager import ShoppingListManager
from RecipeExtractor import RecipeExtractor

class RecipeItem(BaseModel):
    재료: str
    수량: float
    단위: str

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_methods=["*"],
    allow_headers=["*"],
)


inventory_manager = InventoryManager()
rp = RegularPurchaser()
shopping_manager = ShoppingListManager()
recipe_extractor = RecipeExtractor()

@app.on_event("startup")
async def startup_event():
    
    await recipe_extractor.load_whitelist()

@app.get("/")
def home():
    return {"message": "식재료 관리 및 쇼핑 리스트 시스템 정상 작동 중"}

@app.get("/inventory")
def read_inventory():
    return inventory_manager.get_inventory().to_dict(orient="records")

@app.get("/regular-purchase")
def regular_purchase():
    df = rp.get_list()
    return df.to_dict(orient="records") if not df.empty else {"message": "대상 없음"}
