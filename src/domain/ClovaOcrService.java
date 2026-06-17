package domain;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.json.JSONArray;
import org.json.JSONObject;

public class ClovaOcrService {

    // 네이버 클로바 OCR API 정보
    private final String apiURL = "https://i6bnj5nnu2.apigw.ntruss.com/custom/v1/54183/a33b6327cf6ca2e4797577cefcda5aae35bc67ed11072e03630b8e6c1f16323e/general";
    private final String secretKey = "RXV1cFdVZmlLWGlyZmFOZ2FNall2V3NhQ1lnV3htWlY=";

    // 다경이가 공유해 준 Neon PostgreSQL 클라우드 DB 연결 정보
    private final String dbUrl = "jdbc:postgresql://ep-nameless-dust-aomikbfl-pooler.c-2.ap-southeast-1.aws.neon.tech/neondb?sslmode=require";
    private final String dbUser = "neondb_owner";
    private final String dbPassword = "npg_YC6gH8NinfZM"; 

    public List<String> extractIngredientsFromReceipt(String imagePath) {
        List<String> ingredientNames = new ArrayList<>();
        String boundary = "---" + UUID.randomUUID().toString();

        try {
            URL url = new URL(apiURL);
            HttpURLConnection con = (HttpURLConnection) url.openConnection();
            con.setUseCaches(false);
            con.setDoOutput(true);
            con.setDoInput(true);
            con.setRequestMethod("POST");
            
            con.setRequestProperty("Content-Type", "multipart/form-data; boundary=" + boundary);
            con.setRequestProperty("X-OCR-SECRET", secretKey);

            JSONObject json = new JSONObject();
            json.put("version", "V2");
            json.put("requestId", UUID.randomUUID().toString());
            json.put("timestamp", System.currentTimeMillis());
            
            JSONObject image = new JSONObject();
            String format = imagePath.substring(imagePath.lastIndexOf(".") + 1).toLowerCase();
            if (format.equals("jpg")) format = "jpeg";
            
            image.put("format", format); 
            image.put("name", "receipt_image");
            
            JSONArray images = new JSONArray();
            images.put(image);
            json.put("images", images);
            
            String message = json.toString();

            DataOutputStream wr = new DataOutputStream(con.getOutputStream());
            
            wr.writeBytes("--" + boundary + "\r\n");
            wr.writeBytes("Content-Disposition: form-data; name=\"message\"\r\n\r\n");
            wr.write(message.getBytes("UTF-8"));
            wr.writeBytes("\r\n");

            File file = new File(imagePath);
            if (!file.exists()) {
                System.out.println("에러: 지정된 경로에 영수증 파일이 없습니다!: " + imagePath);
                wr.close();
                return ingredientNames;
            }

            wr.writeBytes("--" + boundary + "\r\n");
            wr.writeBytes("Content-Disposition: form-data; name=\"file\"; filename=\"" + file.getName() + "\"\r\n");
            wr.writeBytes("Content-Type: application/octet-stream\r\n\r\n");

            FileInputStream fis = new FileInputStream(file);
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                wr.write(buffer, 0, bytesRead);
            }
            fis.close();
            
            wr.writeBytes("\r\n");
            wr.writeBytes("--" + boundary + "--\r\n");
            wr.flush();
            wr.close();

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

            JSONObject jsonResponse = new JSONObject(response.toString());
            
            if (!jsonResponse.has("images")) {
                System.out.println(" 네이버 OCR 반환 에러 메시지: " + response.toString());
                return ingredientNames;
            }

            // 마트 정보, 결제용 노이즈 텍스트 차단 리스트
            List<String> noiseWords = List.of(
                "과세", "면세", "합계", "금액", "부가세", "포인트", "할인", "결제", 
                "카드", "현금", "수량", "단가", "이마트", "홈플러스", "롯데마트", "매장"
            );

            JSONArray imagesArray = jsonResponse.getJSONArray("images");
            if (imagesArray.length() > 0) {
                JSONArray fields = imagesArray.getJSONObject(0).getJSONArray("fields");
                for (int i = 0; i < fields.length(); i++) {
                    String inferText = fields.getJSONObject(i).getString("inferText").trim();
                    
                    // 1. 숫자가 포함된 텍스트는 단가/금액/사업자번호이므로 제외
                    if (inferText.matches(".*\\d.*")) {
                        continue;
                    }

                    // 2. 특수문자나 단독 영문자 노이즈 제거
                    if (inferText.matches("^[\\W_]+$") || inferText.length() < 2) {
                        continue;
                    }

                    // 3. 결제 관련 노이즈 단어가 포함되어 있다면 제외
                    boolean isNoise = false;
                    for (String noise : noiseWords) {
                        if (inferText.contains(noise)) {
                            isNoise = true;
                            break;
                        }
                    }

                    // 4. 모든 필터를 무사히 통과한 진짜 식재료/음식 품목만 추가
                    if (!isNoise) {
                        ingredientNames.add(inferText);
                    }
                }
            }

            if (!ingredientNames.isEmpty()) {
                saveIngredientsToNeonDatabase(ingredientNames);
            }

        } catch (Exception e) {
            System.out.println("OCR 연동 중 에러 발생: " + e.getMessage());
            e.printStackTrace();
        }

        return ingredientNames;
    }

    // JDBC를 사용하여 Neon DB에 데이터를 적재하는 프라이빗 헬퍼 함수
    private void saveIngredientsToNeonDatabase(List<String> ingredients) {
        String sql = "INSERT INTO ingredients (name, category, qty, reg_date) VALUES (?, '냉장', 1, CURRENT_DATE)";
        
        try {
            Class.forName("org.postgresql.Driver");
            
            try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {
                
                for (String name : ingredients) {
                    pstmt.setString(1, name);
                    pstmt.addBatch();
                }
                
                int[] count = pstmt.executeBatch();
                System.out.println("성공적으로 " + count.length + "개의 식재료 데이터를 클라우드에 영구 저장했습니다");
                
            }
        } catch (ClassNotFoundException e) {
            System.out.println("에러: PostgreSQL JDBC 드라이버를 찾을 수 없습니다. 빌드 패스를 확인해 주세요.");
            e.printStackTrace();
        } catch (Exception e) {
            System.out.println("Neon DB 데이터 저장 중 에러 발생: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
