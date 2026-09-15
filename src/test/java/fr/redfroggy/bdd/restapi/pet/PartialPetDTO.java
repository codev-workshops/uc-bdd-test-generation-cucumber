package fr.redfroggy.bdd.restapi.pet;

/** Fields accepted by a PATCH on a pet. */
public class PartialPetDTO {

  private String status;

  public String getStatus() {
    return status;
  }

  public void setStatus(String status) {
    this.status = status;
  }
}
