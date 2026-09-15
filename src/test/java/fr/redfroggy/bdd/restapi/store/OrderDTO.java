package fr.redfroggy.bdd.restapi.store;

/** Petstore-style store order resource used by the BDD test backend. */
public final class OrderDTO {

  private String id;

  private String petId;

  private Integer quantity;

  private String status;

  private boolean complete;

  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public String getPetId() {
    return petId;
  }

  public void setPetId(String petId) {
    this.petId = petId;
  }

  public Integer getQuantity() {
    return quantity;
  }

  public void setQuantity(Integer quantity) {
    this.quantity = quantity;
  }

  public String getStatus() {
    return status;
  }

  public void setStatus(String status) {
    this.status = status;
  }

  public boolean isComplete() {
    return complete;
  }

  public void setComplete(boolean complete) {
    this.complete = complete;
  }
}
