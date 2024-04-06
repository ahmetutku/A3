SET SEARCH_PATH TO A3Conference;

-- Import Data for Organization
\Copy Organization FROM 'data/Organization.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Person
\Copy Person FROM 'data/Person.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Conference
\Copy Conference FROM 'data/Conference.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Session
\Copy Session FROM 'data/Session.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Submission
\Copy Submission FROM 'data/Submission.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Authorship
\Copy Authorship FROM 'data/Authorship.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Review
\Copy Review FROM 'data/Review.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Presentation
\Copy Presentation FROM 'data/Presentation.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Workshop
\Copy Workshop FROM 'data/Workshop.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for WorkshopFacilitators
\Copy WorkshopFacilitators FROM 'data/WorkshopFacilitators.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for Attendee
\Copy Attendee FROM 'data/Attendee.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for WorkshopRegistration
\Copy WorkshopRegistration FROM 'data/WorkshopRegistration.csv' With CSV DELIMITER ',' HEADER;

-- Import Data for ConferenceCommittee
\Copy ConferenceCommittee FROM 'data/ConferenceCommittee.csv' With CSV DELIMITER ',' HEADER;