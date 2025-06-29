package org.common.exception;

/**
 * 资源未找到异常
 * 用于处理找不到资源的情况
 */
public class ResourceNotFoundException extends RuntimeException {
    
    private final String details;

    public ResourceNotFoundException(String message) {
        super(message);
        this.details = null;
    }

    public ResourceNotFoundException(String message, String details) {
        super(message);
        this.details = details;
    }

    public String getDetails() {
        return details;
    }
}