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

  @import
  Scenario: Should import an empty users csv file
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath                 |   Content-Type        |
      | file               | upload/users-empty.csv   |   text/csv            |
    Then http response code should be 200
    And http response body should be valid json
    And http response body is typed as array using path $ with length 0
    And http response body path $ should not have content

  @import
  Scenario: Should import users csv file regardless of part content type
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath                 |   Content-Type        |
      | file               | upload/users-empty.csv   |   application/json    |
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0
