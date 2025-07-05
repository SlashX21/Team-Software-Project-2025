package org.user.enums;

public enum ActionTaken {
    AVOIDED("avoided"),
    NONE("none"),
    REMOVE("remove"),
    REPORT("report");

    private final String description;

    ActionTaken(String description) {
        this.description = description;
    }
} 