import re
from youtube_transcript_api import YouTubeTranscriptApi
from konlpy.tag import Okt
from sqlalchemy.orm import Session
from fastapi import HTTPException
from models import RecipeTable, IngredientTable, User
import yt_dlp



# 요리 이름 추출 메인(전부)
def recommend_dishes_from_refrigerator(user_id: int, db: Session) -> list[dict]:

    '''
    # 임시 데이터
    user_ingredients = [
    "돼지고기", "대파", "양파", "달걀", "밥", "참치", "식용유",
    "참기름", "배추김치", "고춧가루", "청양고추", "배추", "스팸",
    "생수", "소금", "설탕", "간장", "김치", "두부", "식초",
    "고추장", "멸치", "마늘", "기름", "양념"
    ];
    '''
    
    # DB에서 해당 유저의 정보 가져오기
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.havingIngredients:
        return []
    
    # 콤마로 저장된 문자열을 리스트로 변환
    user_ingredients = [
        ing.strip() for ing in user.havingIngredients.split(",") if ing.strip()
    ]

    all_recipes = db.query(RecipeTable).all()
    recommendations = []

    for recipe in all_recipes:
        recipe_ingredients = [i.strip() for i in recipe.ingredients.split(",") if i.strip()]
        
        # DB에 요리 재료가 비어있다면
        if not recipe_ingredients:
            continue
            
        # 1. 텍스트 포함 여부로 내 재료와 매칭 검사
        matched = []
        raw_ingredients_text = recipe.ingredients if recipe.ingredients else ""
        for my_ing in user_ingredients:
            if my_ing in raw_ingredients_text:
                matched.append(my_ing)
        
        # 2. 하나라도 매칭된 재료가 있다면 매칭률 계산
        if matched:
            match_rate = len(matched) / len(recipe_ingredients)

            recommendations.append({
                "dish": recipe.dish,
                "match_rate": min(match_rate, 1.0), 
                "matched_ingredients": matched
            })
            
    recommendations.sort(key=lambda x: x["match_rate"], reverse=True)
    return {
        "recommendations": recommendations[:3],
        "my_ingredients": user_ingredients
    }


# 유튜브 레시피 검색 메인
def search_and_process_recipes(dish: str, db: Session) -> dict:
    if not dish:
        raise HTTPException(status_code=400, detail="검색할 요리명을 입력해주세요.")
        
    raw_videos = search_youtube_recipes(dish)
    final_results = []
    
    for video in raw_videos:
        video_url = video.get("video_url")
        video_id = get_youtube_video_id(video_url)
        
        transcript_text = fetch_youtube_transcript(video_id) if video_id else ""
        
        detected_ingredients = []
        if transcript_text:
            all_nouns = extract_nouns_from_text(transcript_text)
            detected_ingredients = filter_real_ingredients_fast(all_nouns, db)
                    
        if not detected_ingredients:
            detected_ingredients = [dish]

        final_results.append({
            "title": video.get("title"),
            "video_url": video_url,
            "thumbnail_url": video.get("thumbnail_url"),
            "needed_ingredients": detected_ingredients 
        })
        
    return {"status": "success", "youtube_results": final_results}

#---------------------------------------------------------

#유튜브 영상 id 가져오기
def get_youtube_video_id(url: str) -> str:
    match = re.search(r"(?:v=|\/)([0-9A-Za-z_-]{11})", url)
    return match.group(1) if match else None

#유튜브 자막 가져오기
def fetch_youtube_transcript(video_id: str) -> str:
    try:
        ytt_api = YouTubeTranscriptApi()
        transcript_list = ytt_api.list(video_id)
        transcript = transcript_list.find_transcript(['ko'])
        fetched_data = transcript.fetch()
        
        full_text = " ".join([
            item.text if hasattr(item, 'text') else item['text'] 
            for item in fetched_data
        ])
        return full_text
        
    except Exception as e:
        print(f"유튜브 자막 가져오기 실패: {e}")
        return None


#konlpy로 명사뽑기
def extract_nouns_from_text(text: str) -> list[str]:
    if not text:
        return [] 
    
    okt = Okt()
    # 명사만 뽑기
    raw_nouns = okt.nouns(text)
    # 2글자 이상만 남기기
    clean_nouns = [noun for noun in raw_nouns if len(noun) >= 2]
    # 중복된 단어는 제거하고 리스트로 반환
    return list(set(clean_nouns))

#명사에서 재료 찾기
def filter_real_ingredients_fast(extracted_nouns: list[str], db: Session) -> list[str]:
    # DB에서 재료만 리스트로 가져오기 
    db_ingredients = [item[0] for item in db.query(IngredientTable.name).all()]
    # Set을 활용해 교집합 구하기
    matched_set = set(extracted_nouns).intersection(set(db_ingredients))
    # 리스트로 변환해서 반환
    return list(matched_set)



#유튜브 검색
def search_youtube_recipes(dish_name: str) -> list[dict]:
    # 상위 3개 영상만 검색
    search_query = f"ytsearch3:{dish_name} 레시피"
    
    # yt-dlp 설정 정보
    ydl_opts = {
        'quiet': True,
        'extract_flat': True, # 영상 파일 다운로드 없이 오직 메타데이터 정보만 추출
        'skip_download': True,
    }
    video_list = []
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            # 유튜브 검색 가동
            result = ydl.extract_info(search_query, download=False)
            
            if 'entries' in result:
                for entry in result['entries']:
                    video_id = entry.get('id')
                    video_url = f"https://www.youtube.com/watch?v={video_id}"
                    
                    #유튜브 표준 고화질 썸네일 URL 주소 규격 조립
                    thumbnail_url = f"https://img.youtube.com/vi/{video_id}/mqdefault.jpg"
                    
                    video_list.append({
                        "title": entry.get('title'),        #영상 제목
                        "video_url": video_url,             #영상 url
                        "thumbnail_url": thumbnail_url,     #썸네일 이미지 주소
                        "duration": entry.get('duration')   #영상 길이 (초 단위, 필요시 사용)
                    })
    except Exception as e:
        print(f"유튜브 정보 검색 중 오류 발생: {e}")
        
    return video_list
