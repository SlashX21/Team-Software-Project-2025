package com.demo.backend;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestTemplateConfig {
    
    @Bean
    public RestTemplate restTemplate() {
        // 使用默认的RestTemplate，不设置复杂的超时配置
        return new RestTemplate();
    }
} 