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
  Scenario: Should import an empty csv file as no users
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath             |   Content-Type        |
      | file               | upload/empty.csv     |   text/csv            |
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0
    When I set Content-Type http header to application/json
    And I GET /api/users
    Then http response body is typed as array using path $ with length 0

  @import
  Scenario: Should import a header-only csv file as no users
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath               |   Content-Type        |
      | file               | upload/header-only.csv |   text/csv            |
    Then http response code should be 200
    And http response body is typed as array using path $ with length 0

  @import
  Scenario: Should reject a csv file with a non numeric age
    When I send a multipart POST request to /api/users with:
      | Name               | Filepath                       |   Content-Type        |
      | file               | upload/users-invalid-age.csv   |   text/csv            |
    Then http response code should be 500
    When I set Content-Type http header to application/json
    And I GET /api/users
    Then http response body is typed as array using path $ with length 0
