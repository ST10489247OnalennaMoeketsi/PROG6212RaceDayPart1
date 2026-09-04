/* =========================================================
   DATABASE: Create if it doesn't exist
   ========================================================= */
IF DB_ID(N'RaceDayDB') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB;
END;
GO

USE RaceDayDB;
GO

/* =========================================================
   CLEANUP: Drop all objects in the correct order
   (Child tables first to avoid foreign key errors)
   ========================================================= */
DROP TABLE IF EXISTS dbo.Results;
DROP TABLE IF EXISTS dbo.Enrolments;
DROP TABLE IF EXISTS dbo.EventCategories;
DROP TABLE IF EXISTS dbo.Categories;
DROP TABLE IF EXISTS dbo.Events;
DROP TABLE IF EXISTS dbo.Users;
GO

/* =========================================================
   USERS
   Stores both Organisers and Participants.
   ========================================================= */
CREATE TABLE dbo.Users 
(
    UserId INT IDENTITY(1,1) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL,
    Phone NVARCHAR(20) NULL,
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Users PRIMARY KEY (UserId),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT CK_Users_Role CHECK (Role IN (N'Organiser', N'Participant'))
);
GO

/* =========================================================
   EVENTS
   Each event is owned by one Organiser.
   ========================================================= */
CREATE TABLE dbo.Events 
(
    EventId INT IDENTITY(1,1) NOT NULL,
    OrganiserId INT NOT NULL,
    EventName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(500) NULL,
    Location NVARCHAR(200) NOT NULL,
    EventDate DATETIME2(0) NOT NULL,
    RegistrationDeadline DATETIME2(0) NOT NULL,
    Status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Events_Status DEFAULT (N'Open'),
    CreatedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Events_CreatedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Events PRIMARY KEY (EventId),
    CONSTRAINT FK_Events_Organiser
        FOREIGN KEY (OrganiserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT CK_Events_Status
        CHECK (Status IN (N'Draft', N'Open', N'Closed', N'Completed')),
    CONSTRAINT CK_Events_RegistrationDeadline
        CHECK (RegistrationDeadline <= EventDate)
);
GO

/* =========================================================
   CATEGORIES
   Reusable race categories such as 5 KM, 10 KM and 21 KM.
   ========================================================= */
CREATE TABLE dbo.Categories 
(
    CategoryId INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(300) NULL,

    CONSTRAINT PK_Categories PRIMARY KEY (CategoryId),
    CONSTRAINT UQ_Categories_Name UNIQUE (Name)
);
GO

/* =========================================================
   EVENT CATEGORIES
   Junction table resolving the many-to-many relationship
   between Events and Categories.
   Composite primary key: EventId + CategoryId.
   ========================================================= */
CREATE TABLE dbo.EventCategories 
(
    EventId INT NOT NULL,
    CategoryId INT NOT NULL,

    CONSTRAINT PK_EventCategories PRIMARY KEY (EventId, CategoryId),
    CONSTRAINT FK_EventCategories_Event
        FOREIGN KEY (EventId)
        REFERENCES dbo.Events(EventId)
        ON DELETE CASCADE,
    CONSTRAINT FK_EventCategories_Category
        FOREIGN KEY (CategoryId)
        REFERENCES dbo.Categories(CategoryId)
        ON DELETE CASCADE
);
GO

/* =========================================================
   ENROLMENTS
   Links a Participant to a valid Event + Category combination.
   ========================================================= */
CREATE TABLE dbo.Enrolments
(
    EnrolmentId INT IDENTITY(1,1) NOT NULL,
    ParticipantId INT NOT NULL,
    EventId INT NOT NULL,
    CategoryId INT NOT NULL,
    EnrolmentDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_Enrolments_EnrolmentDate DEFAULT (SYSDATETIME()),
    Status NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Enrolments_Status DEFAULT (N'Active'),

    CONSTRAINT PK_Enrolments PRIMARY KEY (EnrolmentId),
    CONSTRAINT FK_Enrolments_Participant
        FOREIGN KEY (ParticipantId) REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_Enrolments_EventCategory
        FOREIGN KEY (EventId, CategoryId)
        REFERENCES dbo.EventCategories(EventId, CategoryId),
    CONSTRAINT UQ_Enrolments_Participant_Event
        UNIQUE (ParticipantId, EventId),
    CONSTRAINT CK_Enrolments_Status
        CHECK (Status IN (N'Active', N'Cancelled'))
);
GO

/* =========================================================
   RESULTS
   A participant can receive at most one result per enrolment.
   An enrolment may have no result yet.
   ========================================================= */
CREATE TABLE dbo.Results
(
    ResultId INT IDENTITY(1,1) NOT NULL,
    EnrolmentId INT NOT NULL,
    FinishTime TIME(0) NULL,
    Position INT NULL,
    ResultStatus NVARCHAR(30) NOT NULL
        CONSTRAINT DF_Results_Status DEFAULT (N'Finished'),
    RecordedAt DATETIME2(0) NOT NULL
        CONSTRAINT DF_Results_RecordedAt DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Results PRIMARY KEY (ResultId),
    CONSTRAINT FK_Results_Enrolment
        FOREIGN KEY (EnrolmentId)
        REFERENCES dbo.Enrolments(EnrolmentId)
        ON DELETE CASCADE,
    CONSTRAINT UQ_Results_Enrolment UNIQUE (EnrolmentId),
    CONSTRAINT CK_Results_Position
        CHECK (Position IS NULL OR Position > 0),
    CONSTRAINT CK_Results_Status
        CHECK (ResultStatus IN
            (N'Finished', N'DNF', N'DNS', N'Disqualified'))
);
GO

/* =========================================================
   INDEXES
   These support common lookups used by the planned API.
   ========================================================= */
CREATE INDEX IX_Events_OrganiserId
    ON dbo.Events(OrganiserId);

CREATE INDEX IX_Events_EventDate
    ON dbo.Events(EventDate);

CREATE INDEX IX_EventCategories_CategoryId
    ON dbo.EventCategories(CategoryId);

CREATE INDEX IX_Enrolments_ParticipantId
    ON dbo.Enrolments(ParticipantId);

CREATE INDEX IX_Enrolments_EventId
    ON dbo.Enrolments(EventId);

CREATE INDEX IX_Results_Position
    ON dbo.Results(Position);
GO

/* =========================================================
   SEED DATA - USERS
   2 Organisers + 2 Participants.
   Demo password hashes are generated with SHA2_256 only for
   database seed-data demonstration. Part 2 should use the
   application's approved password-hashing implementation.
   ========================================================= */
INSERT INTO dbo.Users
    (FirstName, LastName, Email, PasswordHash, Role, Phone)
VALUES
    (N'Thabo', N'Mokoena',
     N'thabo.organiser@raceday.co.za',
     CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'RaceDayOrg1!'), 2),
     N'Organiser', N'0711111111'),

    (N'Lerato', N'Nkosi',
     N'lerato.organiser@raceday.co.za',
     CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'RaceDayOrg2!'), 2),
     N'Organiser', N'0722222222'),

    (N'Sipho', N'Dlamini',
     N'sipho.participant@raceday.co.za',
     CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'RaceDayPart1!'), 2),
     N'Participant', N'0733333333'),

    (N'Naledi', N'Molefe',
     N'naledi.participant@raceday.co.za',
     CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'RaceDayPart2!'), 2),
     N'Participant', N'0744444444');
GO

/* =========================================================
   SEED DATA - EVENTS
   3 realistic South African events.
   ========================================================= */
INSERT INTO dbo.Events
    (OrganiserId, EventName, Description, Location,
     EventDate, RegistrationDeadline, Status)
VALUES
    (1,
     N'Pretoria City Run',
     N'Road running event through central Pretoria and surrounding areas.',
     N'Pretoria, Gauteng',
     '2026-10-10 07:00:00',
     '2026-10-01 23:59:00',
     N'Open'),

    (1,
     N'Soweto Community Run',
     N'Community-focused road running event supporting local participation.',
     N'Soweto, Gauteng',
     '2026-11-07 07:30:00',
     '2026-10-30 23:59:00',
     N'Open'),

    (2,
     N'Cape Town Coastal Ride',
     N'Organised cycling event along the Cape Town coastal route.',
     N'Cape Town, Western Cape',
     '2026-12-05 06:30:00',
     '2026-11-25 23:59:00',
     N'Open');
GO

/* =========================================================
   SEED DATA - CATEGORIES
   More than the minimum to demonstrate reusable categories.
   ========================================================= */
INSERT INTO dbo.Categories
    (Name, Description)
VALUES
    (N'5 KM Run', N'Short-distance five kilometre road race.'),
    (N'10 KM Run', N'Ten kilometre road race.'),
    (N'21 KM Half Marathon', N'Half marathon road race.'),
    (N'5 KM Fun Run', N'Accessible five kilometre community fun run.'),
    (N'10 KM Community Run', N'Ten kilometre community road race.'),
    (N'50 KM Cycle', N'Fifty kilometre road cycling category.'),
    (N'100 KM Cycle', N'One hundred kilometre road cycling category.');
GO

/* =========================================================
   SEED DATA - EVENT/CATEGORY ASSOCIATIONS
   ========================================================= */
INSERT INTO dbo.EventCategories (EventId, CategoryId)
VALUES
    (1, 1),  -- Pretoria City Run - 5 KM
    (1, 2),  -- Pretoria City Run - 10 KM
    (1, 3),  -- Pretoria City Run - Half Marathon
    (2, 4),  -- Soweto - 5 KM Fun Run
    (2, 5),  -- Soweto - 10 KM Community Run
    (3, 6),  -- Cape Town - 50 KM Cycle
    (3, 7);  -- Cape Town - 100 KM Cycle
GO

/* =========================================================
   SEED DATA - ENROLMENTS
   ========================================================= */
INSERT INTO dbo.Enrolments
    (ParticipantId, EventId, CategoryId, Status)
VALUES
    (3, 1, 2, N'Active'),
    (4, 1, 3, N'Active'),
    (3, 2, 4, N'Active'),
    (4, 3, 6, N'Active'),
    (3, 3, 7, N'Active');
GO

/* =========================================================
   SEED DATA - RESULTS
   Results are linked to existing enrolments.
   ========================================================= */
INSERT INTO dbo.Results
    (EnrolmentId, FinishTime, Position, ResultStatus)
VALUES
    (1, '00:52:34', 12, N'Finished'),
    (2, '01:48:22', 7, N'Finished'),
    (3, NULL, NULL, N'DNS');
GO

/* =========================================================
   VERIFICATION QUERIES
   These ALWAYS run and show results every time!
   ========================================================= */
SELECT * FROM dbo.Users;
SELECT * FROM dbo.Events;
SELECT * FROM dbo.Categories;
SELECT * FROM dbo.EventCategories;
SELECT * FROM dbo.Enrolments;
SELECT * FROM dbo.Results;
GO

/* Relationship verification query */
SELECT
    e.EventName,
    c.Name AS CategoryName,
    u.FirstName + N' ' + u.LastName AS Participant,
    en.Status AS EnrolmentStatus,
    r.FinishTime,
    r.Position,
    r.ResultStatus
FROM dbo.Enrolments AS en
INNER JOIN dbo.Users AS u
    ON en.ParticipantId = u.UserId
INNER JOIN dbo.Events AS e
    ON en.EventId = e.EventId
INNER JOIN dbo.Categories AS c
    ON en.CategoryId = c.CategoryId
LEFT JOIN dbo.Results AS r
    ON en.EnrolmentId = r.EnrolmentId
ORDER BY e.EventDate, c.Name, Participant;
GO
