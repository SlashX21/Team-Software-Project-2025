package com.demo.backend;

import javax.sql.DataSource;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import liquibase.integration.spring.SpringLiquibase;

// Liquibase配置，用于自动创建数据库表结构
@Configuration
public class LiquibaseConfig {
    @Bean
    public SpringLiquibase springLiquibase(DataSource dataSource) {
        SpringLiquibase springLiquibase = new SpringLiquibase();
        springLiquibase.setDataSource(dataSource);
        // 指定changeLog文件的位置, 这里使用的方式是: 一个index文件来引用其他文件
        springLiquibase.setChangeLog("classpath:db/changelog/changelog_index.xml");
        springLiquibase.setContexts("development");
        return springLiquibase;
    }
}
