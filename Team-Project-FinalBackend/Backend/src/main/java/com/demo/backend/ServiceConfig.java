package com.demo.backend;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import java.time.Duration;

@Configuration
public class ServiceConfig {
    
    /**
     * configure RestTemplate for inter-service calls
     * includes timeout and retry settings
     * used to call other microservices via REST
     */
    @Bean(name = "serviceRestTemplate")
    public RestTemplate serviceRestTemplate(RestTemplateBuilder builder) {
        return builder
                .setConnectTimeout(Duration.ofSeconds(5))
                .setReadTimeout(Duration.ofSeconds(10))
                .build();
    }
} 