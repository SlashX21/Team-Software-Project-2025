
// package com.demo.backend;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.context.ApplicationContext;
// import org.springframework.web.bind.annotation.GetMapping;
// import org.springframework.web.bind.annotation.RestController;

// @RestController
// public class TestController {
    
//     @Autowired
//     private ApplicationContext applicationContext;
    
//     @GetMapping("/test")
//     public String test() {
//         return "Spring Boot is working!";
//     }
    
//     @GetMapping("/beans")
//     public String listBeans() {
//         StringBuilder sb = new StringBuilder();
//         String[] beanNames = applicationContext.getBeanDefinitionNames();
//         sb.append("Total beans: ").append(beanNames.length).append("\n\n");
        
//         for (String beanName : beanNames) {
//             if (beanName.toLowerCase().contains("controller") || 
//                 beanName.toLowerCase().contains("user")) {
//                 sb.append(beanName).append(" -> ")
//                   .append(applicationContext.getBean(beanName).getClass().getName())
//                   .append("\n");
//             }
//         }
//         return sb.toString();
//     }
=======
// package com.demo.backend;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.context.ApplicationContext;
// import org.springframework.web.bind.annotation.GetMapping;
// import org.springframework.web.bind.annotation.RestController;

// @RestController
// public class TestController {
    
//     @Autowired
//     private ApplicationContext applicationContext;
    
//     @GetMapping("/test")
//     public String test() {
//         return "Spring Boot is working!";
//     }
    
//     @GetMapping("/beans")
//     public String listBeans() {
//         StringBuilder sb = new StringBuilder();
//         String[] beanNames = applicationContext.getBeanDefinitionNames();
//         sb.append("Total beans: ").append(beanNames.length).append("\n\n");
        
//         for (String beanName : beanNames) {
//             if (beanName.toLowerCase().contains("controller") || 
//                 beanName.toLowerCase().contains("user")) {
//                 sb.append(beanName).append(" -> ")
//                   .append(applicationContext.getBean(beanName).getClass().getName())
//                   .append("\n");
//             }
//         }
//         return sb.toString();
//     }

// } 