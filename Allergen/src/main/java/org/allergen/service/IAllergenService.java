package org.allergen.service;

import org.allergen.pojo.Allergen;
import org.allergen.pojo.DTO.AllergenDto;
import java.util.List;

public interface IAllergenService {
    Allergen add(AllergenDto allergen);
    Allergen get(Integer allergenId);
    Allergen update(AllergenDto allergen);
    void delete(Integer allergenId);
    
    /**
     * get all allergens
     * @return all allergens list
     */
    List<Allergen> getAllAllergens();
}
