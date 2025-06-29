package org.allergen.enums;

public enum ActivityLevel {
    SEDENTARY("久坐不动"),
    LIGHTLY_ACTIVE("轻度活动"),
    MODERATELY_ACTIVE("中度活动"),
    VERY_ACTIVE("重度活动"),
    EXTRA_ACTIVE("极度活动");

    private final String description;

    ActivityLevel(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
} 