package org.user.enums;

public enum GoalLevel {
    STRICT("strict"),
    MODERATE("moderate"),
    RELAXED("relaxed");

    private final String description;

    GoalLevel(String description) {
        this.description = description;
    }
} 