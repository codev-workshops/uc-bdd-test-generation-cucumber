@store
Feature: Store orders api tests

  Background:
    Given http baseUri is /api/store/
    And I set http headers to:
      | Accept       | application/json |
      | Content-Type | application/json |

  # ---------------------------------------------------------------- CRUD

  Scenario: Place an order
    Given I authenticate with login/password tstark/marvel
    And I set http body with file fixtures/rex.order.json
    When I POST /orders
    Then http response code should be 201
    And http response body path $.id must be 100
    And http response body path $.petId must be 1
    And http response body path $.quantity must be 2
    And http response body path $.status must be placed
    And http response body path $.complete must be false

  Scenario: Place an order without status defaults it to placed
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "101", "petId": "1", "quantity": 1}
    When I POST /orders
    Then http response code should be 201
    And http response body path $.status must be placed

  Scenario: Read an order by id and list orders
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "102", "petId": "1", "quantity": 1, "status": "approved"}
    And I POST /orders
    And I set http body to {"id": "103", "petId": "2", "quantity": 3, "status": "delivered", "complete": true}
    And I POST /orders
    When I GET /orders/103
    Then http response code should be 200
    And http response body path $.petId must be 2
    And http response body path $.quantity must be 3
    And http response body path $.complete must be true
    When I GET /orders
    Then http response body is typed as array using path $ with length 2
    When I set http query parameter status to approved
    And I GET /orders
    Then http response body is typed as array using path $ with length 1
    And http response body path $.[0].id must be 102

  Scenario: Delete an order
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "104", "petId": "1", "quantity": 1}
    And I POST /orders
    When I DELETE /orders/104
    Then http response code should be 200
    When I GET /orders/104
    Then http response code should be 404

  Scenario: Inventory counts orders per status
    Given I authenticate with login/password tstark/marvel
    When I GET /inventory
    Then http response code should be 200
    And http response body path $.placed must be 0
    And http response body path $.approved must be 0
    And http response body path $.delivered must be 0
    Given I set http body to {"id": "105", "petId": "1", "quantity": 1}
    And I POST /orders
    And I set http body to {"id": "106", "petId": "1", "quantity": 1, "status": "delivered"}
    And I POST /orders
    When I GET /inventory
    Then http response body path $.placed must be 1
    And http response body path $.approved must be 0
    And http response body path $.delivered must be 1

  # ----------------------------------------------------------- Not found

  Scenario: Get an unknown order
    When I GET /orders/99999
    Then http response code should be 404
    And http response body path $ should not have content

  Scenario: Delete an unknown order
    Given I authenticate with login/password tstark/marvel
    When I DELETE /orders/99999
    Then http response code should be 404
    And http response body path $ should not have content

  # ---------------------------------------------------------- Validation

  Scenario: Place an order without a pet is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "110", "quantity": 1}
    When I POST /orders
    Then http response code should be 422
    And http response body path $ should not have content

  Scenario: Place an order without a quantity is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "111", "petId": "1"}
    When I POST /orders
    Then http response code should be 422

  Scenario: Place an order with an invalid status is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "112", "petId": "1", "quantity": 1, "status": "lost"}
    When I POST /orders
    Then http response code should be 422

  Scenario: Place an order with a duplicate id is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "113", "petId": "1", "quantity": 1}
    And I POST /orders
    And http response code should be 201
    When I POST /orders
    Then http response code should be 409

  # ---------------------------------------------------- Boundary conditions

  Scenario: Quantity boundaries are inclusive
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "120", "petId": "1", "quantity": 0}
    When I POST /orders
    Then http response code should be 422
    And I set http body to {"id": "121", "petId": "1", "quantity": 1}
    When I POST /orders
    Then http response code should be 201
    And http response body path $.quantity must be 1
    And I set http body to {"id": "122", "petId": "1", "quantity": 1000}
    When I POST /orders
    Then http response code should be 201
    And http response body path $.quantity must be 1000
    And I set http body to {"id": "123", "petId": "1", "quantity": 1001}
    When I POST /orders
    Then http response code should be 422
    And I set http body to {"id": "124", "petId": "1", "quantity": -5}
    When I POST /orders
    Then http response code should be 422
    When I GET /orders
    Then http response body is typed as array using path $ with length 2

  # ---------------------------------------------------------- Pagination

  Scenario: Paginate the orders list
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "130", "petId": "1", "quantity": 1}
    And I POST /orders
    And I set http body to {"id": "131", "petId": "1", "quantity": 1}
    And I POST /orders
    And I set http body to {"id": "132", "petId": "1", "quantity": 1}
    And I POST /orders
    When I set http query parameter page to 0
    And I set http query parameter size to 2
    And I GET /orders
    Then http response body is typed as array using path $ with length 2
    And http response body path $.[1].id must be 131
    When I set http query parameter page to 1
    And I GET /orders
    Then http response body is typed as array using path $ with length 1
    And http response body path $.[0].id must be 132
    When I set http query parameter page to 5
    And I GET /orders
    Then http response body is typed as array using path $ with length 0

  # ------------------------------------------------------------ Security

  Scenario: Unauthenticated order placement is rejected
    Given I set http body to {"id": "140", "petId": "1", "quantity": 1}
    When I POST /orders
    Then http response code should be 401
    When I DELETE /orders/140
    Then http response code should be 401
    When I GET /orders
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0

  Scenario: Authenticated order placement succeeds
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "141", "petId": "1", "quantity": 1}
    When I POST /orders
    Then http response code should be 201
    When I DELETE /orders/141
    Then http response code should be 200
