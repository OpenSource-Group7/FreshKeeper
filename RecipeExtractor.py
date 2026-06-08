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

if __name__=="__main__":
    extractor = RecipeExtractor()
    url = "https://www.youtube.com/watch?v=Wh8YL-Iz_kI"
    text = extractor.extract_recipe(url)
    print(text)
    