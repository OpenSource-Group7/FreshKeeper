import bcrypt
import jwt
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from pydantic import BaseModel
import os
from dotenv import load_dotenv
from database import get_db
import models

load_dotenv()

# 회원가입 메인
def register_new_user(user_data, db: Session):
    # 아이디 중복 체크
    existing_user = db.query(models.User).filter(models.User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="이미 존재하는 아이디입니다.")
    
    # 비밀번호 암호화 후 DB 저장
    hashed_pw = hash_password(user_data.password)
    new_user = models.User(username=user_data.username, hashed_password=hashed_pw, nickname=user_data.nickname)
    db.add(new_user)
    db.commit()
    return {"message": "회원가입 성공!"}

# 로그인 메인
def login_user_logic(user_data, db: Session):
    user = db.query(models.User).filter(models.User.username == user_data.username).first()
    
    # 아이디가 없거나 비밀번호가 틀렸을 때
    if not user or not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 틀렸습니다.")
    
    # 로그인 성공. JWT 토큰 구워주기
    token = create_access_token(data={"user_id": user.id, "nickname": user.nickname})
    return {"access_token": token, "token_type": "bearer"}

#-----------------------------------------------------

# 안드로이드가 보낼 데이터 규격 (Pydantic 모델)
class UserRegister(BaseModel):
    username: str
    password: str
    nickname: str

class UserLogin(BaseModel):
    username: str
    password: str

SECRET_KEY =  os.environ.get("SECRET_KEY")
ALGORITHM = "HS256"
security = HTTPBearer()

# 1. 비밀번호 암호화 함수
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# 2. 비밀번호 검증 함수 (로그인할 때 사용)
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# 3. JWT 토큰(출입증) 발급 함수 (일주일 유효)
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=7) # 일주일 유효기간
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# 4. 현재 유저의 토큰 가져오기
def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="인증 토큰 유효기간이 만료되었거나 오류가 발생했습니다.")
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="존재하지 않는 유저입니다.")
    return user