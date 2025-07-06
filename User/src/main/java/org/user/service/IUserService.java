package org.user.service;

import org.user.pojo.DTO.UserDto;
import org.user.pojo.User;
import java.util.List;
import java.util.Map;

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

    /**
     * get user allergens list
     * @param userId user id
     * @return user allergens list
     */
    Map<String, Object> getUserAllergens(Integer userId);

    /**
     * add user allergen
     * @param userId user id
     * @param allergenId allergen id
     * @param severityLevel severity level (mild, moderate, severe)
     * @param notes notes
     * @return added allergen information
     */
    Map<String, Object> addUserAllergen(Integer userId, Integer allergenId, String severityLevel, String notes);

    /**
     * delete user allergen
     * @param userId user id
     * @param userAllergenId user allergen id
     */
    void deleteUserAllergen(Integer userId, Integer userAllergenId);
}
