SET SEARCH_PATH TO A3Conference;
DROP TABLE IF EXISTS q1 cascade;

DROP VIEW IF EXISTS SubmissionCounts CASCADE;

CREATE VIEW SubmissionCounts AS
SELECT
    ConferenceID,
    SUM(CASE WHEN Decision = 'Accept' THEN 1 ELSE 0 END) AS AcceptedSubmissions,
    COUNT(*) AS TotalSubmissions
FROM Submission
GROUP BY ConferenceID;

SELECT
    c.ConferenceID,
    c.Name,
    c.StartDate,
    ROUND((sc.AcceptedSubmissions::DECIMAL / sc.TotalSubmissions) * 100, 2) AS PercentageAccepted
FROM
    SubmissionCounts sc JOIN Conference c ON sc.ConferenceID = c.ConferenceID;
