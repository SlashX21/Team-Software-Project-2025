package com.demo.springboot_demo.repository;

import com.demo.springboot_demo.pojo.User;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository //把这个类注册为Spring Bean
public interface UserRepository extends CrudRepository<User, Integer> {
}
