package org.user.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum PreferenceSource {
    USER_MANUAL("User Manual"),
    SYSTEM_INFERRED("System Inferred"),
    MIXED("Mixed Source");

    private final String description;

    PreferenceSource(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }

    @JsonCreator
    public static PreferenceSource fromString(String value) {
        if (value == null) {
            return USER_MANUAL; // 默认值
        }
        
        // 处理各种格式的转换
        String normalizedValue = value.toUpperCase().replace("-", "_");
        
        try {
            return PreferenceSource.valueOf(normalizedValue);
        } catch (IllegalArgumentException e) {
            // 如果直接转换失败，尝试匹配常见的变体
            switch (normalizedValue) {
                case "MANUAL":
                case "USER":
                case "USER_MANUAL":
                    return USER_MANUAL;
                case "SYSTEM":
                case "INFERRED":
                case "AUTO":
                case "SYSTEM_INFERRED":
                    return SYSTEM_INFERRED;
                case "MIXED":
                case "HYBRID":
                case "COMBINED":
                    return MIXED;
                default:
                    throw new IllegalArgumentException("Unknown PreferenceSource: " + value + 
                        ". Valid values are: USER_MANUAL, SYSTEM_INFERRED, MIXED");
            }
        }
    }
} 