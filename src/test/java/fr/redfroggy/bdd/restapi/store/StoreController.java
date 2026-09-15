package fr.redfroggy.bdd.restapi.store;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import javax.servlet.http.HttpServletRequest;
import org.apache.commons.lang3.StringUtils;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** In-memory petstore-style /api/store backend (orders + inventory) for the BDD suite. */
@RestController
@RequestMapping("/api/store")
public final class StoreController {

  static final List<String> STATUSES = Arrays.asList("placed", "approved", "delivered");

  static final int MAX_QUANTITY = 1000;

  public static List<OrderDTO> orders = new ArrayList<>();

  @GetMapping("/inventory")
  public Map<String, Long> inventory() {
    Map<String, Long> counts = new LinkedHashMap<>();
    for (String status : STATUSES) {
      counts.put(status, orders.stream().filter(o -> status.equals(o.getStatus())).count());
    }
    return counts;
  }

  @GetMapping("/orders")
  public ResponseEntity<List<OrderDTO>> getAll(
      @RequestParam(value = "status", required = false) String status,
      @RequestParam(value = "page", required = false) Integer page,
      @RequestParam(value = "size", required = false) Integer size) {
    List<OrderDTO> result =
        orders.stream()
            .filter(o -> StringUtils.isBlank(status) || status.equals(o.getStatus()))
            .collect(Collectors.toList());
    if (page != null || size != null) {
      int pageIndex = page == null ? 0 : page;
      int pageSize = size == null ? 10 : size;
      if (pageIndex < 0 || pageSize < 1) {
        return ResponseEntity.badRequest().build();
      }
      int from = Math.min(pageIndex * pageSize, result.size());
      int to = Math.min(from + pageSize, result.size());
      result = result.subList(from, to);
    }
    return ResponseEntity.ok(result);
  }

  @GetMapping("/orders/{id}")
  public ResponseEntity<OrderDTO> get(@PathVariable("id") String id) {
    OrderDTO order = find(id);
    if (order == null) {
      return ResponseEntity.notFound().build();
    }
    return ResponseEntity.ok(order);
  }

  @PostMapping("/orders")
  public ResponseEntity<OrderDTO> place(@RequestBody OrderDTO order, HttpServletRequest request) {
    if (StringUtils.isBlank(request.getHeader(HttpHeaders.AUTHORIZATION))) {
      return ResponseEntity.status(401).build();
    }
    if (StringUtils.isBlank(order.getId())
        || StringUtils.isBlank(order.getPetId())
        || order.getQuantity() == null
        || order.getQuantity() < 1
        || order.getQuantity() > MAX_QUANTITY
        || (order.getStatus() != null && !STATUSES.contains(order.getStatus()))) {
      return ResponseEntity.unprocessableEntity().build();
    }
    if (find(order.getId()) != null) {
      return ResponseEntity.status(409).build();
    }
    if (order.getStatus() == null) {
      order.setStatus("placed");
    }
    orders.add(order);
    return ResponseEntity.status(201).body(order);
  }

  @DeleteMapping("/orders/{id}")
  public ResponseEntity<Void> delete(@PathVariable("id") String id, HttpServletRequest request) {
    if (StringUtils.isBlank(request.getHeader(HttpHeaders.AUTHORIZATION))) {
      return ResponseEntity.status(401).build();
    }
    OrderDTO order = find(id);
    if (order == null) {
      return ResponseEntity.notFound().build();
    }
    orders = orders.stream().filter(o -> o != order).collect(Collectors.toList());
    return ResponseEntity.ok().build();
  }

  private static OrderDTO find(String id) {
    if (id == null) {
      return null;
    }
    return orders.stream().filter(o -> id.equals(o.getId())).findFirst().orElse(null);
  }
}
