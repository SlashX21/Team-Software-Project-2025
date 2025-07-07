package org.allergen.enums;

public enum SeverityLevel {
    MILD("低"),
    MODERATE("中"),
    SEVERE("高");

    private final String description;

    SeverityLevel(String description) {
        this.description = description;
    }
} 