package org.allergen.controller;

import org.allergen.pojo.Allergen;
import org.allergen.pojo.DTO.AllergenDto;
import org.allergen.pojo.DTO.ResponseMessage;
import org.allergen.service.IAllergenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

@RestController
@RequestMapping("/allergens")
public class AllergenAnalysisController {
    // 需要调用AllergenAnalysis接口, 将商品信息转换为过敏原信息
    // 然后将过敏原信息保存到数据库中
    // 然后将过敏原信息返回给前端
    @Autowired
    IAllergenService allergenService;

    // add new allergen
    @PostMapping
    public ResponseMessage<Allergen> postMethodName(@Validated @RequestBody AllergenDto allergenDto) {
        Allergen allergen = allergenService.add(allergenDto);
        return ResponseMessage.success(allergen);
    }

    // query product
    @GetMapping("/{allergenId}") // URL: localhost:8088/allergens/123456 method: get
    public ResponseMessage<Allergen> get(@PathVariable Integer allergenId){
        Allergen allergen = allergenService.get(allergenId);
        return ResponseMessage.success(allergen);
    }

    // put mapping
    @PutMapping
    public ResponseMessage<Allergen> edit(@Validated @RequestBody AllergenDto allergenDto) {
        Allergen allergen = allergenService.update(allergenDto);
        return ResponseMessage.success(allergen);
    }

    // delete mapping
    @DeleteMapping("/{allergenId}")
    public ResponseMessage<Allergen> delete(@PathVariable Integer allergenId) {
        allergenService.delete(allergenId);
        return ResponseMessage.success();
    }

    /**
     * Get all allergens dictionary
     * GET /allergens
     */
    @GetMapping
    public ResponseMessage<Map<String, Object>> getAllAllergens() {
        try {
            List<Allergen> allergens = allergenService.getAllAllergens();
            
            // build response data
            List<Map<String, Object>> allergensList = new ArrayList<>();
            
            for (Allergen allergen : allergens) {
                Map<String, Object> allergenData = new HashMap<>();
                allergenData.put("allergenId", allergen.getAllergenId());
                allergenData.put("name", allergen.getName());
                allergenData.put("category", allergen.getCategory());
                allergenData.put("isCommon", allergen.isIsCommon());
                allergenData.put("description", allergen.getDescription());
                allergensList.add(allergenData);
            }
            
            // build final response
            Map<String, Object> response = new HashMap<>();
            response.put("allergens", allergensList);
            
            return ResponseMessage.success(response);
            
        } catch (Exception e) {
            return new ResponseMessage<>(500, "Internal server error: " + e.getMessage(), null);
        }
    }
}