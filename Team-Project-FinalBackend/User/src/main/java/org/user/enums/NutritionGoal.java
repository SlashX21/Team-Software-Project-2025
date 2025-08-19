package org.user.enums;

public enum NutritionGoal {
    WEIGHT_LOSS("WEIGHT_LOSS"),
    // WEIGHT_MAINTENANCE("WEIGHT_MAINTENANCE"),
    // WEIGHT_GAIN("WEIGHT_GAIN"),
    MUSCLE_GAIN("MUSCLE_GAIN"),
    HEALTH_MAINTENANCE("HEALTH_MAINTENANCE");

    private final String description;

    NutritionGoal(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}