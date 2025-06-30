package org.product.enums;

public enum NutritionGoal {
    lose_weight("减重"),
    gain_muscle("增肌"),
    maintain("健康维持");


    private final String description;

    NutritionGoal(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
} 