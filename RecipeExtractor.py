from __future__ import annotations

import re
import asyncio
import xml.etree.ElementTree as ET

import httpx
import youtube_transcript_api
from kiwipiepy import Kiwi
import pandas as pd


class RecipeExtractor:
    def __init__(self, api_key: str = "sample"):
        self.kiwi = Kiwi(num_workers=-1)
        self.yt_api = youtube_transcript_api.YouTubeTranscriptApi()

    def convert_unit(self, row):
        try:
            qty = float(row["수량"])
            unit = row["단위"]
            
            if unit == "kg":
                return pd.Series([qty * 1000.0, "g"])
            elif unit == "L":
                return pd.Series([qty * 1000.0, "ml"])
            return pd.Series([qty, unit])
        except (ValueError, TypeError):
            return pd.Series([row["수량"], row["단위"]])

    #유튜브 자막 추출

    def extract_recipe(self, url: str) -> str | None:
        """
        유튜브 URL에서 자막 텍스트를 추출해 반환한다.
        """
        video_id_match = re.search(r"(?:v=|\/)([0-9A-Za-z_-]{11})", url)
        if not video_id_match:
            raise ValueError("올바른 유튜브 URL이 아닙니다.")

        video_id = video_id_match.group(1)

        try:
            transcript = self.yt_api.fetch(video_id, languages=["ko", "en"])
            return " ".join(snippet.text for snippet in transcript)
        except Exception as e:
            print(f"[자막] 가져오는 중 오류 발생: {e}")
            return None

    def extract_data(self, text):
        if not text:
            return []
            
        results = []
        tokens = self.kiwi.tokenize(text)
        
        for i in range(len(tokens)):
            token = tokens[i]
            
            if token.tag == 'NNG':
                ingredient = token.form
                
                cursor = i + 1
                if cursor < len(tokens) and tokens[cursor].tag.startswith('J'):
                    cursor += 1
                
                if cursor < len(tokens) and tokens[cursor].tag == 'SN':
                    amount = tokens[cursor].form
                    unit = ""
                    
                    if cursor + 1 < len(tokens) and tokens[cursor+1].tag == 'NNG':
                        unit = tokens[cursor+1].form
                    
                    if ingredient not in ['크기', '정도', '시간', '생각', '사람', '데']:
                        results.append({"재료": ingredient, "수량": amount, "단위": unit})
        
        if results:
            df = pd.DataFrame(results)
            df[["수량", "단위"]] = df.apply(self.convert_unit, axis=1)
            return df.to_dict('records')

if __name__=="__main__":
    extractor = RecipeExtractor()
    url = "https://www.youtube.com/watch?v=Wh8YL-Iz_kI"
    text = extractor.extract_recipe(url)
    print(text)
    if text:
        data = extractor.extract_data(text)

        print(("--- 추출된 재료 및 수량 ---"))
        if not data:
            print("추출된 재료 데이터가 없습니다.")
        for item in data:
            print(f"재료: {item['재료']}, 수량: {item['수량']}, 단위: {item['단위']}")
    else:
        print("유튜브 자막을 가져오지 못해 분석을 시작할 수 없습니다.")