package org.user.service;

import org.user.pojo.User;
import org.allergen.pojo.UserAllergen;
import org.allergen.pojo.Allergen;
import org.allergen.repository.AllergenRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.user.pojo.DTO.UserDto;
import org.user.repository.UserRepository;
import org.user.repository.UserAllergenRepository;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class UserService implements IUserService{

    @Autowired
    UserRepository userRepository;
    
    @Autowired
    UserAllergenRepository userAllergenRepository;
    
    @Autowired
    AllergenRepository allergenRepository;
    
    // login user
    @Override
    public User logIn(UserDto user) {
        // find user by user name and password hash
        User foundUser = userRepository.findByUserNameAndPasswordHash(
            user.getUserName(), 
            user.getPasswordHash()
        );
        
        if (foundUser == null) {
            throw new IllegalArgumentException("Error: user name or password is incorrect.");
        }
        
        return foundUser;
    }

    // register user
    @Override
    public User add(UserDto user) {
        User existingUser = userRepository.findByUserName(user.getUserName());
        if (existingUser == null) {
            throw new IllegalArgumentException("Error: user name already exists.");
        }

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
        BeanUtils.copyProperties(user, userPojo);
        return userRepository.save(userPojo);
    }

    public void delete(Integer userId){
        userRepository.deleteById(userId);
    }

    @Override
    public Map<String, Object> getUserAllergens(Integer userId) {
        // validate user existence
        User user = userRepository.findById(userId).orElseThrow(() -> 
            new IllegalArgumentException("User not found with id: " + userId));
        
        // query user allergens
        List<UserAllergen> userAllergens = userAllergenRepository.findByUserIdOrderBySeverityLevel(userId);
        
        // build response data
        List<Map<String, Object>> userAllergensList = new ArrayList<>();
        
        for (UserAllergen userAllergen : userAllergens) {
            // query allergen details
            Allergen allergen = allergenRepository.findById(userAllergen.getAllergenId()).orElse(null);
            
            if (allergen != null) {
                Map<String, Object> allergenData = new HashMap<>();
                allergenData.put("userAllergenId", userAllergen.getUserAllergenId());
                allergenData.put("allergenId", allergen.getAllergenId());
                allergenData.put("allergenName", allergen.getName());
                allergenData.put("category", allergen.getCategory());
                
                // convert SeverityLevel enum value
                String severityLevel = "moderate"; // default value
                if (userAllergen.getSeverityLevel() != null) {
                    switch (userAllergen.getSeverityLevel()) {
                        case LOW:
                            severityLevel = "mild";
                            break;
                        case MEDIUM:
                            severityLevel = "moderate";
                            break;
                        case HIGH:
                            severityLevel = "severe";
                            break;
                    }
                }
                allergenData.put("severityLevel", severityLevel);
                
                // note: Allergen module's UserAllergen entity's confirmed field is boolean type, not Boolean
                allergenData.put("confirmed", userAllergen.isConfirmed());
                allergenData.put("notes", userAllergen.getNotes() != null ? 
                    userAllergen.getNotes() : "");
                
                userAllergensList.add(allergenData);
            }
        }
        
        // build final response
        Map<String, Object> response = new HashMap<>();
        response.put("userAllergens", userAllergensList);
        
        return response;
    }

    @Override
    public Map<String, Object> addUserAllergen(Integer userId, Integer allergenId, String severityLevel, String notes) {
        // validate user existence
        User user = userRepository.findById(userId).orElseThrow(() -> 
            new IllegalArgumentException("User not found with id: " + userId));
        
        // validate allergen existence
        Allergen allergen = allergenRepository.findById(allergenId).orElseThrow(() -> 
            new IllegalArgumentException("Allergen not found with id: " + allergenId));
        
        // check if user allergen already exists
        List<UserAllergen> existingAllergens = userAllergenRepository.findByUserId(userId);
        for (UserAllergen existing : existingAllergens) {
            if (existing.getAllergenId().equals(allergenId)) {
                // return existing allergen information instead of throwing exception
                Map<String, Object> existingResponse = new HashMap<>();
                existingResponse.put("userAllergenId", existing.getUserAllergenId());
                existingResponse.put("allergenId", allergen.getAllergenId());
                existingResponse.put("allergenName", allergen.getName());
                existingResponse.put("category", allergen.getCategory());
                
                // convert existing severity level to API format
                String existingSeverityLevel = "moderate"; // default
                if (existing.getSeverityLevel() != null) {
                    switch (existing.getSeverityLevel()) {
                        case LOW:
                            existingSeverityLevel = "mild";
                            break;
                        case MEDIUM:
                            existingSeverityLevel = "moderate";
                            break;
                        case HIGH:
                            existingSeverityLevel = "severe";
                            break;
                    }
                }
                existingResponse.put("severityLevel", existingSeverityLevel);
                existingResponse.put("confirmed", existing.isConfirmed());
                existingResponse.put("notes", existing.getNotes() != null ? existing.getNotes() : "");
                existingResponse.put("message", "User already has this allergen");
                existingResponse.put("isExisting", true);
                
                return existingResponse;
            }
        }
        
        // convert severity level string to enum
        org.allergen.enums.SeverityLevel severityEnum;
        try {
            switch (severityLevel.toLowerCase()) {
                case "mild":
                    severityEnum = org.allergen.enums.SeverityLevel.LOW;
                    break;
                case "moderate":
                    severityEnum = org.allergen.enums.SeverityLevel.MEDIUM;
                    break;
                case "severe":
                    severityEnum = org.allergen.enums.SeverityLevel.HIGH;
                    break;
                default:
                    throw new IllegalArgumentException("Invalid severity level. Must be: mild, moderate, or severe");
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid severity level. Must be: mild, moderate, or severe");
        }
        
        // create new user allergen
        UserAllergen userAllergen = new UserAllergen();
        userAllergen.setUserId(userId);
        userAllergen.setAllergenId(allergenId);
        userAllergen.setSeverityLevel(severityEnum);
        userAllergen.setConfirmed(true); // default to confirmed
        userAllergen.setNotes(notes != null ? notes : "");
        
        // save to database
        UserAllergen savedUserAllergen = userAllergenRepository.save(userAllergen);
        
        // build response
        Map<String, Object> response = new HashMap<>();
        response.put("userAllergenId", savedUserAllergen.getUserAllergenId());
        response.put("allergenId", allergen.getAllergenId());
        response.put("allergenName", allergen.getName());
        response.put("category", allergen.getCategory());
        response.put("severityLevel", severityLevel);
        response.put("confirmed", savedUserAllergen.isConfirmed());
        response.put("notes", savedUserAllergen.getNotes());
        response.put("message", "User allergen added successfully");
        response.put("isExisting", false);
        
        return response;
    }

    @Override
    public void deleteUserAllergen(Integer userId, Integer userAllergenId) {
        // validate user existence
        User user = userRepository.findById(userId).orElseThrow(() -> 
            new IllegalArgumentException("User not found with id: " + userId));
        
        // validate user allergen existence
        UserAllergen userAllergen = userAllergenRepository.findById(userAllergenId).orElseThrow(() -> 
            new IllegalArgumentException("User allergen not found with id: " + userAllergenId));
        
        // validate that the allergen belongs to the specified user
        if (!userAllergen.getUserId().equals(userId)) {
            throw new IllegalArgumentException("User allergen does not belong to user: " + userId);
        }
        
        // delete the user allergen
        userAllergenRepository.deleteById(userAllergenId);
    }
}