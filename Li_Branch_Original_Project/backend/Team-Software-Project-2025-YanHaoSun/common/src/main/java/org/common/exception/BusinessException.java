package org.common.exception;

import org.springframework.http.HttpStatus;

/**
 * 业务异常类
 * 用于处理业务逻辑中的异常情况
 */
public class BusinessException extends RuntimeException {
    
    private final String errorCode;
    private final String details;
    private final HttpStatus httpStatus;

    public BusinessException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
        this.details = null;
        this.httpStatus = HttpStatus.BAD_REQUEST;
    }

    public BusinessException(String errorCode, String message, String details) {
        super(message);
        this.errorCode = errorCode;
        this.details = details;
        this.httpStatus = HttpStatus.BAD_REQUEST;
    }

    public BusinessException(String errorCode, String message, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.details = null;
        this.httpStatus = httpStatus;
    }

    public BusinessException(String errorCode, String message, String details, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.details = details;
        this.httpStatus = httpStatus;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public String getDetails() {
        return details;
    }

    public HttpStatus getHttpStatus() {
        return httpStatus;
    }
}