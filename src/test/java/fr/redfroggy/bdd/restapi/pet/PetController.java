package fr.redfroggy.bdd.restapi.pet;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import wiremock.org.apache.commons.lang3.StringUtils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public final class PetController {

    static final String TOTAL_COUNT_HEADER = "X-Total-Count";

    public static List<PetDTO> pets = new ArrayList<>();

    @GetMapping("/pets")
    public ResponseEntity<List<PetDTO>> getAll(@RequestParam(value = "status", required = false) String status,
                                               @RequestParam(value = "page", required = false) Integer page,
                                               @RequestParam(value = "size", required = false) Integer size) {
        List<PetDTO> filtered = pets.stream()
                .filter(p -> StringUtils.isBlank(status) || status.equalsIgnoreCase(p.getStatus()))
                .collect(Collectors.toList());

        List<PetDTO> result = filtered;
        if (page != null && size != null) {
            int from = page * size;
            result = from >= filtered.size()
                    ? Collections.emptyList()
                    : filtered.subList(from, Math.min(from + size, filtered.size()));
        }

        return ResponseEntity.ok()
                .header(TOTAL_COUNT_HEADER, String.valueOf(filtered.size()))
                .body(result);
    }

    @GetMapping("/pets/{id}")
    public ResponseEntity<PetDTO> get(@PathVariable("id") String id) {
        return findById(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/pets")
    public ResponseEntity<PetDTO> addPet(@RequestBody PetDTO pet) {
        if (isInvalid(pet)) {
            return ResponseEntity.badRequest().build();
        }
        if (StringUtils.isBlank(pet.getId())) {
            pet.setId(UUID.randomUUID().toString());
        } else if (findById(pet.getId()).isPresent()) {
            return ResponseEntity.badRequest().build();
        }
        pets.add(pet);
        return ResponseEntity.status(201).body(pet);
    }

    @PutMapping("/pets/{id}")
    public ResponseEntity<PetDTO> updatePet(@RequestBody PetDTO pet, @PathVariable("id") String id) {
        Optional<PetDTO> currentPet = findById(id);
        if (!currentPet.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        if (isInvalid(pet)) {
            return ResponseEntity.badRequest().build();
        }

        PetDTO existing = currentPet.get();
        existing.setName(pet.getName());
        existing.setCategory(pet.getCategory());
        existing.setStatus(pet.getStatus());
        existing.setTags(pet.getTags());
        existing.setPhotoUrls(pet.getPhotoUrls());

        return ResponseEntity.ok(existing);
    }

    @PatchMapping("/pets/{id}")
    public ResponseEntity<PetDTO> patchPet(@RequestBody PetDTO pet, @PathVariable("id") String id) {
        Optional<PetDTO> currentPet = findById(id);
        if (!currentPet.isPresent()) {
            return ResponseEntity.notFound().build();
        }

        PetDTO existing = currentPet.get();
        Optional.ofNullable(pet.getName()).ifPresent(existing::setName);
        Optional.ofNullable(pet.getCategory()).ifPresent(existing::setCategory);
        Optional.ofNullable(pet.getStatus()).ifPresent(existing::setStatus);
        Optional.ofNullable(pet.getTags()).ifPresent(existing::setTags);
        Optional.ofNullable(pet.getPhotoUrls()).ifPresent(existing::setPhotoUrls);

        return ResponseEntity.ok(existing);
    }

    @DeleteMapping("/pets/{id}")
    public ResponseEntity<Void> deletePet(@PathVariable("id") String id) {
        Optional<PetDTO> currentPet = findById(id);
        if (!currentPet.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        pets.remove(currentPet.get());
        return ResponseEntity.ok().build();
    }

    private static Optional<PetDTO> findById(String id) {
        return pets.stream().filter(p -> id.equals(p.getId())).findFirst();
    }

    private static boolean isInvalid(PetDTO pet) {
        return StringUtils.isBlank(pet.getName()) || StringUtils.isBlank(pet.getCategory());
    }
}
