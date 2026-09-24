@user
Feature: Users import api tests

  @import
  Scenario: Should import users csv file
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath             |   Content-Type        |
      | file               | upload/users.csv     |   text/csv            |
    Then http response code should be 200
    And http response body is typed as array using path $ with length 2
    And http response body path $.[0].id should be 123
    And http response body path $.[0].firstName should be Peter
    And http response body path $.[0].lastName should be Parker
    And http response body path $.[0].age should be 22
    And http response body path $.[1].id should be 4334
    And http response body path $.[1].firstName should be Steve
    And I set Content-Type http header to application/json
    When I GET /api/users
    Then http response code should be 200
    And http response body is typed as array using path $ with length 2

  @import
  Scenario: Should import a single line csv file
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath                 |   Content-Type        |
      | file               | upload/users-single.csv  |   text/csv            |
    Then http response code should be 200
    And http response body is typed as array using path $ with length 1
    And http response body path $.[0].id should be 1
    And http response body path $.[0].firstName should be Natasha
    And http response body path $.[0].age should be 35

  @import
  Scenario: Should import a csv file containing only the header line
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath                 |   Content-Type        |
      | file               | upload/users-empty.csv   |   text/csv            |
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0
    And I set Content-Type http header to application/json
    When I GET /api/users
    Then http response body is typed as array using path $ with length 0

  @import
  Scenario: Should reject an import when the file part is missing
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath             |   Content-Type        |
      | document           | upload/users.csv     |   text/csv            |
    Then http response code should be 400
    And I set Content-Type http header to application/json
    When I GET /api/users
    Then http response body is typed as array using path $ with length 0
