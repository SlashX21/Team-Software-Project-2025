package com.demo.springboot_demo.service;

import com.demo.springboot_demo.pojo.DTO.UserDto;
import com.demo.springboot_demo.pojo.User;

public interface IUserService {
    /**
     * 插入用户
     *
     * @param user
     * @return
     */
    User add(UserDto user);

    /**
     * 查询用户
     * @param userId 用户Id
     * @return
     */
    User getUser(Integer userId);

    /**
     * 修改用户
     * @param user 需要修改的用户对象
     * @return
     */
    User edit(UserDto user);

    /**
     * 删除用户
     * @param userId 需要删除的用户Id
     * @return
     */
    void delete(Integer userId);
}
