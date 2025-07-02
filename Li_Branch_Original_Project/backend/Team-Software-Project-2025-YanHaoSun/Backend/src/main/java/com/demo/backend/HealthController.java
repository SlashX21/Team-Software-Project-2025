package com.demo.backend;

import org.common.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.ZonedDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HealthController {

    @Autowired
    private DataSource dataSource;

    @GetMapping("/health")
    public ApiResponse<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", ZonedDateTime.now());
        health.put("service", "Grocery Guardian Backend");
        health.put("version", "1.0.0");
        
        // Check database connectivity
        try (Connection connection = dataSource.getConnection()) {
            health.put("database", "UP");
            health.put("databaseUrl", connection.getMetaData().getURL());
        } catch (SQLException e) {
            health.put("database", "DOWN");
            health.put("databaseError", e.getMessage());
        }
        
        return ApiResponse.success(health, "Service is healthy");
    }

    @GetMapping("/status")
    public ApiResponse<Map<String, Object>> status() {
        Map<String, Object> status = new HashMap<>();
        status.put("application", "Grocery Guardian");
        status.put("version", "1.0.0");
        status.put("timestamp", ZonedDateTime.now());
        status.put("uptime", System.currentTimeMillis());
        
        // Runtime information
        Runtime runtime = Runtime.getRuntime();
        Map<String, Object> runtime_info = new HashMap<>();
        runtime_info.put("totalMemory", runtime.totalMemory());
        runtime_info.put("freeMemory", runtime.freeMemory());
        runtime_info.put("maxMemory", runtime.maxMemory());
        runtime_info.put("processors", runtime.availableProcessors());
        status.put("runtime", runtime_info);
        
        return ApiResponse.success(status);
    }

    @GetMapping("/version")
    public ApiResponse<String> version() {
        return ApiResponse.success("v1.0.0", "Grocery Guardian Backend Version");
    }
}