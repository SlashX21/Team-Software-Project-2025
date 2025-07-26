package org.user.enums;

public enum ActionTaken {
    AVOIDED("avoided"),
    NO_ACTION("no_action"),
    PURCHASED("purchased"),
    UNKNOWN("unknown");

    private final String description;

    ActionTaken(String description) {
        this.description = description;
    }
} 