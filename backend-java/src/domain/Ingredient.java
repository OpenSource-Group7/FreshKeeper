package domain;

import java.time.LocalDate;

public class Ingredient {

    // 1. 데이터 필드 (식재료 속성)
    private Long id;                // 고유 식별자 (ID)
    private String name;            // 식재료 이름 (예: 우유, 달걀)
    private LocalDate expirationDate; // 유통기한
    private Double quantity;        // 수량
    private String unit;            // 단위 (g, ml, 개 등)
    private String category;        // 보관 카테고리 (냉장, 냉동, 실온)
    private String status;          // 재고 상태 (충분, 임박, 소진)

    // 2. 기본 생성자
    public Ingredient() {
    }

    // 3. 모든 필드를 채우는 생성자 (데이터 넣을 때 사용)
    public Ingredient(Long id, String name, LocalDate expirationDate, Double quantity, String unit, String category, String status) {
        this.id = id;
        this.name = name;
        this.expirationDate = expirationDate;
        this.quantity = quantity;
        this.unit = unit;
        this.category = category;
        this.status = status;
    }

    // 4. Getter 및 Setter 메서드 (데이터 읽고 쓰기 기능)
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public LocalDate getExpirationDate() { return expirationDate; }
    public void setExpirationDate(LocalDate expirationDate) { this.expirationDate = expirationDate; }

    public Double getQuantity() { return quantity; }
    public void setQuantity(Double quantity) { this.quantity = quantity; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}