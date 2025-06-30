package org.allergen.controller;

import org.allergen.pojo.Allergen;
import org.allergen.pojo.DTO.AllergenDto;
import org.common.dto.ApiResponse;
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

@RestController
@RequestMapping("/allergen")
public class AllergenAnalysisController {
    // 需要调用AllergenAnalysis接口, 将商品信息转换为过敏原信息
    // 然后将过敏原信息保存到数据库中
    // 然后将过敏原信息返回给前端
    @Autowired
    IAllergenService allergenService;

    // add new allergen
    @PostMapping
    public ApiResponse<Allergen> postMethodName(@Validated @RequestBody AllergenDto allergenDto) {
        Allergen allergen = allergenService.add(allergenDto);
        return ApiResponse.success(allergen);
    }

    // query product
    @GetMapping("/{allergenId}") // URL: localhost:8088/user/'123456' method: get
    public ApiResponse<Allergen> get(@PathVariable Integer allergenId){
        Allergen allergen = allergenService.get(allergenId);
        return ApiResponse.success(allergen);
    }

    // put mapping
    @PutMapping
    public ApiResponse<Allergen> edit(@Validated @RequestBody AllergenDto allergenDto) {
        Allergen allergen = allergenService.update(allergenDto);
        return ApiResponse.success(allergen);
    }

    // delete mapping
    @DeleteMapping("/{allergenId}")
    public ApiResponse<Allergen> delete(@PathVariable Integer allergenId) {
        allergenService.delete(allergenId);
        return ApiResponse.success();
    }

    // Health check endpoint
    @GetMapping("/health")
    public ApiResponse<String> health() {
        return ApiResponse.success("Allergen service is running", "过敏原服务健康检查通过");
    }
    
}