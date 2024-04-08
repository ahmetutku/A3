SET SEARCH_PATH TO A3Conference;
DROP TABLE IF EXISTS q4 cascade;

DROP VIEW IF EXISTS AcceptedSubmissions CASCADE;
DROP VIEW IF EXISTS RejectionsCount CASCADE;
DROP VIEW IF EXISTS RandA CASCADE;

CREATE VIEW AcceptedSubmissions AS
SELECT *
FROM Submission
WHERE Decision = 'Accept';

-- submissions that have been accepted 
-- and submissions that have been rejected but accepted at least once
CREATE VIEW RandA AS
SELECT s.SubmissionID, s.ConferenceID, s.Title, s.Type, s.Decision
FROM AcceptedSubmissions a JOIN Submission s ON a.Title = s.Title;

CREATE VIEW RejectionsCount AS
SELECT Title, count(*) AS NumberRejections
FROM RandA
WHERE Decision = 'Reject'
GROUP BY Title;

SELECT Title, MAX(NumberRejections)
FROM RejectionsCount
GROUP BY Title


