package org.user.controller;

// import org.demo.springboot_demo.pojo.DTO.ResponseMessage;
// import com.demo.springboot_demo.pojo.DTO.UserDto;
// import com.demo.springboot_demo.pojo.User;
// import com.demo.springboot_demo.service.IUserService;


import org.common.dto.ApiResponse;
import org.user.pojo.DTO.UserDto;
import org.user.pojo.User;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.user.service.IUserService;


@RestController //允许接口方法返回对象, 并且对象可以直接转换为json文本
@RequestMapping("/user") // 这样子前端就可以使用 localhost:8080/user/**来访问
public class UserController {

    @Autowired
    IUserService userService;

    // Register user
    @PostMapping // URL: localhost:8080/user/ method: post
    public ApiResponse<User> add(@Validated @RequestBody UserDto user){
        System.out.println("Register user success");
        User userNew = userService.add(user);
        return ApiResponse.success(userNew);
    }

    // Login user
    @PostMapping("/login") // URL: localhost:8080/user/login method: post
    public ApiResponse<User> login(@Validated @RequestBody UserDto user){
        System.out.println("User login attempt for: " + user.getUserName());
        User userNew = userService.logIn(user);
        System.out.println("User login success for: " + user.getUserName());
        return ApiResponse.success(userNew);
    }

    // query user
    @GetMapping("/{userId}") // URL: localhost:8080/user/1 method: get
    public ApiResponse<User> get(@PathVariable Integer userId){
        User userNew = userService.getUser(userId);
        return ApiResponse.success(userNew);
    }
    // 修改
    // put mapping
    @PutMapping // URL: localhost:8080/user/ method: put
    public ApiResponse<User> edit(@Validated @RequestBody UserDto user){
        User userNew = userService.edit(user);
        return ApiResponse.success(userNew);
    }

    // 删除
    // delete mapping
    @DeleteMapping("/{userId}") // URL: localhost:8080/user/1 method: delete
    public ApiResponse<User> delete(@PathVariable Integer userId){
        userService.delete(userId);
        return ApiResponse.success();
    }

    // Health check endpoint
    @GetMapping("/health")
    public ApiResponse<String> health() {
        return ApiResponse.success("User service is running", "健康检查通过");
    }
}
