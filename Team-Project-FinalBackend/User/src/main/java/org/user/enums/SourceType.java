package org.user.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum SourceType {
    SCAN("scan"),
    MANUAL("manual"),
    RECEIPT("receipt");

    private final String value;

    SourceType(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static SourceType fromString(String value) {
        if (value == null) {
            return null;
        }
        
        String normalizedValue = value.toLowerCase().trim();
        for (SourceType sourceType : SourceType.values()) {
            if (sourceType.value.equals(normalizedValue)) {
                return sourceType;
            }
        }
        
        throw new IllegalArgumentException("Unknown source type: " + value);
    }

    @Override
    public String toString() {
        return value;
    }
} 