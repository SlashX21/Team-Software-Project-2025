package com.demo.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication(scanBasePackages = {
    "com.demo.backend", 
    "org.user", "org.product", "org.allergen", "org.ocr", "org.recommendation"
})
@EnableJpaRepositories(basePackages = {
    "com.demo.backend", 
    "org.user.repository", "org.product.repository", "org.allergen.repository"
})
@EntityScan(basePackages = {
    "com.demo.backend", 
    "org.user.pojo", "org.product.pojo", "org.allergen.pojo"
})
public class SpringbootDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpringbootDemoApplication.class, args);
    }
}  
=======

package com.demo.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication(scanBasePackages = {
    "com.demo.backend", 
    "org.user", "org.product", "org.allergen", "org.ocr"
})
@EnableJpaRepositories(basePackages = {
    "com.demo.backend", 
    "org.user.repository", "org.product.repository", "org.allergen.repository"
})
@EntityScan(basePackages = {
    "com.demo.backend", 
    "org.user.pojo", "org.product.pojo", "org.allergen.pojo"
})
public class SpringbootDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpringbootDemoApplication.class, args);
    }
}  

