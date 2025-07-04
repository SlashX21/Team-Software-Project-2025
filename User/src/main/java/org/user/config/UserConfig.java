package org.user.config;

import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@ComponentScan(basePackages = "org.user")
public class UserConfig {
    // 确保所有User模块的Bean都被扫描到
} 