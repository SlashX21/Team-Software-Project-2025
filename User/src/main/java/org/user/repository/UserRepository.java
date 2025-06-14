package org.user.repository;

import org.user.pojo.User;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository //把这个类注册为Spring Bean
public interface UserRepository extends CrudRepository<User, Integer> {
}
