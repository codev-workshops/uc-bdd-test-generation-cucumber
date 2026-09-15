@pet
Feature: Pets api tests

  Background:
    Given http baseUri is /api/
    And I set http headers to:
      | Accept       | application/json |
      | Content-Type | application/json |

  # ---------------------------------------------------------------- CRUD

  Scenario: Create a pet
    Given I authenticate with login/password tstark/marvel
    And I set http body with file fixtures/rex.pet.json
    When I POST /pets
    Then http response code should be 201
    And http response header Content-Type should be application/json
    And http response body should be valid json
    And http response body path $.id must be 1
    And http response body path $.name must be Rex
    And http response body path $.category should be dog
    And http response body path $.status must be available
    And http response body path $.age should be 3
    And http response body path $.tags should be ["friendly", "trained"]
    And http response body path $.photoUrls must not be []
    And http response body is typed as array using path $.photoUrls with length 1

  Scenario: Create a pet without status defaults it to available
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "2", "name": "Tom", "category": "cat"}
    When I POST /pets
    Then http response code should be 201
    And http response body path $.status must be available
    And http response body path $.tags should not exist

  Scenario: Read a pet by id
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "3", "name": "Nemo", "category": "fish", "status": "pending"}
    And I POST /pets
    And http response code should be 201
    When I GET /pets/3
    Then http response code should be 200
    And http response body path $.id must be 3
    And http response body path $.name must be Nemo
    And http response body path $.status must be pending

  Scenario: Read all pets and filter by name and status
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "4", "name": "Rex", "category": "dog", "status": "available"}
    And I POST /pets
    And I set http body to {"id": "5", "name": "Rexina", "category": "dog", "status": "sold"}
    And I POST /pets
    And I set http body to {"id": "6", "name": "Tom", "category": "cat", "status": "available"}
    And I POST /pets
    When I GET /pets
    Then http response code should be 200
    And http response header X-Total-Count should be 3
    And http response body is typed as array using path $ with length 3
    And http response body path $.[0].name must be Rex
    And http response body path $.[2].name must be Tom
    When I set http query parameter name to rex
    And I GET /pets
    Then http response body is typed as array using path $ with length 2
    When I set http query parameter status to sold
    And I GET /pets
    Then http response body is typed as array using path $ with length 1
    And http response body path $.[0].id must be 5

  Scenario: Update a pet
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "7", "name": "Rex", "category": "dog", "status": "available", "age": 3}
    And I POST /pets
    And http response code should be 201
    And I set http body to {"id": "7", "name": "Rex II", "category": "dog", "status": "sold", "age": 4, "tags": ["adopted"]}
    When I PUT /pets/7
    Then http response code should be 200
    And http response body path $.name must be Rex II
    And http response body path $.status must be sold
    And http response body path $.age must be 4
    And http response body path $.tags should be ["adopted"]
    When I GET /pets/7
    Then http response code should be 200
    And http response body path $.name must be Rex II
    And http response body path $.age must be 4

  Scenario: Partially update a pet status
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "8", "name": "Tom", "category": "cat", "status": "available", "age": 2}
    And I POST /pets
    And http response code should be 201
    And I set http body to {"status": "pending"}
    When I PATCH /pets/8
    Then http response code should be 200
    And http response body path $.status must be pending
    And http response body path $.name must be Tom
    And http response body path $.age must be 2

  Scenario: Delete a pet
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "9", "name": "Nemo", "category": "fish"}
    And I POST /pets
    And http response code should be 201
    When I DELETE /pets/9
    Then http response code should be 200
    And http response body path $ should not have content
    When I GET /pets/9
    Then http response code should be 404
    When I GET /pets
    Then http response body is typed as array using path $ with length 0

  # ----------------------------------------------------------- Not found

  Scenario: Get an unknown pet
    When I GET /pets/24333
    Then http response code should be 404
    And http response body path $ should not have content

  Scenario: Update an unknown pet
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "24333", "name": "Ghost"}
    When I PUT /pets/24333
    Then http response code should be 404
    And http response body path $ should not have content

  Scenario: Patch an unknown pet
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"status": "sold"}
    When I PATCH /pets/24333
    Then http response code should be 404
    And http response body path $ should not have content

  Scenario: Delete an unknown pet
    Given I authenticate with login/password tstark/marvel
    When I DELETE /pets/24333
    Then http response code should be 404
    And http response body path $ should not exist
    And http response body path $ should not have content

  # ---------------------------------------------------------- Validation

  Scenario: Create a pet without a name is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "10", "category": "dog"}
    When I POST /pets
    Then http response code should be 400
    And http response body path $ should not have content
    When I GET /pets/10
    Then http response code should be 404

  Scenario: Create a pet with a blank name is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "10", "name": "   ", "category": "dog"}
    When I POST /pets
    Then http response code should be 400

  Scenario: Create a pet without an id is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"name": "Rex", "category": "dog"}
    When I POST /pets
    Then http response code should be 400

  Scenario: Create a pet with an invalid status is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "11", "name": "Rex", "status": "lost"}
    When I POST /pets
    Then http response code should be 400
    And http response code should not be 201

  Scenario: Create a pet with an existing id is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "12", "name": "Rex"}
    And I POST /pets
    And http response code should be 201
    When I POST /pets
    Then http response code should be 409
    When I GET /pets
    Then http response body is typed as array using path $ with length 1

  Scenario: Update a pet with an invalid payload is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "13", "name": "Rex", "status": "available"}
    And I POST /pets
    And http response code should be 201
    And I set http body to {"id": "13", "name": "", "status": "available"}
    When I PUT /pets/13
    Then http response code should be 400
    And I set http body to {"id": "13", "name": "Rex", "status": "unknown"}
    When I PUT /pets/13
    Then http response code should be 400
    When I GET /pets/13
    Then http response body path $.name must be Rex
    And http response body path $.status must be available

  Scenario: Patch a pet with an invalid status is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "14", "name": "Rex", "status": "available"}
    And I POST /pets
    And I set http body to {"status": "lost"}
    When I PATCH /pets/14
    Then http response code should be 400
    And I set http body to {"name": "Rex"}
    When I PATCH /pets/14
    Then http response code should be 400
    When I GET /pets/14
    Then http response body path $.status must be available

  Scenario: Create a pet with a malformed json body is rejected
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "15", "name": "Rex", "age": "not-a-number"}
    When I POST /pets
    Then http response code should be 400

  # ---------------------------------------------------- Boundary conditions

  Scenario: Age boundaries are inclusive
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "20", "name": "Newborn", "age": 0}
    When I POST /pets
    Then http response code should be 201
    And http response body path $.age must be 0
    And I set http body to {"id": "21", "name": "Ancient", "age": 100}
    When I POST /pets
    Then http response code should be 201
    And http response body path $.age must be 100
    And I set http body to {"id": "22", "name": "Impossible", "age": 101}
    When I POST /pets
    Then http response code should be 400
    And I set http body to {"id": "23", "name": "Negative", "age": -1}
    When I POST /pets
    Then http response code should be 400
    When I GET /pets
    Then http response body is typed as array using path $ with length 2

  Scenario: Empty arrays are accepted and preserved
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "24", "name": "Plain", "tags": [], "photoUrls": []}
    When I POST /pets
    Then http response code should be 201
    And http response body is typed as array using path $.tags with length 0
    And http response body is typed as array using path $.photoUrls with length 0
    And http response body path $.tags should not have content
    When I GET /pets/24
    Then http response body is typed as array using path $.tags with length 0

  Scenario: Very large ids are supported
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "9223372036854775807", "name": "Max"}
    When I POST /pets
    Then http response code should be 201
    And http response body path $.id must be 9223372036854775807
    When I GET /pets/9223372036854775807
    Then http response code should be 200
    And http response body path $.name must be Max
    When I GET /pets/9223372036854775808
    Then http response code should be 404

  Scenario: Name length and unicode boundaries
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "25", "name": "R"}
    When I POST /pets
    Then http response code should be 201
    And http response body path $.name must be R
    And I set http body with file fixtures/long-name.pet.json
    When I POST /pets
    Then http response code should be 201
    And http response body should contain Rexxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    And I set http body to {"id": "27", "name": "Réxö 犬 🐶"}
    When I POST /pets
    Then http response code should be 201
    And http response body path $.name must be Réxö 犬 🐶

  # ---------------------------------------------------------- Pagination

  Scenario: Paginate the pets list
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "30", "name": "P1"}
    And I POST /pets
    And I set http body to {"id": "31", "name": "P2"}
    And I POST /pets
    And I set http body to {"id": "32", "name": "P3"}
    And I POST /pets
    And I set http body to {"id": "33", "name": "P4"}
    And I POST /pets
    And I set http body to {"id": "34", "name": "P5"}
    And I POST /pets
    When I GET /pets
    Then http response body is typed as array using path $ with length 5
    When I set http query parameter page to 0
    And I set http query parameter size to 2
    And I GET /pets
    Then http response code should be 200
    And http response header X-Total-Count should be 5
    And http response body is typed as array using path $ with length 2
    And http response body path $.[0].id must be 30
    And http response body path $.[1].id must be 31
    When I set http query parameter page to 1
    And I GET /pets
    Then http response body is typed as array using path $ with length 2
    And http response body path $.[0].id must be 32
    When I set http query parameter page to 2
    And I GET /pets
    Then http response body is typed as array using path $ with length 1
    And http response body path $.[0].id must be 34
    When I set http query parameter page to 3
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0
    And http response body path $ should not have content

  Scenario: Pagination defaults and combination with filters
    Given I authenticate with login/password tstark/marvel
    And I set http body to {"id": "35", "name": "Rex", "status": "sold"}
    And I POST /pets
    And I set http body to {"id": "36", "name": "Rexy", "status": "available"}
    And I POST /pets
    And I set http body to {"id": "37", "name": "Rexo", "status": "sold"}
    And I POST /pets
    When I set http query parameter size to 1
    And I GET /pets
    Then http response body is typed as array using path $ with length 1
    And http response body path $.[0].id must be 35
    When I set http query parameter status to sold
    And I set http query parameter page to 1
    And I GET /pets
    Then http response body is typed as array using path $ with length 1
    And http response body path $.[0].id must be 37

  Scenario: Pagination boundaries are validated
    When I set http query parameter page to -1
    And I GET /pets
    Then http response code should be 400
    When I set http query parameter page to 0
    And I set http query parameter size to 0
    And I GET /pets
    Then http response code should be 400
    When I set http query parameter size to 51
    And I GET /pets
    Then http response code should be 400
    When I set http query parameter size to 50
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0

  # ------------------------------------------------------------ Security

  Scenario: Reads do not require authentication
    When I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0

  Scenario: Unauthenticated create is rejected
    Given I set http body to {"id": "40", "name": "Intruder"}
    When I POST /pets
    Then http response code should be 401
    And http response body path $ should not have content
    When I GET /pets/40
    Then http response code should be 404

  Scenario: Unauthenticated update, patch and delete are rejected before any lookup
    Given I set http body to {"id": "41", "name": "Hacked", "status": "sold"}
    When I PUT /pets/41
    Then http response code should be 401
    And I set http body to {"status": "sold"}
    When I PATCH /pets/41
    Then http response code should be 401
    When I DELETE /pets/41
    Then http response code should be 401
    When I HEAD /authenticated
    Then http response code should be 401

  Scenario: Authenticated user can write after checking authentication
    When I HEAD /authenticated
    Then http response code should be 401
    Given I authenticate with login/password tstark/marvel
    When I HEAD /authenticated
    Then http response code should be 200
    And http response header Authorization should exist
    And I set http body to {"id": "42", "name": "Allowed"}
    When I POST /pets
    Then http response code should be 201
    When I DELETE /pets/42
    Then http response code should be 200
