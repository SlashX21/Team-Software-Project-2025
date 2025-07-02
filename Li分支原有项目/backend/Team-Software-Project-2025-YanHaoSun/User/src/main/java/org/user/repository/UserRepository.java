package org.user.repository;

import org.user.pojo.User;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository // register this class as Spring Bean
public interface UserRepository extends CrudRepository<User, Integer> {
    User findByEmail(String email);
    User findByUserName(String userName);
    User findByPasswordHash(String passwordHash);
    // used for user login verification: match both user name and password
    User findByUserNameAndPasswordHash(String userName, String passwordHash);
}
