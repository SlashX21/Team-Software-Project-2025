package org.product.enums;

public enum PreferenceType {
    LIKE("like", "喜欢", 1.5),
    DISLIKE("dislike", "不喜欢", 0.3),
    BLACKLIST("blacklist", "黑名单", 0.0);

    private final String code;
    private final String description;
    private final double weight;

    PreferenceType(String code, String description, double weight) {
        this.code = code;
        this.description = description;
        this.weight = weight;
    }

    public String getCode() {
        return code;
    }

    public String getDescription() {
        return description;
    }

    public double getWeight() {
        return weight;
    }

    /**
     * get the enum value by code
     */
    public static PreferenceType fromCode(String code) {
        for (PreferenceType type : PreferenceType.values()) {
            if (type.code.equals(code)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Unknown preference type code: " + code);
    }

    /**
     * determine if the preference should be recommended based on the weight
     */
    public boolean shouldRecommend() {
        return this.weight > 0;
    }

    @Override
    public String toString() {
        return this.code;
    }
} 