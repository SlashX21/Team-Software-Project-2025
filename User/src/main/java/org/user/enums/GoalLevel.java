package org.user.enums;

public enum GoalLevel {
    STRICT("STRICT"),
    MODERATE("MODERATE"),
    RELAXED("RELAXED"),
    CUSTOM("CUSTOM");

    private final String description;

    GoalLevel(String description) {
        this.description = description;
    }
} 