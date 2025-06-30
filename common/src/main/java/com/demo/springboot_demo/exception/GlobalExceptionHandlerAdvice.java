package com.demo.springboot_demo.exception;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice // 统一处理异常
public class GlobalExceptionHandlerAdvice {
    Logger log = LoggerFactory.getLogger(GlobalExceptionHandlerAdvice.class);
    @ExceptionHandler({Exception.class}) //@ExceptionHandler 决定了对什么异常进行统一处理, 这里我们设置对所有异常进行处理
    public ResponseMessage handlerException(Exception e, HttpServletRequest request, HttpServletResponse response){
        // 可以记录日志
        log.error("统一异常", e);
        return new ResponseMessage(500, "error", null);
    }
}
