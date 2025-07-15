package org.user.enums;

public enum SugarSummaryStatus {
    GOOD("Good"),
    WARNING("Warning"),
    OVER_LIMIT("Over Limit");

    // private final String value;
    private final String description;

    SugarSummaryStatus(String description) {
        this.description = description;
    }

    // public String getValue() {
    //     return value;
    // }

    public String getDescription() {
        return description;
    }

    // @Override
    // public String toString() {
    //     return value;
    // }
} 