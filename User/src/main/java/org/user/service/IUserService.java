package org.user.service;

import org.user.pojo.DTO.UserDto;
import org.user.pojo.User;

public interface IUserService {
    /**
     * register user
     *
     * @param user
     * @return
     */
    User add(UserDto user);

    /**
     * query user
     * @param userId user id
     * @return
     */
    User getUser(Integer userId);

    /**
     * modify user
     * @param user user object
     * @return
     */
    User edit(UserDto user);

    /**
     * delete user
     * @param userId user id
     * @return
     */
    void delete(Integer userId);

    /**
     * login user
     * @param user user object
     * @return
     */
    User logIn(UserDto user);
}
