// package com.demo.backend;

// import org.springframework.web.bind.annotation.GetMapping;
// import org.springframework.web.bind.annotation.PostMapping;
// import org.springframework.web.bind.annotation.RequestBody;
// import org.springframework.web.bind.annotation.RequestMapping;
// import org.springframework.web.bind.annotation.RestController;

// import java.util.Map;

// @RestController
// @RequestMapping("/simple-user")
// public class SimpleUserController {
    
//     @GetMapping
//     public String getUser() {
//         return "Simple User Controller is working!";
//     }
    
//     @PostMapping
//     public String addUser(@RequestBody Map<String, Object> user) {
//         return "Received user data: " + user.toString();
//     }
// } 