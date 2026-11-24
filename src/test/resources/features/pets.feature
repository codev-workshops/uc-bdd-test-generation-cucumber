Feature: Pets api tests

  Background:
    Given http baseUri is /api/
    And I set http headers to:
    | Accept        | application/json  |
    | Content-Type  | application/json  |

  Scenario: Create a pet successfully
    When I set http body to {"name":"Rex","category":"dog","status":"available","tags":["friendly"],"photoUrls":["http://pets/rex.png"]}
    And I POST /pets
    Then http response code should be 201
    And http response header Content-Type should be application/json
    And http response body path $.id should exists
    And http response body path $.name must be Rex
    And http response body path $.category must be dog
    And http response body path $.status must be available
    And http response body path $.tags should be ["friendly"]
    And http response body path $.photoUrls should be ["http://pets/rex.png"]
    And I store the value of http body path $.id as petId in scenario scope

  Scenario: Create a pet with an explicit id
    When I set http body to {"id":"pet-1","name":"Tom","category":"cat","status":"pending"}
    And I POST /pets
    Then http response code should be 201
    And http response body path $.id must be pet-1
    And http response body path $.name must be Tom
    And http response body path $.category must be cat
    And http response body path $.status must be pending

  Scenario: Create a pet without name should fail
    When I set http body to {"category":"dog","status":"available"}
    And I POST /pets
    Then http response code should be 400

  Scenario: Create a pet with blank name should fail
    When I set http body to {"name":"  ","category":"dog","status":"available"}
    And I POST /pets
    Then http response code should be 400

  Scenario: Create a pet without category should fail
    When I set http body to {"name":"Nemo","status":"available"}
    And I POST /pets
    Then http response code should be 400

  Scenario: Create a pet with duplicate id should fail
    When I set http body to {"id":"pet-1","name":"Garfield","category":"cat","status":"available"}
    And I POST /pets
    Then http response code should be 400

  Scenario: Get pet by id
    When I GET /pets/`$petId`
    Then http response code should be 200
    And http response body path $.id should be `$petId`
    And http response body path $.name should be Rex
    And http response body path $.category should be dog
    And http response body path $.status should be available

  Scenario: Get non-existent pet
    When I GET /pets/unknown-pet
    Then http response code should be 404
    And http response body path $ should not have content

  Scenario: Update pet via PUT
    When I set http body to {"name":"Rex II","category":"dog","status":"sold","tags":["trained"],"photoUrls":[]}
    And I PUT /pets/`$petId`
    Then http response code should be 200
    And http response body path $.name should be Rex II
    And http response body path $.status should be sold
    When I GET /pets/`$petId`
    Then http response code should be 200
    And http response body path $.id should be `$petId`
    And http response body path $.name should be Rex II
    And http response body path $.category should be dog
    And http response body path $.status should be sold
    And http response body path $.tags should be ["trained"]

  Scenario: Update pet via PUT with missing category should fail
    When I set http body to {"name":"Rex III","status":"sold"}
    And I PUT /pets/`$petId`
    Then http response code should be 400

  Scenario: Update non-existent pet via PUT
    When I set http body to {"name":"Ghost","category":"dog","status":"available"}
    And I PUT /pets/unknown-pet
    Then http response code should be 404

  Scenario: Patch pet status
    When I set http body to {"status":"available"}
    And I PATCH /pets/`$petId`
    Then http response code should be 200
    And http response body path $.status should be available
    And http response body path $.name should be Rex II
    When I GET /pets/`$petId`
    Then http response code should be 200
    And http response body path $.status should be available
    And http response body path $.category should be dog

  Scenario: Patch all pet fields
    When I set http body to {"name":"Tommy","category":"kitten","status":"sold","tags":["lazy"],"photoUrls":["http://pets/tommy.png"]}
    And I PATCH /pets/pet-1
    Then http response code should be 200
    And http response body path $.name should be Tommy
    And http response body path $.category should be kitten
    And http response body path $.status should be sold
    And http response body path $.tags should be ["lazy"]
    And http response body path $.photoUrls should be ["http://pets/tommy.png"]

  Scenario: Patch non-existent pet
    When I set http body to {"status":"sold"}
    And I PATCH /pets/unknown-pet
    Then http response code should be 404

  Scenario: List pets
    When I GET /pets
    Then http response code should be 200
    And http response body should be valid json
    And http response body is typed as array for path $
    And http response body is typed as array using path $ with length 2
    And http response body path $.[0].id should be `$petId`
    And http response body path $.[1].id should be pet-1
    And http response header X-Total-Count should be 2

  Scenario: Filter pets by status
    When I set http query parameter status to sold
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 1
    And http response body path $.[0].id should be pet-1
    And http response body path $.[0].status should be sold
    And http response header X-Total-Count should be 1

  Scenario: Filter pets by unknown status
    When I set http query parameter status to lost
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0
    And http response header X-Total-Count should be 0

  Scenario: Create several pets for pagination
    When I set http body to {"id":"pet-2","name":"Bella","category":"dog","status":"available"}
    And I POST /pets
    Then http response code should be 201
    When I set http body to {"id":"pet-3","name":"Luna","category":"cat","status":"available"}
    And I POST /pets
    Then http response code should be 201
    When I set http body to {"id":"pet-4","name":"Kiwi","category":"bird","status":"pending"}
    And I POST /pets
    Then http response code should be 201

  Scenario: Paginate pets first page
    When I set http query parameter page to 0
    And I set http query parameter size to 2
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 2
    And http response body path $.[0].id should be `$petId`
    And http response body path $.[1].id should be pet-1
    And http response header X-Total-Count should be 5

  Scenario: Paginate pets last partial page
    When I set http query parameter page to 2
    And I set http query parameter size to 2
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 1
    And http response body path $.[0].id should be pet-4
    And http response header X-Total-Count should be 5

  Scenario: Paginate pets out of range page
    When I set http query parameter page to 5
    And I set http query parameter size to 2
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0
    And http response header X-Total-Count should be 5

  Scenario: Paginate filtered pets
    When I set http query parameter status to available
    And I set http query parameter page to 0
    And I set http query parameter size to 2
    And I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 2
    And http response body path $.[0].id should be `$petId`
    And http response body path $.[1].id should be pet-2
    And http response header X-Total-Count should be 3

  Scenario: Delete pet
    When I DELETE /pets/`$petId`
    Then http response code should be 200
    When I GET /pets/`$petId`
    Then http response code should be 404

  Scenario: Delete non-existent pet
    When I DELETE /pets/unknown-pet
    Then http response code should be 404
    And http response body path $ should not have content

  Scenario: Delete remaining pets
    When I DELETE /pets/pet-1
    Then http response code should be 200
    And I DELETE /pets/pet-2
    Then http response code should be 200
    And I DELETE /pets/pet-3
    Then http response code should be 200
    And I DELETE /pets/pet-4
    Then http response code should be 200
    When I GET /pets
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0
    And http response header X-Total-Count should be 0
