package domain;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class IngredientService {

    private final IngredientRepository ingredientRepository;
    private final FoodSafetyApiService foodSafetyApiService;

    public IngredientService(IngredientRepository ingredientRepository, FoodSafetyApiService foodSafetyApiService) {
        this.ingredientRepository = ingredientRepository;
        this.foodSafetyApiService = foodSafetyApiService;
    }

    public Ingredient register(Ingredient ingredient) {
        LocalDate computedUseByDate = foodSafetyApiService.calculateUseByDate(
            ingredient.getName(), 
            ingredient.getExpiryDate()
        );
        
        ingredient.setUseByDate(computedUseByDate);
        updateIngredientStatus(ingredient);
        return ingredientRepository.save(ingredient);
    }

    public List<Ingredient> getAllIngredients() {
        List<Ingredient> ingredients = ingredientRepository.findAll();
        for (Ingredient ingredient : ingredients) {
            updateIngredientStatus(ingredient);
        }
        return ingredients;
    }

    public List<Ingredient> getIngredientsByStatus(String status) {
        return ingredientRepository.findByStatus(status);
    }

    public void removeIngredient(Long id) {
        ingredientRepository.deleteById(id);
    }

    private void updateIngredientStatus(Ingredient ingredient) {
        if (ingredient.getExpiryDate() == null) {
            ingredient.setStatus("NORMAL");
            return;
        }

        LocalDate today = LocalDate.now();
        long daysLeft = ChronoUnit.DAYS.between(today, ingredient.getExpiryDate());

        if (daysLeft < 0 || ingredient.getQuantity() <= 0) {
            ingredient.setStatus("URGENT");
        } else if (daysLeft <= 3) {
            ingredient.setStatus("WARNING");
        } else {
            ingredient.setStatus("NORMAL");
        }
    }
}
