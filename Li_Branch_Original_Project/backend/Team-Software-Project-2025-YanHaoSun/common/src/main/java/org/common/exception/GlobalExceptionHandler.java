package org.common.exception;

import org.common.dto.ApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import java.util.stream.Collectors;

/**
 * 全局异常处理器
 * 统一处理所有未捕获的异常，并格式化为标准的API响应
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * 处理业务异常
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Object>> handleBusinessException(BusinessException ex, WebRequest request) {
        logger.warn("Business exception: {}", ex.getMessage());
        
        ApiResponse<Object> response = ApiResponse.error(
            ex.getErrorCode(),
            ex.getMessage(),
            ex.getDetails()
        );
        
        return ResponseEntity.status(ex.getHttpStatus()).body(response);
    }

    /**
     * 处理参数验证异常
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Object>> handleValidationException(MethodArgumentNotValidException ex) {
        logger.warn("Validation exception: {}", ex.getMessage());
        
        String errorMessage = ex.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.joining(", "));
        
        ApiResponse<Object> response = ApiResponse.error(
            "VALIDATION_ERROR",
            "参数验证失败",
            errorMessage
        );
        
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * 处理绑定异常
     */
    @ExceptionHandler(BindException.class)
    public ResponseEntity<ApiResponse<Object>> handleBindException(BindException ex) {
        logger.warn("Bind exception: {}", ex.getMessage());
        
        String errorMessage = ex.getFieldErrors().stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.joining(", "));
        
        ApiResponse<Object> response = ApiResponse.error(
            "BIND_ERROR",
            "参数绑定失败",
            errorMessage
        );
        
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * 处理约束验证异常
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Object>> handleConstraintViolationException(ConstraintViolationException ex) {
        logger.warn("Constraint violation exception: {}", ex.getMessage());
        
        String errorMessage = ex.getConstraintViolations().stream()
            .map(ConstraintViolation::getMessage)
            .collect(Collectors.joining(", "));
        
        ApiResponse<Object> response = ApiResponse.error(
            "CONSTRAINT_VIOLATION",
            "约束验证失败",
            errorMessage
        );
        
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * 处理类型不匹配异常
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<Object>> handleTypeMismatchException(MethodArgumentTypeMismatchException ex) {
        logger.warn("Type mismatch exception: {}", ex.getMessage());
        
        String details = String.format("参数 '%s' 的值 '%s' 无法转换为 %s 类型", 
            ex.getName(), ex.getValue(), ex.getRequiredType().getSimpleName());
        
        ApiResponse<Object> response = ApiResponse.error(
            "TYPE_MISMATCH",
            "参数类型错误",
            details
        );
        
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * 处理HTTP消息不可读异常
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Object>> handleHttpMessageNotReadableException(HttpMessageNotReadableException ex) {
        logger.warn("Http message not readable exception: {}", ex.getMessage());
        
        ApiResponse<Object> response = ApiResponse.error(
            "MESSAGE_NOT_READABLE",
            "请求体格式错误",
            "请检查JSON格式是否正确"
        );
        
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * 处理HTTP方法不支持异常
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Object>> handleMethodNotSupportedException(HttpRequestMethodNotSupportedException ex) {
        logger.warn("Method not supported exception: {}", ex.getMessage());
        
        String details = String.format("不支持 %s 方法，支持的方法: %s", 
            ex.getMethod(), String.join(", ", ex.getSupportedMethods()));
        
        ApiResponse<Object> response = ApiResponse.error(
            "METHOD_NOT_SUPPORTED",
            "HTTP方法不支持",
            details
        );
        
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(response);
    }

    /**
     * 处理404异常
     */
    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleNoHandlerFoundException(NoHandlerFoundException ex) {
        logger.warn("No handler found exception: {}", ex.getMessage());
        
        String details = String.format("路径 '%s' 不存在", ex.getRequestURL());
        
        ApiResponse<Object> response = ApiResponse.error(
            "NOT_FOUND",
            "接口不存在",
            details
        );
        
        return ResponseEntity.notFound().build();
    }

    /**
     * 处理资源未找到异常
     */
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleResourceNotFoundException(ResourceNotFoundException ex) {
        logger.warn("Resource not found exception: {}", ex.getMessage());
        
        ApiResponse<Object> response = ApiResponse.error(
            "RESOURCE_NOT_FOUND",
            ex.getMessage(),
            ex.getDetails()
        );
        
        return ResponseEntity.notFound().build();
    }

    /**
     * 处理所有其他未捕获的异常
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Object>> handleGenericException(Exception ex, WebRequest request) {
        logger.error("Unexpected exception occurred", ex);
        
        // 在生产环境中，不应该暴露详细的错误信息
        String details = isProductionEnvironment() ? null : ex.getMessage();
        
        ApiResponse<Object> response = ApiResponse.error(
            "INTERNAL_SERVER_ERROR",
            "服务器内部错误",
            details
        );
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }

    /**
     * 检查是否为生产环境
     */
    private boolean isProductionEnvironment() {
        String environment = System.getProperty("spring.profiles.active", "development");
        return "production".equals(environment) || "prod".equals(environment);
    }
}