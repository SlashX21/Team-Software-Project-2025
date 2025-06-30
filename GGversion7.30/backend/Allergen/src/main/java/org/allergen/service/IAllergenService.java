package org.allergen.service;

import java.util.List;

import org.allergen.pojo.Allergen;
import org.allergen.pojo.DTO.AllergenDto;

public interface IAllergenService {
    List<Allergen> getAllAllergens();
    Allergen add(AllergenDto allergen);
    Allergen get(Integer allergenId);
    Allergen update(AllergenDto allergen);
    void delete(Integer allergenId);
}
