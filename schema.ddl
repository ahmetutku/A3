-- Could not:
-- Did not:
-- Extra constraints:
-- Assumptions:
-- For the Reviews table, we assumed a reviewer can only review a submission once.

-- Create a people table as we have assumed that reviewers, session chairs, attendees and facilitator are all authors

-- Drop and Create Schema
DROP SCHEMA IF EXISTS A3Conference CASCADE;
CREATE SCHEMA A3Conference;
SET SEARCH_PATH TO A3Conference;

-- Conferences Table
CREATE TABLE Conferences (
    conference_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    conference_date DATE NOT NULL
);

-- Authors Table
CREATE TABLE Authors (
    author_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    organization TEXT NOT NULL
);

-- Submissions Table
CREATE TABLE Submissions (
    submission_id SERIAL PRIMARY KEY,
    -- The conference at which the submission will be presented.
    conference_id INTEGER NOT NULL,
    -- The title of the event.
    title TEXT NOT NULL,
    -- The type of submission.
    submission_type TEXT NOT NULL,
    -- The submition status.
    status VARCHAR(50) NOT NULL, -- status not specified in assignment.
    FOREIGN KEY (conference_id) REFERENCES Conferences(conference_id),
    UNIQUE (title, submission_type, conference_id), -- Constraints needs to be changed
    CHECK (submission_type IN ('Paper', 'Poster')),
    CHECK (status IN ('Submitted', 'Accepted', 'Rejected'))
);

-- Author_Submission Relationship Table
CREATE TABLE Author_Submission (
    -- The author of a submission.
    author_id INTEGER NOT NULL,
    submission_id INTEGER NOT NULL,
    -- The order in which the author name is presented on a paper.
    -- The order is ascending.
    -- ex: if the author_order = 1, that author will have his name appear first on the paper.
    author_order INTEGER NOT NULL, -- this can be NULL if the submission is not a paper but a poster.
    PRIMARY KEY (author_id, submission_id),
    FOREIGN KEY (author_id) REFERENCES Authors(author_id),
    FOREIGN KEY (submission_id) REFERENCES Submissions(submission_id),
    UNIQUE (submission_id, author_order)
);

-- Reviews Table
CREATE TABLE Reviews (
    review_id SERIAL PRIMARY KEY,
    -- The submission that is being reviewed.
    submission_id INTEGER NOT NULL,
    -- The author that is reviewing the submission.
    reviewer_id INTEGER NOT NULL,
    -- The recommendation the reviewer gave for the submission.
    recommendation TEXT CHECK (recommendation IN ('Accept', 'Reject')),
    FOREIGN KEY (submission_id) REFERENCES Submissions(submission_id),
    FOREIGN KEY (reviewer_id) REFERENCES Authors(author_id),
    -- We assume a reviewer can review a submission only once.
    UNIQUE (submission_id, reviewer_id)
);

-- Presentations Table
CREATE TABLE Presentations (
    presentation_id SERIAL PRIMARY KEY,
    -- The submission presented in the presentation.
    submission_id INTEGER NOT NULL,
    presented_during TEXT NOT NULL, -- not sure what this is supposed to represent
    -- The time at which the presentation of the submission starts.
    start_time TIMESTAMP NOT NULL, -- Could this be NULL in the case where it is a "poster session"? -- Make this a key with other presentation presented in the same session if paper session.
    -- The time at which the presentation of the submission ends.
    end_time TIMESTAMP NOT NULL, -- Not specified in the assignment.
    -- The session chair for the paper session.
    -- The attribute can be NULL in the case this presentation is part of a poster session.
    session_chair_id INTEGER,
    FOREIGN KEY (session_chair_id) REFERENCES Authors(author_id),
    FOREIGN KEY (submission_id) REFERENCES Submissions(submission_id),
    -- Assuming session chair is an author who will not have a paper in the same session.
    CONSTRAINT fk_conference FOREIGN KEY (submission_id) REFERENCES Conferences(conference_id), -- I think this FKC is wrong.
    CHECK (start_time < end_time)
);

-- Registrations Table
CREATE TABLE Registrations (
    registration_id SERIAL PRIMARY KEY,
    -- The person that attends the conference.
    attendee_id INTEGER NOT NULL,
    conference_id INTEGER NOT NULL,
    -- The type of  attendee (student or regular).
    registration_type TEXT NOT NULL,
    -- The registration fee to attend the conference.
    fee DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (attendee_id) REFERENCES Authors(author_id),
    FOREIGN KEY (conference_id) REFERENCES Conferences(conference_id),
    CHECK (registration_type IN ('Regular', 'Student'))
    -- Need a way to check that students pay the lower of both fees.
    -- Need to be able to register to Workshops too or maybe create a new table for it?
);

-- Workshops Table
CREATE TABLE Workshops (
    workshop_id SERIAL PRIMARY KEY,
    -- The conference in which this workshop is held.
    conference_id INTEGER NOT NULL,
    -- The name of the workshop.
    title TEXT NOT NULL,
    -- The facilitator of the workshop.
    facilitator_id INTEGER NOT NULL,
    FOREIGN KEY (conference_id) REFERENCES Conferences(conference_id),
    FOREIGN KEY (facilitator_id) REFERENCES Authors(author_id)
    -- Additional registration details for workshops would be required
);

-- Organizing Committees Table
CREATE TABLE OrganizingCommittees (
    committee_id SERIAL PRIMARY KEY,
    conference_id INTEGER REFERENCES Conferences(conference_id),
    member_id INTEGER REFERENCES Authors(author_id),
    role VARCHAR(255),
    -- Constraints for role and other rules would be needed
    UNIQUE (conference_id, member_id)
);

-- Conference Chairs Table
CREATE TABLE ConferenceChairs (
    chair_id INTEGER REFERENCES Authors(author_id),
    conference_id INTEGER REFERENCES Conferences(conference_id),
    tenure INTEGER CHECK (tenure >= 0),
    PRIMARY KEY (chair_id, conference_id)
    -- Assuming tenure is the number of times they have been on the committee
    -- Additional logic for enforcing the "at least twice" rule might be needed
);


--Triggers
--A) For Review
-- Additional tables and relationships would be defined as needed based on the requirements
-- Check if reviewer is also an author of the submission
    CREATE FUNCTION check_reviewer_not_author() RETURNS TRIGGER AS $$
    BEGIN
        -- Check if reviewer is also an author of the submission
        IF EXISTS (
            SELECT 1
            FROM Author_Submission
            WHERE submission_id = NEW.submission_id
            AND author_id = NEW.reviewer_id
        ) THEN
            RAISE EXCEPTION 'Reviewers cannot review their own submissions.';
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_check_reviewer_not_author
    BEFORE INSERT OR UPDATE ON Reviews
    FOR EACH ROW
    EXECUTE FUNCTION check_reviewer_not_author();

-- Check if reviewer is a co-author with any of the authors of the submission
    CREATE FUNCTION check_co_author_conflict() RETURNS TRIGGER AS $$
    BEGIN
        -- Check if reviewer is a co-author with any of the authors of the submission
        IF EXISTS (
            SELECT 1
            FROM Author_Submission AS1
            JOIN Author_Submission AS2 ON AS1.submission_id = AS2.submission_id
            WHERE AS1.author_id = NEW.reviewer_id
            AND AS2.author_id != NEW.reviewer_id
            AND AS2.submission_id = NEW.submission_id
        ) THEN
            RAISE EXCEPTION 'Reviewers cannot review submissions from their co-authors.';
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_check_co_author_conflict
    BEFORE INSERT OR UPDATE ON Reviews
    FOR EACH ROW
    EXECUTE FUNCTION check_co_author_conflict();

-- Check if reviewer and authors of the submission are from the same organization
    CREATE FUNCTION check_organization_conflict() RETURNS TRIGGER AS $$
    BEGIN
        -- Check if reviewer and authors of the submission are from the same organization
        IF EXISTS (
            SELECT 1
            FROM Authors A
            JOIN Author_Submission ASUB ON A.author_id = ASUB.author_id
            WHERE ASUB.submission_id = NEW.submission_id
            AND A.organization = (SELECT organization FROM Authors WHERE author_id = NEW.reviewer_id)
        ) THEN
            RAISE EXCEPTION 'Reviewers cannot review submissions from their organization.';
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_check_organization_conflict
    BEFORE INSERT OR UPDATE ON Reviews
    FOR EACH ROW
    EXECUTE FUNCTION check_organization_conflict();

    CREATE TABLE DeclaredConflicts (
        reviewer_id INTEGER REFERENCES Authors(author_id),
        submission_id INTEGER REFERENCES Submissions(submission_id),
        PRIMARY KEY (reviewer_id, submission_id)
    );
-- Check if there are declared conflicts for the reviewer and submission
    CREATE FUNCTION check_additional_conflicts() RETURNS TRIGGER AS $$
    BEGIN
        -- Check if there are declared conflicts for the reviewer and submission
        IF EXISTS (
            SELECT 1
            FROM DeclaredConflicts
            WHERE reviewer_id = NEW.reviewer_id
            AND submission_id = NEW.submission_id
        ) THEN
            RAISE EXCEPTION 'Reviewers have declared a conflict with this submission.';
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_check_additional_conflicts
    BEFORE INSERT OR UPDATE ON Reviews
    FOR EACH ROW
    EXECUTE FUNCTION check_additional_conflicts();


--b) Submissitions
--Check ifa subission has been checked three times
    CREATE OR REPLACE FUNCTION fn_adjust_submission_status() RETURNS TRIGGER AS $$
    DECLARE
        review_count INTEGER;
        accept_count INTEGER;
    BEGIN
        -- Count the total number of reviews for the submission
        SELECT COUNT(*) INTO review_count
        FROM Reviews
        WHERE submission_id = NEW.submission_id;

        IF review_count < 3 THEN
            -- Automatically set the status to 'Submitted' if there are less than three reviews
            NEW.status := 'Submitted';
            RETURN NEW;
        ELSE
            -- Count the number of 'Accept' recommendations for the submission
            SELECT COUNT(*) INTO accept_count
            FROM Reviews
            WHERE submission_id = NEW.submission_id AND recommendation = 'Accept';

            -- Enforce at least one 'Accept' recommendation for 'Accepted' status
            IF accept_count < 2 THEN
                NEW.status := 'Rejected';
            ELSE
                NEW.status := 'Accepted';
            END IF;

            RETURN NEW;
        END IF;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_adjust_submission_status
    BEFORE UPDATE OF status ON Submissions
    FOR EACH ROW
    EXECUTE FUNCTION fn_adjust_submission_status();

--Check if accepted ant be submitted again
    CREATE OR REPLACE FUNCTION fn_prevent_duplicate_accepted_submissions() RETURNS TRIGGER AS $$
    BEGIN
        -- Check for an existing 'Accepted' submission with the same title and type
        IF EXISTS (
            SELECT 1
            FROM Submissions
            WHERE title = NEW.title
            AND submission_type = NEW.submission_type
            AND status = 'Accepted'
            AND submission_id != NEW.submission_id -- Exclude self for updates
        ) THEN
            RAISE EXCEPTION 'An accepted submission with the same title and type already exists.';
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_prevent_duplicate_accepted_submissions
    BEFORE INSERT OR UPDATE ON Submissions
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_duplicate_accepted_submissions();

--c) Presentation
--Paper presentations must have unique timestamps
    CREATE OR REPLACE FUNCTION fn_check_presentation_timing() RETURNS TRIGGER AS $$
    DECLARE
        submission_type VARCHAR(50);
    BEGIN
        -- Determine if the submission is a paper or poster
        SELECT submission_type INTO submission_type FROM Submissions WHERE submission_id = NEW.submission_id;
        
        IF submission_type = 'Paper' THEN
            -- Check for overlapping paper presentations
            IF EXISTS (
                SELECT 1 FROM Presentations
                JOIN Submissions ON Presentations.submission_id = Submissions.submission_id
                WHERE Submissions.submission_type = 'Paper'
                AND Presentations.presented_during = NEW.presented_during
                AND ((NEW.start_time < Presentations.end_time AND NEW.start_time >= Presentations.start_time) OR
                    (NEW.end_time > Presentations.start_time AND NEW.end_time <= Presentations.end_time) OR
                    (NEW.start_time <= Presentations.start_time AND NEW.end_time >= Presentations.end_time))
                AND Presentations.presentation_id != NEW.presentation_id -- Exclude self for updates
            ) THEN
                RAISE EXCEPTION 'Overlapping paper presentations in the same session are not allowed.';
            END IF;
        END IF;
        
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_check_presentation_timing
    BEFORE INSERT OR UPDATE ON Presentations
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_presentation_timing();

--making sure that there are not scheduling conflicts for authors
    CREATE OR REPLACE FUNCTION fn_check_author_presentation_overlap() RETURNS TRIGGER AS $$
    DECLARE
        v_paper_authors INT;
        v_poster_authors INT;
        v_author_id INT;
    BEGIN
        -- Iterate through each author of the new/updated presentation's submission
        FOR v_author_id IN SELECT author_id FROM Author_Submission WHERE submission_id = NEW.submission_id LOOP
            
            -- Check if this author is involved in another presentation at the same time
            IF EXISTS (
                SELECT 1 FROM Presentations
                JOIN Author_Submission ON Presentations.submission_id = Author_Submission.submission_id
                WHERE Author_Submission.author_id = v_author_id
                AND Presentations.start_time = NEW.start_time
                AND Presentations.presentation_id != NEW.presentation_id -- Avoid self-comparison for updates
            ) THEN
                -- Count authors for both the new/updated submission and the overlapping one
                SELECT COUNT(*) INTO v_paper_authors FROM Author_Submission WHERE submission_id = NEW.submission_id;
                SELECT COUNT(*) INTO v_poster_authors FROM Author_Submission
                JOIN Presentations ON Author_Submission.submission_id = Presentations.submission_id
                WHERE Presentations.start_time = NEW.start_time
                AND Author_Submission.author_id = v_author_id;

                -- If there's overlap and either the new or existing presentation has only one author, raise exception
                IF v_paper_authors = 1 OR v_poster_authors = 1 THEN
                    RAISE EXCEPTION 'An author cannot have two presentations at the same time unless they are co-authored.';
                END IF;
            END IF;
        END LOOP;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER trg_check_author_presentation_overlap
    BEFORE INSERT OR UPDATE ON Presentations
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_author_presentation_overlap();

