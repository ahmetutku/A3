--Overview:

-- Could no ensure: (most of these would require a trigger or more logical operations)
        -- SessionChair must be an attendee not presenting in this session.
        -- SessionChair must be an attendee not presenting in this session.
        -- Session times don't overlap with other sessions within the same period
        -- Each submission of paper having one author as a reviewer
        -- Session start and end times are within the conference duration, necessitating external validation.
        -- A submission's decision progresses from 'Pending' to either 'Accept' or 'Reject'.
        -- Tracking how many Acceptions/ Rejections a submission has
        -- Only assigning 3 people to decide for the submision
        -- Not assigning authors their own submission
        -- not allowing new submission that has been accepted before without a trigger
        -- Multiple posters being presented in the same timeslot
        -- Chairs must have been on the committee twice before.
        -- Chairs are required to have prior committee experience
        -- Each submission hacing at least one registered person
        -- Students having a different fee than the rest
        -- Submission not being accepted if no reviewer reccomended accept
        -- An author not having two presentations at the same time with the exception that it is one paper and one poster both in which they are not the sole contributor


-- Did not:
-- Extra constraints:
    -- Sessions, including paper and poster sessions, are well-defined time blocks that can accommodate presentations with specific start and end times.
-- Assumptions:
    --Every attendee needs tp pay a fee
    -- For the Reviews table, we assumed a reviewer can only review a submission once.
    -- An author cannot review his or her paper
    -- This schema assumes either individual time slots for posters or a collective time block entry.
    -- Workshops are specialized sessions within a conference, facilitated by one or more persons.
    -- Workshops can have multiple faciliatators
    -- Assuming fees are monetary values with 2 decimal places.
    -- A reviewer can accept the submission whilst declaring a conflict


--did we do this:
-- Create a people table as we have assumed that reviewers, session chairs, attendees and facilitator are all authors

-- Drop and Create Schema
DROP SCHEMA IF EXISTS A3Conference CASCADE;
CREATE SCHEMA A3Conference;
SET SEARCH_PATH TO A3Conference;

CREATE TABLE Organization (
    OrganizationID INT PRIMARY KEY,
    Name TEXT,
    ContactInfo TEXT
    -- Assumption: Each organization is unique and can be associated with multiple persons.
);

CREATE TABLE Person (
    PersonID INT PRIMARY KEY,
    FullName TEXT,
    Email TEXT UNIQUE,
    OrganizationID INT NOT NULL,
    FOREIGN KEY (OrganizationID) REFERENCES Organization(OrganizationID)
    -- Assumption: A person is uniquely identified by their ID and can belong to only one organization.
    -- Assumption: Each person has a unique email address.
);

CREATE TABLE Conference (
    ConferenceID INT PRIMARY KEY,
    Name TEXT,
    Location TEXT,
    StartDate DATE,
    EndDate DATE
    CHECK (StartDate < EndDate)
    -- Assumption: Each conference is a unique event with a distinct name, location, and time frame.
);



CREATE TABLE Session (
    SessionID INT PRIMARY KEY,
    ConferenceID INT,
    SessionChairID INT,
    StartTime TIMESTAMP,
    EndTime TIMESTAMP,
    Type TEXT,
    FOREIGN KEY (ConferenceID) REFERENCES Conference(ConferenceID),
    FOREIGN KEY (SessionChairID) REFERENCES Person(PersonID),
    CHECK (Type IN ('Paper', 'Poster')),
    CHECK (StartTime < EndTime)
    -- Constraint: SessionChair must be an attendee not presenting in this session.
    -- This cannot be directly enforced without a trigger.

    -- Cannot enforce that the session chair is not a presenting author in the session without a trigger.
    -- Cannot ensure session times don't overlap with other sessions within the same period

    -- Assumption: Sessions are specific segments within a conference, categorized as either 'Paper' or 'Poster'.
    -- Constraint: Each session is chaired by a person who is not presenting in that session, requiring application logic to ensure.
    -- Constraint: Session start and end times are within the conference duration, necessitating external validation.
);

CREATE TABLE Submission (
    SubmissionID INT PRIMARY KEY,
    Title TEXT,
    Type TEXT,
    Decision TEXT,
    CHECK (Type IN ('Paper', 'Poster')),
    CHECK (Decision IN ('Pending', 'Accept', 'Reject'))
    -- Assumption: Submissions are proposals for conference content, reviewed and either accepted or rejected.
    -- Constraint: A submission's decision progresses from 'Pending' to either 'Accept' or 'Reject'.

    -- Cannot prevent duplicate submissions (identical title, type, and authors) without a trigger.

    -- Cannot make sure not allowing new submission that has been accepted before without a trigger
);

CREATE TABLE Authorship (
    SubmissionID INT,
    AuthorID INT,
    AuthorOrder INT,
    FOREIGN KEY (SubmissionID) REFERENCES Submission(SubmissionID),
    FOREIGN KEY (AuthorID) REFERENCES Person(PersonID),
    PRIMARY KEY (SubmissionID, AuthorID),
    UNIQUE (SubmissionID, AuthorOrder)
    -- Assumption: Submissions can have multiple authors, with the order of authorship being significant.
    -- Constraint: Each author is uniquely associated with a submission but can appear in different submissions.
);

CREATE TABLE Review (
    ReviewID INT PRIMARY KEY,
    SubmissionID INT,
    ReviewerID INT,
    Recommendation TEXT CHECK (Recommendation IN ('Accept', 'Reject')),
    HasConflict BOOLEAN NOT NULL,
    FOREIGN KEY (SubmissionID) REFERENCES Submission(SubmissionID),
    FOREIGN KEY (ReviewerID) REFERENCES Person(PersonID)
    -- Constraint: Reviewers cannot review their own or co-authors' submissions.
    -- This check cannot be implemented directly in the schema without a trigger.
    -- The Recommendation column now accepts 'Accept' or 'Reject' as text.
    -- The HasConflict boolean indicates if there are additional conflicts beyond co-authorship or organizational conflicts.

    -- Assumption: Reviews are assessments of submissions, recommending acceptance or rejection.
    -- Assumption: The HasConflict flag is manually set based on additional conflict checks.
    -- Constraint: Reviewers cannot review their own submissions or those of their co-authors.
    -- Note: Enforcing the no self-review or co-author review rule requires application logic or manual validation, as SQL constraints cannot assess relational data complexities for this rule.
);


CREATE TABLE Presentation (
    PresentationID INT PRIMARY KEY, -- Unique identifier for each presentation.
    SubmissionID INT, -- Links the presentation to a specific submission (paper or poster).
    SessionID INT, -- Indicates which session the presentation belongs to.
    StartTime TIMESTAMP, -- Specific start time of the presentation within the session.
    EndTime TIMESTAMP, -- Specific end time of the presentation within the session.
    FOREIGN KEY (SubmissionID) REFERENCES Submission(SubmissionID),
    FOREIGN KEY (SessionID) REFERENCES Session(SessionID),
    UNIQUE (SessionID, StartTime), -- Ensures no overlapping presentations within the same session.
    CHECK (StartTime < EndTime) -- Ensures that the start time is before the end time.
    -- Assumption: Sessions, including paper and poster sessions, are well-defined time blocks that can accommodate presentations with specific start and end times.
    -- Assumption: The scheduling does not account for breaks or transitions between presentations; those must be managed externally or factored into the timing.
    -- Constraint: A single session cannot have two presentations that start at the same time, preventing scheduling conflicts within a session.
    -- Constraint: Every presentation must have a defined duration, with the end time always after the start time.
    -- Note: For poster sessions where multiple posters may be presented simultaneously throughout the session, the handling of start and end times may need to be adapted. 
    -- This schema assumes either individual time slots for posters or a collective time block entry.
    -- Note: This table does not explicitly handle scheduling constraints related to presenter availability or room capacity; such considerations are outside the scope of this simple scheduling mechanism.
);


CREATE TABLE Workshop (
    WorkshopID INT PRIMARY KEY,
    ConferenceID INT,
    Title TEXT,
    Fee DECIMAL(10, 2), -- Assuming fees are monetary values with 2 decimal places
    FOREIGN KEY (ConferenceID) REFERENCES Conference(ConferenceID)
    -- Removed FacilitatorID to support multiple facilitators through a linking table.
);

CREATE TABLE WorkshopFacilitators (
    WorkshopID INT,
    FacilitatorID INT,
    FOREIGN KEY (WorkshopID) REFERENCES Workshop(WorkshopID),
    FOREIGN KEY (FacilitatorID) REFERENCES Person(PersonID),
    PRIMARY KEY (WorkshopID, FacilitatorID)
    -- Each record represents a facilitator for a workshop.
    -- A workshop can have multiple facilitators, and a person can facilitate multiple workshops.
);


CREATE TABLE Attendee (
    AttendeeID INT PRIMARY KEY,
    PersonID INT,
    ConferenceID INT,
    IsStudent BOOLEAN,
    Fee DECIMAL(10, 2), -- Assuming fees are monetary values with 2 decimal places.
    FOREIGN KEY (PersonID) REFERENCES Person(PersonID),
    FOREIGN KEY (ConferenceID) REFERENCES Conference(ConferenceID)
    -- Constraint: At least one author per accepted submission must be registered.
    -- This complex constraint is difficult to enforce directly in the schema.

    -- Assumption: Attendees are conference participants, potentially benefiting from student discounts.
    -- Constraint: At least one author of an accepted submission must register as an attendee.
);


CREATE TABLE WorkshopRegistration (
    AttendeeID INT,
    WorkshopID INT,
    FeePaid BOOLEAN,
    FOREIGN KEY (AttendeeID) REFERENCES Attendee(AttendeeID),
    FOREIGN KEY (WorkshopID) REFERENCES Workshop(WorkshopID),
    PRIMARY KEY (AttendeeID, WorkshopID)
    -- Assumption: Attendees can register for multiple workshops.
);

CREATE TABLE ConferenceCommittee (
    CommitteeID INT PRIMARY KEY,
    ConferenceID INT,
    MemberID INT,
    Role TEXT,
    FOREIGN KEY (ConferenceID) REFERENCES Conference(ConferenceID),
    FOREIGN KEY (MemberID) REFERENCES Person(PersonID)
    -- Constraint: Chairs must have been on the committee twice before.
    -- This requirement cannot be directly enforced in the schema without historical data checks or a trigger.
    -- Assumption: The conference committee is responsible for organizing the conference, with roles including chairs and members.
    -- Constraint: Chairs are required to have prior committee experience, though this must be validated outside the database structure.
);
