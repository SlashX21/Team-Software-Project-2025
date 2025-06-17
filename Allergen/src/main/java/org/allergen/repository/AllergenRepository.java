package org.allergen.repository;

import org.allergen.pojo.Allergen;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AllergenRepository extends JpaRepository<Allergen, Integer> {
    // List<Allergen> findByNameContaining(String name);
    // List<Allergen> findBySeverity(String severity);
}
