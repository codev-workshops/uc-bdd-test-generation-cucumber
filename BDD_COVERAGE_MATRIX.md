# BDD Coverage Matrix

Maps every REST endpoint exposed by the sample application
(`src/test/java/fr/redfroggy/bdd/restapi/user/UserController.java`) to the Gherkin
scenarios that exercise it (`src/test/resources/features/*.feature`).

Scenario categories:

- **Happy path** – nominal request, 2xx response and body/header assertions.
- **Error** – request that must be rejected (4xx) or that hits an upstream failure.
- **Boundary** – edge values / edge inputs (empty collections, zero, single element,
  case sensitivity, partial matches, idempotency, ignored fields...).

Scenarios marked **(new)** were added to fill the gaps found in the analysis.

## Summary

| Endpoint | Feature file | Happy path | Error | Boundary | Status before | Status after |
|---|---|---|---|---|---|---|
| `HEAD /api/authenticated` | users.feature | 1 | 1 | 1 (new) | happy + error, no boundary | full |
| `GET /api/users` | users.feature, users-import.feature | 3 (+1 new) | 0 (*) | 4 (+3 new) | happy + boundary (empty result only) | full (*) |
| `GET /api/users/{id}` | users.feature | 2 | 1 (+2 new) | 1 (new) | happy + 404 only, no upstream failure, no boundary | full |
| `POST /api/users` (JSON) | users.feature | 3 | 0 → 3 (new) | 1 (new) | **happy path only** | full |
| `POST /api/users` (multipart CSV) | users-import.feature | 1 | 0 → 1 (new) | 2 (new) | **happy path only** | full |
| `PUT /api/users/{id}` | users.feature | 1 | 0 → 1 (new) | 2 (new) | **happy path only** | full |
| `PATCH /api/users/{id}` | users.feature | 1 | 0 → 1 (new) | 0 (**) | **happy path only** | happy + error |
| `DELETE /api/users/{id}` | users.feature | 1 | 1 | 1 (new) | happy + 404, no boundary | full |
| `DELETE /api/users`, `PUT /api/users` (unmapped) | users.feature | – | 1 (new) | – | **no scenario** | error |

Scenario count: 15 → 31 (Cucumber runner `RestApiCucumberTest`, all green).

(*) `GET /api/users` has no error path in the controller: any `name` value is
accepted and an unknown value yields an empty array (covered by *Search for invalid
users*). No 4xx can be produced without a request the test harness cannot build.

(**) `PATCH /api/users/{id}` only exposes `lastName`; there is no boundary value the
controller treats differently (an absent `lastName` is silently written as `null`,
which is arguably a defect, see *Findings*).

## Detailed matrix

### `HEAD /api/authenticated`

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Should be authenticated | 200 with basic auth, `Authorization` response header stored in scope |
| Error | Should be authenticated | 401 without any `Authorization` header |
| Boundary (new) | Should echo back an explicit Authorization header | any non-blank token (`Bearer any-opaque-token`) is accepted and echoed back unchanged |

### `GET /api/users?name=`

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Get users | 200, array of 3, positional ids/names, `$.[4]` absent |
| Happy path | Search for valid users | `name=wayne` returns exactly Bruce Wayne |
| Happy path (new) | Should import users csv file (users-import.feature) | imported users are visible on the collection right after import |
| Happy path | Delete user | collection is empty after all deletions |
| Boundary | Search for invalid users | unknown name → 200 and empty array |
| Boundary (new) | Search is case insensitive | `name=WAYNE` matches lower-case data |
| Boundary (new) | Search matches a partial first name across several users | `name=ru` matches both "Bruce" users, first *and* last name are searched |
| Boundary (new) | Search with a single character matches first and last names | `name=k` returns only Stark |
| Boundary (new) | Should import a csv file containing only the header line | collection stays empty after an empty import |

### `GET /api/users/{id}?format=`

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Get user Tony Stark | 200, `format=json` forwarded to the third-party API, `$.details.comicName` merged from the WireMock stub, `Content-Type` stored in scope |
| Happy path | Get user Bruce Wayne | 200, third-party stub fed from a fixture file |
| Error | Get wrong user | unknown id → 404, empty body |
| Error (new) | Get user when third party details api fails | upstream 500 → 400, empty body |
| Error (new) | Get user when third party details are not found | upstream 404 → 400, empty body |
| Boundary (new) | Create, update, delete a user with boundary values | a stubbed upstream does not resurrect a deleted user (404) |

### `POST /api/users` (JSON body)

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Add tony stark user | 201, `Content-Type: application/json`, body path override (`$.age` → 42), array fields, scope storage |
| Happy path | Add bruce wayne user | 201 with nested `relatedTo` and scope variable substitution |
| Happy path | Add bruce banner user | 201 with body loaded from a fixture file |
| Error (new) | Reject user creation with an already used id | duplicate id → 400, empty body, collection size unchanged |
| Error (new) | Reject user creation without a body | missing body → 400, collection size unchanged |
| Error (new) | Reject unsupported http method on users collection | `DELETE /users` and `PUT /users` → 405 |
| Boundary (new) | Create, update, delete a user with boundary values | `age: 0`, one-character names, empty `sessionIds`, absent `relatedTo` → 201 |

### `POST /api/users` (multipart/form-data, CSV import)

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Should import users csv file | 2 rows imported, every column mapped, both rows asserted, visible on `GET /api/users` |
| Error (new) | Should reject an import when the file part is missing | part named `document` instead of `file` → 400, nothing imported |
| Boundary (new) | Should import a single line csv file | single-row CSV → array of 1 |
| Boundary (new) | Should import a csv file containing only the header line | header-only CSV → 200 and empty array |

### `PUT /api/users/{id}`

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Update tony stark user | 200, `$.age` updated and persisted (`GET` after `PUT`) |
| Error (new) | Reject update of an unknown user | unknown id → 404, empty body |
| Boundary (new) | Update ignores the id carried in the body | body `id` differs from path id → path id wins, no user `999` created |
| Boundary (new) | Create, update, delete a user with boundary values | `age` moved from 0 to 150 |

### `PATCH /api/users/{id}`

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Patch bruce wayne user | 200, `$.lastName` updated and persisted |
| Error (new) | Reject patch of an unknown user | unknown id → 404, empty body |

### `DELETE /api/users/{id}`

| Category | Scenario | Assertions |
|---|---|---|
| Happy path | Delete user | 200 for each existing user, collection empty afterwards |
| Error | Delete wrong user | unknown id → 404, empty body |
| Boundary (new) | Create, update, delete a user with boundary values | deleting the same id twice → 200 then 404 (non idempotent by design), `GET` on the deleted id → 404 |

## Findings surfaced while filling the gaps

1. **Unstubbed third-party API yields 500 instead of 400.** When WireMock has no stub
   for `GET /public/characters/{id}` it answers `404 text/plain`; `UserDetailService`
   then throws `UnknownContentTypeException` and the controller returns 500 rather
   than the 400 it returns for any other non-2xx upstream response. A scenario
   asserting 400 was written and failed; it was removed rather than assert a 500.
   Fixing the service (catch `RestClientException` → 400) would let it be added back.
2. **`PATCH` with a body lacking `lastName` nulls the field** (`currentUser.setLastName(null)`).
   No scenario asserts this because the current behaviour looks unintended.
3. **`GET /api/users` after a multipart request needs `Content-Type` reset.** The step
   library keeps the multipart `Content-Type` header for the rest of the scenario, so a
   following `GET` is rejected by Tomcat (`no multipart boundary was found`, 500). The
   import scenarios therefore reset the header before listing users.

## How to run

```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 mvn test -Dtest=RestApiCucumberTest
```
