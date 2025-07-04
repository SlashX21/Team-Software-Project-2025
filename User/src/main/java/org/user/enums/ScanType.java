package org.user.enums;

public enum ScanType {
    BARCODE("barcode"),
    RECEIPT("receipt");

    private final String description;

    ScanType(String description) {
        this.description = description;
    }
} 