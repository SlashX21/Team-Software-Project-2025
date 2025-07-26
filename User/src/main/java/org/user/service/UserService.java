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
        // validate required fields for registration
        validateUserRegistrationData(user);
        
        // check if username already exists
        User existingUser = userRepository.findByUserName(user.getUserName());
        if (existingUser != null) {
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
        // find existing user
        User existingUser = userRepository.findById(user.getUserId()).orElseThrow(()->{
            throw new IllegalArgumentException("User not exist.");
        });
        
        // copy data from DTO to existing user
        BeanUtils.copyProperties(user, existingUser);
        
        // set updated time
        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        existingUser.setUpdatedTime(now.format(formatter));
        
        return userRepository.save(existingUser);
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
                        case MILD:
                            severityLevel = "mild";
                            break;
                        case MODERATE:
                            severityLevel = "moderate";
                            break;
                        case SEVERE:
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
                // user already bound to this allergen, return error message
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("message", "user already bound to this allergen, cannot add again");
                errorResponse.put("allergenId", allergenId);
                errorResponse.put("allergenName", allergen.getName());
                errorResponse.put("isExisting", true);
                
                return errorResponse;
            }
        }
        
        // convert severity level string to enum
        org.allergen.enums.SeverityLevel severityEnum;
        try {
            switch (severityLevel.toLowerCase()) {
                case "mild":
                    severityEnum = org.allergen.enums.SeverityLevel.MILD;
                    break;
                case "moderate":
                    severityEnum = org.allergen.enums.SeverityLevel.MODERATE;
                    break;
                case "severe":
                    severityEnum = org.allergen.enums.SeverityLevel.SEVERE;
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
        response.put("success", true);
        response.put("userAllergenId", savedUserAllergen.getUserAllergenId());
        response.put("allergenId", allergen.getAllergenId());
        response.put("allergenName", allergen.getName());
        response.put("category", allergen.getCategory());
        response.put("severityLevel", severityLevel);
        response.put("confirmed", savedUserAllergen.isConfirmed());
        response.put("notes", savedUserAllergen.getNotes());
        response.put("message", "allergen bound successfully");
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
    
    /**
     * Validate user registration data
     * @param user UserDto to validate
     * @throws IllegalArgumentException if validation fails
     */
    private void validateUserRegistrationData(UserDto user) {
        // check required fields
        if (user.getHeightCm() == null) {
            throw new IllegalArgumentException("Error: height cannot be empty.");
        }
        if (user.getWeightKg() == null) {
            throw new IllegalArgumentException("Error: weight cannot be empty.");
        }
        if (user.getActivityLevel() == null) {
            throw new IllegalArgumentException("Error: activity level cannot be empty.");
        }
        if (user.getNutritionGoal() == null) {
            throw new IllegalArgumentException("Error: nutrition goal cannot be empty.");
        }
        
        // validate field values
        if (user.getHeightCm() <= 0 || user.getHeightCm() > 300) {
            throw new IllegalArgumentException("Error: height must be between 1-300 cm.");
        }
        if (user.getWeightKg() <= 0 || user.getWeightKg() > 1000) {
            throw new IllegalArgumentException("Error: weight must be between 1-1000 kg.");
        }
        if (user.getAge() != null && (user.getAge() < 0 || user.getAge() > 150)) {
            throw new IllegalArgumentException("Error: age must be between 0-150 years.");
        }
    }
}