package org.user.service;

import org.user.pojo.User;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.user.pojo.DTO.UserDto;
import org.user.repository.UserRepository;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;


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
        // 先查找现有用户
        User existingUser = userRepository.findById(user.getUserId())
            .orElseThrow(() -> new IllegalArgumentException("User not exist."));
        
        // 更新现有用户的属性
        BeanUtils.copyProperties(user, existingUser, "userId", "createdTime");
        
        // 保存更新后的用户
        return userRepository.save(existingUser);
    }

    public void delete(Integer userId){
        userRepository.deleteById(userId);
    }
}