package org.user.enums;

public enum NutritionGoal {
    WEIGHT_LOSS("减重"),
    WEIGHT_MAINTENANCE("维持体重"),
    WEIGHT_GAIN("增重"),
    MUSCLE_GAIN("增肌"),
    HEALTH_MAINTENANCE("健康维持");

    private final String description;

    NutritionGoal(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
} 