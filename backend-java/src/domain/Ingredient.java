package domain;

import java.time.LocalDate;

public class Ingredient {

    private Long id;
    private String name;
    private LocalDate expiryDate;
    private LocalDate useByDate;
    private Double quantity;
    private String unit;
    private String category;
    private String status;

    public Ingredient() {
    }

    public Ingredient(Long id, String name, LocalDate expiryDate, LocalDate useByDate, Double quantity, String unit, String category, String status) {
        this.id = id;
        this.name = name;
        this.expiryDate = expiryDate;
        this.useByDate = useByDate;
        this.quantity = quantity;
        this.unit = unit;
        this.category = category;
        this.status = status;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public LocalDate getExpiryDate() { return expiryDate; }
    public void setExpiryDate(LocalDate expiryDate) { this.expiryDate = expiryDate; }

    public LocalDate getUseByDate() { return useByDate; }
    public void setUseByDate(LocalDate useByDate) { this.useByDate = useByDate; }

    public Double getQuantity() { return quantity; }
    public void setQuantity(Double quantity) { this.quantity = quantity; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
