package org.allergen.service;

import org.allergen.pojo.Allergen;
import org.allergen.pojo.DTO.AllergenDto;

public interface IAllergenService {
    Allergen add(AllergenDto allergen);
    Allergen get(Integer allergenId);
    Allergen update(AllergenDto allergen);
    void delete(Integer allergenId);
}
