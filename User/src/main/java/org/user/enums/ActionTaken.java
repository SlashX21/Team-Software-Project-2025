package org.user.enums;

public enum ActionTaken {
    NONE("无"),
    REMOVE("移除"),
    REPORT("报告");

    private final String description;

    ActionTaken(String description) {
        this.description = description;
    }
} 