package domain;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.time.LocalDate;

@Service
public class FoodSafetyApiService {

    private final String SERVICE_KEY = "5d1de53ec8b6fddf0e52ffcdc0125e9bfbca37c48c5096b81d8d5f92e2e3d7a2";

    public LocalDate calculateUseByDate(String ingredientName, LocalDate expiryDate) {
        if (expiryDate == null) return LocalDate.now();
        
        int extraDays = getExpiryExtraDaysFromApi(ingredientName);
        return expiryDate.plusDays(extraDays);
    }

    private int getExpiryExtraDaysFromApi(String ingredientName) {
        try {
            String urlStr = "http://apis.data.go.kr/1471000/FoodExp實驗InfoService02/getFoodExp實驗InfoList02"
                    + "?serviceKey=" + SERVICE_KEY
                    + "&prdlst_nm=" + URLEncoder.encode(ingredientName, "UTF-8")
                    + "&type=json"
                    + "&pageNo=1"
                    + "&numOfRows=1";

            URL url = new URL(urlStr);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("Content-type", "application/json");

            if (conn.getResponseCode() >= 200 && conn.getResponseCode() <= 300) {
                BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = rd.readLine()) != null) {
                    sb.append(line);
                }
                rd.close();
                conn.disconnect();

                ObjectMapper objectMapper = new ObjectMapper();
                JsonNode root = objectMapper.readTree(sb.toString());
                JsonNode itemNode = root.path("body").path("items").get(0);

                if (!itemNode.isMissingNode()) {
                    String doubleExtTime = itemNode.path("ext_time").asText(); 
                    if (doubleExtTime != null && !doubleExtTime.isEmpty()) {
                        String cleanNumber = doubleExtTime.replaceAll("[^0-9]", "");
                        return Integer.parseInt(cleanNumber);
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("식약처 Open API 통신 실패 (백업 모드 가동): " + e.getMessage());
        }

        if (ingredientName.contains("우유")) return 45;
        if (ingredientName.contains("두부")) return 20;
        if (ingredientName.contains("계란") || ingredientName.contains("달걀")) return 25;
        
        return 0; 
    }
}
