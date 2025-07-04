package org.allergen.enums;

public enum PresenceType {
    PRESENT("存在"),
    ABSENT("不存在");

    private final String description;

    PresenceType(String description) {
        this.description = description;
    }
} 