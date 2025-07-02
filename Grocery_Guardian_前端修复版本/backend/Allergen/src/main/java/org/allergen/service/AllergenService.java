package org.allergen.service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

import org.allergen.pojo.Allergen;
import org.allergen.pojo.DTO.AllergenDto;
import org.allergen.repository.AllergenRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.demo.springboot_demo.exception.ResourceNotFoundException;

@Service
@Transactional
public class AllergenService implements IAllergenService {
    @Autowired
    private AllergenRepository allergenRepository;


    // add allergen
    @Override
    @Transactional
    public Allergen add(AllergenDto allergenDto) {
        Allergen allergenPojo = new Allergen();
        BeanUtils.copyProperties(allergenDto, allergenPojo);

        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        allergenPojo.setCreatedTime(now.format(formatter));

        return allergenRepository.save(allergenPojo);
    }

    // get allergen
    @Override
    public Allergen get(Integer allergenId) {
        return allergenRepository.findById(allergenId)
            .orElseThrow(() -> new ResourceNotFoundException("Allergen not found with id: " + allergenId));
    
    }

    // update allergen
    @Override
    @Transactional
    public Allergen update(AllergenDto allergenDto) {
        Allergen existingAllergen = allergenRepository.findById(allergenDto.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Allergen not found with id: " + allergenDto.getId()));


        BeanUtils.copyProperties(allergenDto, existingAllergen, "createdAt");
        // if (!allergenRepository.existsById(allergenDto.getId())) {
        //     throw new ResourceNotFoundException("Allergen not found with id: " + allergenDto.getId());
        // }
        // Allergen allergenPojo = new Allergen();
        // BeanUtils.copyProperties(allergenDto, allergenPojo);
        return allergenRepository.save(existingAllergen);
    }

    // delete allergen
    @Override
    @Transactional
    public void delete(Integer allergenId) {
        if (!allergenRepository.existsById(allergenId)) {
            throw new ResourceNotFoundException("Allergen not found with id: " + allergenId);
        }
        allergenRepository.deleteById(allergenId);
    }

    // 获取所有过敏原
    @Override
    public List<Allergen> getAllAllergens() {
        return allergenRepository.findAll();
    }

    // 根据名称搜索过敏原
    public List<Allergen> searchByName(String name) {
        return allergenRepository.findAll().stream()
            .filter(allergen -> allergen.getName().toLowerCase().contains(name.toLowerCase()))
            .collect(Collectors.toList());
    }

    // 检查过敏原是否存在
    public boolean existsById(Integer allergenId) {
        return allergenRepository.existsById(allergenId);
    }

    // DTO转换方法
    // private AllergenDto convertToDto(Allergen allergen) {
    //     AllergenDto dto = new AllergenDto();
    //     dto.setId(allergen.getId());
    //     dto.setName(allergen.getName());
    //     dto.setDescription(allergen.getDescription());
    //     dto.setSeverity(allergen.getSeverity());
    //     return dto;
    // }

    // private Allergen convertToEntity(AllergenDto dto) {
    //     Allergen allergen = new Allergen();
    //     allergen.setId(dto.getId());
    //     allergen.setName(dto.getName());
    //     allergen.setDescription(dto.getDescription());
    //     allergen.setSeverity(dto.getSeverity());
    //     return allergen;
    // }
}
