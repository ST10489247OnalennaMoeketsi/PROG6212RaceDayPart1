# RaceDay - Part 1 System Planning and Database

## RaceDay Project Overview 

RaceDay is a full-stack web-based event management system designed for the
South African road-running, walking and cycling community.

The final system will allow Organisers to create and manage events, manage
event categories, view participant enrolments and record results. Participants
will be able to create accounts, browse events, select categories, enrol and
track their personal results.

Part 1 focuses on planning the data model and API before implementation in
Part 2.

## User roles

### Organiser
- Create, edit and delete events.
- Create and manage event categories.
- Assign categories to events.
- View event enrolments.
- Capture and update participant results.

### Participant
- Create an account and log in.
- View and update their profile.
- Browse events and categories.
- Enrol in an event by selecting a category.
- View/cancel their own enrolments.
- View their personal results.

## Part 1 deliverables

The `/docs` folder contains:

- `RaceDay-ERD.png` - Entity Relationship Diagram.
- `API-Endpoint-Plan.md` - complete REST API endpoint plan.
- `RaceDaySystem.sql` - SQL Server database schema and seed data.

## Database design

The database contains six entities:

1. Users
2. Events
3. Categories
4. EventCategories
5. Enrolments
6. Results

`EventCategories` resolves the many-to-many relationship between Events and
Categories. `Enrolments` references a valid Event/Category combination, and
Results references an Enrolment.

## SQL Server / SSMS setup

1. Open SQL Server Management Studio (SSMS).
2. Connect to a SQL Server instance.
3. Open `docs/RaceDaySystem.sql`.
4. Execute the complete script.
5. Confirm that `RaceDayDB` is created.
6. Run the verification SELECT statements at the end of the script.
7. Confirm that all six tables contain the expected seed data.

The script contains:
- Primary keys
- Foreign keys
- Composite primary key
- Unique constraints
- NOT NULL constraints
- DEFAULT constraints
- CHECK constraints
- Seed data for users, events, categories, event-category associations,
  enrolments and results.

## How to use this Part 1 package

1. Create a GitHub repository for the RaceDay project.
2. Copy the supplied `.github`, `docs`, `README.md` and supporting files into it.
3. Commit the work in meaningful stages; use `COMMIT-PLAN.md` as a guide.
4. Open `docs/RaceDaySystem.sql` in SSMS and run it on a clean SQL Server instance.
5. Confirm all six tables and seed records using the verification queries.
6. Push the repository to GitHub.
7. Confirm GitHub Actions is green.
8. Add a screenshot of the real successful workflow to this README.
9. Record the Part 1 video in your own voice and upload it to YouTube as Unlisted.
10. Replace the video placeholder below with the actual YouTube link.

## GitHub Actions CI/CD

The repository uses GitHub Actions to validate the required Part 1 structure.

Workflow:

`.github/workflows/docs-validation.yml`

The workflow checks that the ERD, API endpoint plan and SQL script exist in
the `/docs` folder and are non-empty.

### CI/CD green build screenshot
<img width="1920" height="1080" alt="Screenshot 2026-09-04 182043" src="https://github.com/user-attachments/assets/25fbf8f7-ef82-4a7c-a7cd-bb76ae4e619d" /> 

## GitHub commit requirement

Part 1 requires at least 20 meaningful commits. Commits should represent
real development work rather than repeated message-only changes.

Suggested progression is provided in `COMMIT-PLAN.md`.

## Video presentation

The presentation should demonstrate:
1. RaceDay system purpose and roles.
2. ERD entities, attributes, PKs, FKs, cardinality and relationship choices.
3. API endpoint plan and role restrictions.
4. SQL script structure and constraints.
5. The SQL script being executed successfully in SSMS.
6. GitHub repository structure and the successful CI/CD build.

### Unlisted YouTube video

**INSERT YOUR UNLISTED YOUTUBE LINK HERE**

## Repository structure

```text
RaceDay/
├── .github/
│   └── workflows/
│       └── docs-validation.yml
├── docs/
│   ├── RaceDay-ERD.png
│   ├── API-Endpoint-Plan.md
│   └── RaceDaySystem.sql
├── README.md
```
