package org.user.enums;

public enum Source {
    MANUAL("manual"),
    SCAN("scan"),
    RECEIPT("receipt");

    private final String description;

    Source(String description) {
        this.description = description;
    }
} 