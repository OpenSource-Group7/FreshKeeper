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
        self.api_key = "ab19a9e4fe58eaff6d06a4b96f05c01dee2417c8f971d0443f75c409d425ff44"

        self.base_url = (
            f"http://211.237.50.150:7080/openapi/{self.api_key}"
            f"/xml/Grid_20150827000000000227_1"
        )

        self.ingredient_whitelist: dict[str, str] = {}

    #화이트 리스트 로드

    async def load_whitelist(self) -> None:
        if self.api_key == "sample":
            self.ingredient_whitelist = {
                "소고기": "g", "돼지고기": "g", "닭고기": "g",
                "안심": "g", "콩나물": "g", "청포묵": "모",
                "미나리": "g", "양파": "g", "마늘": "쪽",
                "간장": "ml", "설탕": "g", "소금": "g",
                "참기름": "ml", "고춧가루": "g", "된장": "g",
                "물": "ml",
            }
            print(f"[화이트리스트] 개발용 더미 데이터 {len(self.ingredient_whitelist)}개 로드 완료")
            return

        page_size = 1000
        total: int | None = None
        fetched = 0

        async with httpx.AsyncClient() as client:
            while total is None or fetched < total:
                start = fetched + 1
                end = fetched + page_size
                url = f"{self.base_url}/{start}/{end}"

                try:
                    response = await client.get(url, timeout=10.0)
                    response.raise_for_status()
                    root = ET.fromstring(response.text)

                    if total is None:
                        total = int(root.findtext("totalCnt") or "0")
                        print(f"[화이트리스트] 전체 재료 수: {total}개")

                    rows = root.findall("row")
                    if not rows:
                        break

                    for row in rows:
                        name = (row.findtext("IRDNT_NM") or "").strip()
                        cpcty = (row.findtext("IRDNT_CPCTY") or "").strip()

                        if not name:
                            continue

                        unit_match = re.search(r"[가-힣a-zA-Z]+$", cpcty)
                        unit = unit_match.group() if unit_match else ""

                        if name not in self.ingredient_whitelist:
                            self.ingredient_whitelist[name] = unit

                    fetched += len(rows)

                except Exception as e:
                    print(f"[화이트리스트] 로드 중 에러 (row {start}~{end}): {e}")
                    break

        print(f"[화이트리스트] 로드 완료: {len(self.ingredient_whitelist)}개")

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

    #단위 정규화
    def convert_unit(self, row: pd.Series) -> pd.Series:
        """
        kg → g, L → ml 단위 변환.
        변환 불가 시 원본 값을 그대로 반환.
        """
        try:
            qty = float(row["수량"])
            unit = row["단위"]

            if unit in ["kg", "킬로", "킬로그램"]:
                return pd.Series([qty * 1000.0, "g"])
            elif unit in ["L", "리터"]:
                return pd.Series([qty * 1000.0, "ml"])

            return pd.Series([qty, unit])
        except (ValueError, TypeError):
            return pd.Series([row["수량"], row["단위"]])

    #재료 추출

    async def extract_data(self, text: str) -> list[dict]:
        
        if not text:
            return []

        if not self.ingredient_whitelist:
            await self.load_whitelist()

        results: list[dict] = []
        tokens = self.kiwi.tokenize(text)

        for i, token in enumerate(tokens):
            
            if token.tag != "NNG" or token.form not in self.ingredient_whitelist:
                continue

            ingredient = token.form
            cursor = i + 1

            
            while cursor < len(tokens) and tokens[cursor].tag in [
                "JKO", "JX", "JC", "MAG", "MM"
            ]:
                cursor += 1

            
            if cursor >= len(tokens) or tokens[cursor].tag != "SN":
                continue  

            amount = tokens[cursor].form
            unit = ""

            if cursor + 1 < len(tokens) and tokens[cursor + 1].tag in ["NNG", "SL"]:
                unit = tokens[cursor + 1].form

            if not unit:
                unit = self.ingredient_whitelist.get(ingredient, "")

            results.append({"재료": ingredient, "수량": amount, "단위": unit})

        if not results:
            return []
        
        df = pd.DataFrame(results)

        # 단위 변환
        mask = df["수량"] != ""
        if mask.any():
            def convert_row(row):
                result = self.convert_unit(row)
                return pd.Series([str(result.iloc[0]), str(result.iloc[1])])

            df.loc[mask, ["수량", "단위"]] = df[mask].apply(convert_row, axis=1).values

        # 수량을 숫자로 변환
        df["수량"] = pd.to_numeric(df["수량"], errors="coerce").fillna(0)

        # 같은 재료 + 같은 단위끼리 합산
        df = df.groupby(["재료", "단위"], as_index=False)["수량"].sum()

        # 딕셔너리로 반환
        return df.to_dict("records")


#  실행 테스트

if __name__ == "__main__":

    async def main() -> None:
        extractor = RecipeExtractor()

        print("0. 재료 화이트리스트 로딩")
        await extractor.load_whitelist()

        # 테스트용 유튜브 URL
        url = "https://www.youtube.com/watch?v=-BYPCJNm5uo"

        print("\n1. 유튜브 자막 추출 중")
        text = extractor.extract_recipe(url)

        if not text:
            print("유튜브 자막을 가져오지 못했습니다.")
            return

        
        # 추출한 원본 자막 보여주기
    
        print("\n======================= [추출된 원본 자막] =======================")
        print(text)
        print("==================================================================\n")

        print("2. 형태소 분석 및 재료 추출")
        data = await extractor.extract_data(text)

        print("\n--- 추출 및 정제된 재료 리스트 ---")
        if not data:
            print("추출된 재료 데이터가 없습니다.")
            return

        for item in data:
            qty_str = f"{item['수량']} {item['단위']}".strip() if item["수량"] else "수량 미상"
            print(f"  재료: {item['재료']:<10}  수량: {qty_str}")

asyncio.run(main())


