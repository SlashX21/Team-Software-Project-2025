package org.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.ZonedDateTime;

/**
 * 统一API响应格式
 * 符合DEVELOPMENT_STANDARDS.md中定义的响应结构
 *
 * @param <T> 响应数据类型
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "API统一响应格式")
public class ApiResponse<T> {

    @Schema(description = "请求是否成功", example = "true")
    private boolean success;

    @Schema(description = "响应时间戳", example = "2025-06-29T10:30:00Z")
    private ZonedDateTime timestamp;

    @Schema(description = "响应数据")
    private T data;

    @Schema(description = "错误信息")
    private ErrorDetails error;

    @Schema(description = "响应消息", example = "操作成功")
    private String message;

    // 构造函数
    public ApiResponse() {
        this.timestamp = ZonedDateTime.now();
    }

    public ApiResponse(boolean success, T data) {
        this();
        this.success = success;
        this.data = data;
    }

    public ApiResponse(boolean success, T data, String message) {
        this();
        this.success = success;
        this.data = data;
        this.message = message;
    }

    public ApiResponse(boolean success, ErrorDetails error) {
        this();
        this.success = success;
        this.error = error;
    }

    // 静态工厂方法 - 成功响应
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, data);
    }

    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(true, data, message);
    }

    public static <T> ApiResponse<T> success() {
        return success(null, "操作成功");
    }

    public static <T> ApiResponse<T> success(String message) {
        return success(null, message);
    }

    // 静态工厂方法 - 失败响应
    public static <T> ApiResponse<T> error(String code, String message) {
        ErrorDetails error = new ErrorDetails(code, message);
        return new ApiResponse<>(false, error);
    }

    public static <T> ApiResponse<T> error(String code, String message, String details) {
        ErrorDetails error = new ErrorDetails(code, message, details);
        return new ApiResponse<>(false, error);
    }

    public static <T> ApiResponse<T> error(ErrorDetails error) {
        return new ApiResponse<>(false, error);
    }

    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public ZonedDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(ZonedDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }

    public ErrorDetails getError() {
        return error;
    }

    public void setError(ErrorDetails error) {
        this.error = error;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    /**
     * 错误详情类
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    @Schema(description = "错误详情")
    public static class ErrorDetails {
        @Schema(description = "错误代码", example = "BARCODE_NOT_FOUND")
        private String code;

        @Schema(description = "错误消息", example = "未找到该条码对应的商品信息")
        private String message;

        @Schema(description = "错误详情", example = "Barcode: 1234567890")
        private String details;

        public ErrorDetails() {}

        public ErrorDetails(String code, String message) {
            this.code = code;
            this.message = message;
        }

        public ErrorDetails(String code, String message, String details) {
            this.code = code;
            this.message = message;
            this.details = details;
        }

        // Getters and Setters
        public String getCode() {
            return code;
        }

        public void setCode(String code) {
            this.code = code;
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }

        public String getDetails() {
            return details;
        }

        public void setDetails(String details) {
            this.details = details;
        }
    }
}