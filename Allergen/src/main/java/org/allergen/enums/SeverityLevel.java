package org.allergen.enums;

public enum SeverityLevel {
    LOW("低"),
    MEDIUM("中"),
    HIGH("高");

    private final String description;

    SeverityLevel(String description) {
        this.description = description;
    }
} 