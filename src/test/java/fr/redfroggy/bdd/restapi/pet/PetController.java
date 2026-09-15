package fr.redfroggy.bdd.restapi.pet;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import javax.servlet.http.HttpServletRequest;
import org.apache.commons.lang3.StringUtils;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** In-memory petstore-style /api/pets backend for the BDD suite. Write endpoints require auth. */
@RestController
@RequestMapping("/api")
public final class PetController {

  static final List<String> STATUSES = Arrays.asList("available", "pending", "sold");

  static final int MAX_AGE = 100;

  static final int MAX_PAGE_SIZE = 50;

  public static List<PetDTO> pets = new ArrayList<>();

  @GetMapping("/pets")
  public ResponseEntity<List<PetDTO>> getAll(
      @RequestParam(value = "name", required = false) String name,
      @RequestParam(value = "status", required = false) String status,
      @RequestParam(value = "page", required = false) Integer page,
      @RequestParam(value = "size", required = false) Integer size) {
    Stream<PetDTO> stream = pets.stream();
    if (StringUtils.isNotBlank(name)) {
      stream = stream.filter(p -> p.getName().toLowerCase().contains(name.toLowerCase()));
    }
    if (StringUtils.isNotBlank(status)) {
      stream = stream.filter(p -> status.equalsIgnoreCase(p.getStatus()));
    }
    List<PetDTO> result = stream.collect(Collectors.toList());

    if (page != null || size != null) {
      int pageIndex = page == null ? 0 : page;
      int pageSize = size == null ? 10 : size;
      if (pageIndex < 0 || pageSize < 1 || pageSize > MAX_PAGE_SIZE) {
        return ResponseEntity.badRequest().build();
      }
      int from = Math.min(pageIndex * pageSize, result.size());
      int to = Math.min(from + pageSize, result.size());
      result = result.subList(from, to);
    }
    return ResponseEntity.ok()
        .header("X-Total-Count", String.valueOf(pets.size()))
        .body(result);
  }

  @GetMapping("/pets/{id}")
  public ResponseEntity<PetDTO> get(@PathVariable("id") String id) {
    PetDTO pet = find(id);
    if (pet == null) {
      return ResponseEntity.notFound().build();
    }
    return ResponseEntity.ok(pet);
  }

  @PostMapping("/pets")
  public ResponseEntity<PetDTO> add(@RequestBody PetDTO pet, HttpServletRequest request) {
    if (!isAuthenticated(request)) {
      return ResponseEntity.status(401).build();
    }
    if (!isValid(pet)) {
      return ResponseEntity.badRequest().build();
    }
    if (find(pet.getId()) != null) {
      return ResponseEntity.status(409).build();
    }
    if (pet.getStatus() == null) {
      pet.setStatus("available");
    }
    pets.add(pet);
    return ResponseEntity.status(201).body(pet);
  }

  @PutMapping("/pets/{id}")
  public ResponseEntity<PetDTO> update(
      @RequestBody PetDTO pet, @PathVariable("id") String id, HttpServletRequest request) {
    if (!isAuthenticated(request)) {
      return ResponseEntity.status(401).build();
    }
    PetDTO current = find(id);
    if (current == null) {
      return ResponseEntity.notFound().build();
    }
    if (!isValid(pet)) {
      return ResponseEntity.badRequest().build();
    }
    current.setName(pet.getName());
    current.setCategory(pet.getCategory());
    current.setAge(pet.getAge());
    current.setTags(pet.getTags());
    current.setPhotoUrls(pet.getPhotoUrls());
    if (pet.getStatus() != null) {
      current.setStatus(pet.getStatus());
    }
    return ResponseEntity.ok(current);
  }

  @PatchMapping("/pets/{id}")
  public ResponseEntity<PetDTO> patch(
      @RequestBody PartialPetDTO pet, @PathVariable("id") String id, HttpServletRequest request) {
    if (!isAuthenticated(request)) {
      return ResponseEntity.status(401).build();
    }
    PetDTO current = find(id);
    if (current == null) {
      return ResponseEntity.notFound().build();
    }
    if (pet.getStatus() == null || !STATUSES.contains(pet.getStatus())) {
      return ResponseEntity.badRequest().build();
    }
    current.setStatus(pet.getStatus());
    return ResponseEntity.ok(current);
  }

  @DeleteMapping("/pets/{id}")
  public ResponseEntity<Void> delete(@PathVariable("id") String id, HttpServletRequest request) {
    if (!isAuthenticated(request)) {
      return ResponseEntity.status(401).build();
    }
    PetDTO current = find(id);
    if (current == null) {
      return ResponseEntity.notFound().build();
    }
    pets = pets.stream().filter(p -> p != current).collect(Collectors.toList());
    return ResponseEntity.ok().build();
  }

  private static PetDTO find(String id) {
    if (id == null) {
      return null;
    }
    return pets.stream().filter(p -> id.equals(p.getId())).findFirst().orElse(null);
  }

  private static boolean isValid(PetDTO pet) {
    if (StringUtils.isBlank(pet.getId()) || StringUtils.isBlank(pet.getName())) {
      return false;
    }
    if (pet.getStatus() != null && !STATUSES.contains(pet.getStatus())) {
      return false;
    }
    return pet.getAge() == null || (pet.getAge() >= 0 && pet.getAge() <= MAX_AGE);
  }

  private static boolean isAuthenticated(HttpServletRequest request) {
    return StringUtils.isNotBlank(request.getHeader(HttpHeaders.AUTHORIZATION));
  }
}
