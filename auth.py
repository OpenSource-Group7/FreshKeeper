import bcrypt
import jwt
from datetime import datetime, timedelta

SECRET_KEY = "super_super_super_secret_key" #임시용
ALGORITHM = "HS256"

# 1. 비밀번호 암호화 함수
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# 2. 비밀번호 검증 함수 (로그인할 때 사용)
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# 3. JWT 토큰(출입증) 발급 함수 (일주일 유효)
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=7) # 일주일 유효기간
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)