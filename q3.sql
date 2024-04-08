SET SEARCH_PATH TO A3Conference;
DROP TABLE IF EXISTS q3 cascade;

WITH AcceptedPapers AS (
    SELECT s.ConferenceID, s.SubmissionID, a.AuthorID
    FROM Submission s
    JOIN Authorship a ON s.SubmissionID = a.SubmissionID
    WHERE s.Decision = 'Accept' AND s.Type = 'Paper' AND a.AuthorOrder = 1
)
SELECT c.ConferenceID, c.Name AS ConferenceName, a.FullName AS AuthorName
FROM Conference c
JOIN AcceptedPapers ap ON c.ConferenceID = ap.ConferenceID
JOIN Person a ON ap.AuthorID = a.PersonID
WHERE c.ConferenceID = (
    SELECT ConferenceID
    FROM (
        SELECT ConferenceID, COUNT(*) AS AcceptedPapersCount
        FROM AcceptedPapers
        GROUP BY ConferenceID
        ORDER BY AcceptedPapersCount DESC
        LIMIT 1
    ) AS HighestAcceptedPapers
    
)
ORDER BY c.ConferenceID, a.FullName;

