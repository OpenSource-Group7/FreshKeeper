package domain;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.json.JSONArray;
import org.json.JSONObject;

public class ClovaOcrService {

    // 네이버 클로바 OCR API 정보 (가은이의 고유 키셋)
    private final String apiURL = "https://i6bnj5nnu2.apigw.ntruss.com/custom/v1/54183/a33b6327cf6ca2e4797577cefcda5aae35bc67ed11072e03630b8e6c1f16323e/general";
    private final String secretKey = "RXV1cFdVZmlLWGlyZmFOZ2FNall2V3NhQ1lnV3htWlY=";

    public List<String> extractIngredientsFromReceipt(String imagePath) {
        List<String> ingredientNames = new ArrayList<>();
        String boundary = "---" + UUID.randomUUID().toString(); // Multipart/form-data 전송용 고유 바운더리

        try {
            URL url = new URL(apiURL);
            HttpURLConnection con = (HttpURLConnection) url.openConnection();
            con.setUseCaches(false);
            con.setDoOutput(true);
            con.setDoInput(true);
            con.setRequestMethod("POST");
            
            // 네이버 OCR 규격에 맞게 멀티파트 헤더 세팅
            con.setRequestProperty("Content-Type", "multipart/form-data; boundary=" + boundary);
            con.setRequestProperty("X-OCR-SECRET", secretKey);

            // 1. 네이버가 요구하는 메타데이터 JSON 데이터 만들기
            JSONObject json = new JSONObject();
            json.put("version", "V2");
            json.put("requestId", UUID.randomUUID().toString());
            json.put("timestamp", System.currentTimeMillis());
            
            JSONObject image = new JSONObject();
            String format = imagePath.substring(imagePath.lastIndexOf(".") + 1).toLowerCase();
            if (format.equals("jpg")) format = "jpeg"; // jpg 확장자는 jpeg로 매핑
            
            image.put("format", format); 
            image.put("name", "receipt_image");
            
            JSONArray images = new JSONArray();
            images.put(image);
            json.put("images", images);
            
            String message = json.toString();

            // 2. 진짜 파일과 JSON 데이터를 바운더리로 나누어 전송 (Multipart)
            DataOutputStream wr = new DataOutputStream(con.getOutputStream());
            
            // [파트 1: 메타데이터 JSON 영역]
            wr.writeBytes("--" + boundary + "\r\n");
            wr.writeBytes("Content-Disposition: form-data; name=\"message\"\r\n\r\n");
            wr.write(message.getBytes("UTF-8"));
            wr.writeBytes("\r\n");

            // [파트 2: 진짜 이미지 파일 영역]
            File file = new File(imagePath);
            if (!file.exists()) {
                System.out.println("⚠️ 에러: 지정된 경로에 영수증 파일이 없습니다! 경로를 확인해 주세요: " + imagePath);
                wr.close();
                return ingredientNames;
            }

            wr.writeBytes("--" + boundary + "\r\n");
            wr.writeBytes("Content-Disposition: form-data; name=\"file\"; filename=\"" + file.getName() + "\"\r\n");
            wr.writeBytes("Content-Type: application/octet-stream\r\n\r\n");

            // 이미지 바이트 데이터 스트림 전송
            FileInputStream fis = new FileInputStream(file);
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                wr.write(buffer, 0, bytesRead);
            }
            fis.close();
            
            wr.writeBytes("\r\n");
            wr.writeBytes("--" + boundary + "--\r\n"); // 멀티파트 데이터 종료 닫기
            wr.flush();
            wr.close();

            // 3. 네이버 서버로부터 응답 받기
            int responseCode = con.getResponseCode();
            BufferedReader br;
            if (responseCode == 200) {
                br = new BufferedReader(new InputStreamReader(con.getInputStream(), "UTF-8"));
            } else {
                br = new BufferedReader(new InputStreamReader(con.getErrorStream(), "UTF-8"));
            }

            String inputLine;
            StringBuffer response = new StringBuffer();
            while ((inputLine = br.readLine()) != null) {
                response.append(inputLine);
            }
            br.close();

            // 4. OCR 결과 JSON에서 식재료 단어만 필터링 파싱
            JSONObject jsonResponse = new JSONObject(response.toString());
            
            // 에러 응답 분기 처리
            if (!jsonResponse.has("images")) {
                System.out.println("❌ 네이버 OCR 반환 에러 메시지: " + response.toString());
                return ingredientNames;
            }

            // 🛒 FreshKeeper 식재료 매칭 사전 리스트 (마트 정보, 결제 문구 컷팅용 필터)
            List<String> allowedIngredients = List.of(
                "우유", "달걀", "계란", "삼겹살", "두부", "콩나물", "대파", 
                "소고기", "돼지고기", "닭고기", "양파", "당근", "마늘", "고추", "상추", "깻잎"
            );

            JSONArray imagesArray = jsonResponse.getJSONArray("images");
            if (imagesArray.length() > 0) {
                JSONArray fields = imagesArray.getJSONObject(0).getJSONArray("fields");
                for (int i = 0; i < fields.length(); i++) {
                    String inferText = fields.getJSONObject(i).getString("inferText");
                    
                    // 1차 필터: 2글자 이상의 순수 한글만 통과
                    if (inferText.matches("^[가-힣]+$") && inferText.length() >= 2) { 
                        
                        // 2차 필터: ⭐ 지정한 진짜 식재료 사전에 들어있는 단어인지 검증
                        if (allowedIngredients.contains(inferText)) {
                            ingredientNames.add(inferText);
                        }
                    }
                }
            }

        } catch (Exception e) {
            System.out.println("OCR 연동 중 에러 발생: " + e.getMessage());
            e.printStackTrace();
        }

        return ingredientNames;
    }
}