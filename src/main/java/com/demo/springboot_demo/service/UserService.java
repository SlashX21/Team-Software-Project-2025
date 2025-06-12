package com.demo.springboot_demo.service;

import com.demo.springboot_demo.pojo.DTO.ResponseMessage;
import com.demo.springboot_demo.pojo.DTO.UserDto;
import com.demo.springboot_demo.pojo.User;
import com.demo.springboot_demo.repository.UserRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Service
public class UserService implements IUserService{

    @Autowired
    UserRepository userRepository;
    @Override
    public User add(UserDto user) {
        User userPojo = new User();
        // 把user中的数据复制到userPojo里面
        BeanUtils.copyProperties(user, userPojo);
        
        // 设置当前时间为注册时间
        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        userPojo.setCreatedTime(now.format(formatter));
        
        // 将userPojo中的数据保存到数据库中
        return userRepository.save(userPojo);
    }

    public User getUser(Integer userId){
        return userRepository.findById(userId).orElseThrow(()->{
           throw new IllegalArgumentException("User not exist.");
        });
    }

    public User edit(UserDto user){
        User userPojo = new User();
        // 把user中的数据复制到userPojo里面
        BeanUtils.copyProperties(user, userPojo);
        // 将userPojo中的数据保存到数据库中
        return userRepository.save(userPojo);
    }

    public void delete(Integer userId){
        userRepository.deleteById(userId);
    }
}