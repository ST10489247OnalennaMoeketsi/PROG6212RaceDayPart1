# RaceDay API Endpoint Plan PROG6212 Part 1

## Design conventions

- Base route: `/api`
- JSON is used for request and response bodies.
- Authentication is planned using a bearer token/JWT in Part 2.
- `Public` means no login is required.
- Public registration creates a Participant account; the API must not allow an unauthenticated caller to assign themselves the Organiser role.
- `Authenticated` means the caller must be logged in.
- `Organiser` and `Participant` are enforced at the API level in Part 2.
- IDs are integer identifiers matching the SQL Server schema.
- `204 No Content` is used when an operation succeeds without a response body.
- Failure responses consistently use `400`, `401`, `403`, `404`, `409`, or `500` where appropriate.

## Endpoint plan

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | `/api/auth/register` | Creates a new Participant account. Organiser accounts are provisioned/seeded and are not self-assigned through public registration. | Public | `{ "firstName": "A", "lastName": "B", "email": "a@example.com", "password": "Secret123!", "phone": "0712345678" }` | **201** Created with user ID and Participant role; **400** validation error; **409** email already exists |
| POST | `/api/auth/login` | Authenticates a user and returns an access token. | Public | `{ "email": "a@example.com", "password": "Secret123!" }` | **200** token + user profile; **400** invalid request; **401** invalid credentials |
| GET | `/api/users/me` | Gets the authenticated user's profile. | Authenticated | None | **200** profile; **401** unauthenticated; **404** profile not found |
| PUT | `/api/users/me` | Updates the authenticated user's profile. | Authenticated | `{ "firstName": "A", "lastName": "B", "phone": "0712345678" }` | **200** updated profile; **400** validation error; **401** unauthenticated |
| GET | `/api/events`  | Lists events available in RaceDay. | Public | None | **200** event list; **500** server error |
| GET | `/api/events/{id}` | Gets one event and its details. | Public | None | **200** event; **400** invalid ID; **404** event not found |
| POST | `/api/events` | Creates an event owned by the logged-in organiser. | Organiser | `{ "eventName": "Pretoria City Run", "description": "...", "location": "Pretoria, Gauteng", "eventDate": "2026-10-10T07:00:00", "registrationDeadline": "2026-10-01T23:59:00", "status": "Open" }` | **201** Created; **400** invalid dates/data; **401** unauthenticated; **403** not organiser |
| PUT | `/api/events/{id}` | Updates an event owned by the organiser. | Organiser | Event fields to update | **200** updated event; **400** invalid data; **401** unauthenticated; **403** wrong role/not owner; **404** not found |
| DELETE | `/api/events/{id}` | Deletes an event and its event-category links. | Organiser | None | **204** deleted; **401** unauthenticated; **403** not organiser/not owner; **404** not found; **409** conflict if deletion is not allowed by business rules |
| GET | `/api/events/{eventId}/categories` | Lists categories assigned to an event. | Public | None | **200** category list; **400** invalid ID; **404** event not found |
| GET | `/api/categories` | Lists all reusable RaceDay categories. | Public | None | **200** category list; **500** server error |
| GET | `/api/categories/{id}` | Gets one category. | Public | None | **200** category; **400** invalid ID; **404** not found |
| POST | `/api/categories` | Creates a new event category. | Organiser | `{ "name": "10 KM Run", "description": "Ten kilometre road race." }` | **201** Created; **400** validation error; **401** unauthenticated; **403** not organiser; **409** duplicate category |
| PUT | `/api/categories/{id}` | Updates a category. | Organiser | `{ "name": "10 KM Run", "description": "Updated description." }` | **200** updated category; **400** invalid data; **401** unauthenticated; **403** not organiser; **404** not found; **409** duplicate name |
| DELETE | `/api/categories/{id}` | Deletes a category and its event-category links. | Organiser | None | **204** deleted; **401** unauthenticated; **403** not organiser; **404** not found; **409** conflict where business rules prevent deletion |
| POST | `/api/events/{eventId}/categories/{categoryId}` | Associates an existing category with an event. | Organiser | None | **201** association created; **400** invalid IDs; **401** unauthenticated; **403** not organiser; **404** event/category not found; **409** association already exists |
| DELETE | `/api/events/{eventId}/categories/{categoryId}` | Removes a category from an event. | Organiser | None | **204** removed; **401** unauthenticated; **403** not organiser; **404** association not found; **409** category is required by an existing enrolment |
| GET | `/api/events/{eventId}/enrolments` | Lists all participant enrolments for an event. | Organiser | None | **200** enrolment list; **401** unauthenticated; **403** not organiser; **404** event not found |
| POST | `/api/events/{eventId}/enrolments` | Enrols the logged-in participant in a selected event category. | Participant | `{ "categoryId": 2 }` | **201** enrolment created; **400** invalid category/data; **401** unauthenticated; **403** not participant; **404** event/category not found; **409** already enrolled/registration closed |
| GET | `/api/users/me/enrolments` | Lists the authenticated participant's enrolments. | Participant | None | **200** enrolment list; **401** unauthenticated; **403** not participant |
| DELETE | `/api/enrolments/{id}` | Cancels the authenticated participant's enrolment. | Participant | None | **204** cancelled; **401** unauthenticated; **403** not participant/not owner; **404** not found; **409** already cancelled or event registration closed |
| GET | `/api/events/{eventId}/results` | Lists results for an event, including participant, category and finishing details. | Public | None | **200** result list; **400** invalid ID; **404** event not found |
| POST | `/api/events/{eventId}/results` | Records a result for an enrolment belonging to the event. | Organiser | `{ "enrolmentId": 1, "finishTime": "00:52:34", "position": 12, "resultStatus": "Finished" }` | **201** result created; **400** invalid result; **401** unauthenticated; **403** not organiser; **404** event/enrolment not found; **409** result already exists |
| PUT | `/api/results/{id}` | Updates an existing participant result. | Organiser | `{ "finishTime": "00:51:40", "position": 10, "resultStatus": "Finished" }` | **200** updated result; **400** invalid result; **401** unauthenticated; **403** not organiser; **404** not found |
| GET | `/api/users/me/results` | Lists the authenticated participant's personal results/history. | Participant | None | **200** personal results; **401** unauthenticated; **403** not participant |

## Role summary

### Public
- Register
- Login
- Browse events
- View event details
- View categories
- View event categories
- View event results

### Organiser
- Create/update/delete events
- Create/update/delete categories
- Assign/remove event categories
- View event enrolments
- Capture/update results

### Participant
- View/update own profile
- Enrol in events
- View/cancel own enrolments
- View own results

## Alignment with the database

The API uses the same identifiers and relationships as `RaceDay.sql`:

- `Users.UserId`
- `Events.EventId`
- `Events.OrganiserId`
- `Categories.CategoryId`
- `EventCategories(EventId, CategoryId)`
- `Enrolments.EnrolmentId`
- `Enrolments.ParticipantId`
- `Enrolments.EventId`
- `Enrolments.CategoryId`
- `Results.ResultId`
- `Results.EnrolmentId`
