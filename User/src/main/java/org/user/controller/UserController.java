package org.user.controller;

// import org.demo.springboot_demo.pojo.DTO.ResponseMessage;
// import com.demo.springboot_demo.pojo.DTO.UserDto;
// import com.demo.springboot_demo.pojo.User;
// import com.demo.springboot_demo.service.IUserService;


import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.user.service.IUserService;
import org.user.service.IUserHistoryService;
import org.user.pojo.DTO.UserHistoryResponseDto;
import org.user.pojo.DTO.UserHistoryListDto;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import java.util.HashMap;
import java.util.Map;


@RestController //允许接口方法返回对象, 并且对象可以直接转换为json文本
@RequestMapping("/user") // 这样子前端就可以使用 localhost:8080/user/**来访问
public class UserController {
    @Autowired IUserService userService;
    @Autowired IUserHistoryService userHistoryService;

    // Register user
    @PostMapping // URL: localhost:8080/user/ method: post
    public ResponseMessage<User> add(@Validated @RequestBody UserDto user){
        System.out.println("Register user success");
        User userNew = userService.add(user);
        return ResponseMessage.success(userNew);
    }

    // Login user
    @PostMapping("/login") // URL: localhost:8080/user/login method: post
    public ResponseMessage<User> login(@Validated @RequestBody UserDto user){
        System.out.println("User login attempt for: " + user.getUserName());
        User userNew = userService.logIn(user);
        System.out.println("User login success for: " + user.getUserName());
        return ResponseMessage.success(userNew);
    }

    // query user
    @GetMapping("/{userId}") // URL: localhost:8080/user/1 method: get
    public ResponseMessage<User> get(@PathVariable Integer userId){
        User userNew = userService.getUser(userId);
        return ResponseMessage.success(userNew);
    }
    
    // edit user
    // put mapping
    @PutMapping // URL: localhost:8080/user/ method: put
    public ResponseMessage<User> edit(@Validated @RequestBody UserDto user){
        User userNew = userService.edit(user);
        return ResponseMessage.success(userNew);
    }

    // delete user
    @DeleteMapping("/{userId}") // URL: localhost:8080/user/1 method: delete
    public ResponseMessage<User> delete(@PathVariable Integer userId){
        userService.delete(userId);
        return ResponseMessage.success();
    }
    
    /**
     * Obtain specific user's all history records
     */
    @GetMapping("/{userId}/history")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getUserHistory(
            @PathVariable Integer userId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String range) {
        
        try {
            // parameter validation
            if (page < 1) page = 1;
            if (limit < 1 || limit > 100) limit = 20;
            
            // get history records
            Page<UserHistoryListDto> historyPage = userHistoryService.getUserHistory(
                    userId, page, limit, search, type, range);
            
            // build response data
            Map<String, Object> data = new HashMap<>();
            data.put("items", historyPage.getContent());
            data.put("totalCount", historyPage.getTotalElements());
            data.put("currentPage", page);
            data.put("totalPages", historyPage.getTotalPages());
            data.put("hasMore", historyPage.hasNext());
            
            // build response
            ResponseMessage<Map<String, Object>> response = new ResponseMessage<>(200, "Success", data);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Obtain specific user's history record by historyId
     */
    @GetMapping("/{userId}/history/{historyId}")
    public ResponseEntity<ResponseMessage<UserHistoryResponseDto>> getUserHistoryById(
            @PathVariable Integer userId,
            @PathVariable String historyId) {
                UserHistoryResponseDto history;
        try{
            history = userHistoryService.getUserHistoryById(userId, historyId);
        }
        catch (Exception e){
            ResponseMessage<UserHistoryResponseDto> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
        return ResponseEntity.ok(ResponseMessage.success(history));
    }
    
    @DeleteMapping("/{userId}/history/{historyId}")
    public ResponseEntity<ResponseMessage<String>> deleteUserHistoryById(
            @PathVariable Integer userId,
            @PathVariable String historyId) {
        userHistoryService.deleteUserHistoryById(userId, historyId);
        return ResponseEntity.ok(ResponseMessage.success("History record deleted successfully!"));
    }

    /**
     * Get user history statistics
     */
    @GetMapping("/{userId}/history/statistics")
    public ResponseEntity<ResponseMessage<Map<String, Object>>> getUserHistoryStats(
            @PathVariable Integer userId,
            @RequestParam(defaultValue = "month") String period) {
        
        try {
            Map<String, Object> stats = userHistoryService.getUserHistoryStats(userId, period);
            ResponseMessage<Map<String, Object>> response = new ResponseMessage<>(200, "Success", stats);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            ResponseMessage<Map<String, Object>> errorResponse = new ResponseMessage<>(
                    500, "Internal server error: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}
