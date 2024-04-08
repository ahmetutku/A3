WITH SessionInfo AS (
    SELECT
        c.ConferenceID,
        c.Name AS ConferenceName,
        s.SessionID,
        s.Type AS SessionType,
        COUNT(p.SubmissionID) AS SubmissionCount
    FROM
        A3Conference.Conference c
    JOIN
        A3Conference.Session s ON c.ConferenceID = s.ConferenceID
    JOIN
        A3Conference.Presentation p ON s.SessionID = p.SessionID
    JOIN
        A3Conference.Submission sub ON p.SubmissionID = sub.SubmissionID
    WHERE
        sub.Decision = 'Accept'
    GROUP BY
        c.ConferenceID, c.Name, s.SessionID, s.Type
)
SELECT
    ConferenceID,
    ConferenceName,
    AVG(SubmissionCount) FILTER (WHERE SessionType = 'Paper') AS AvgPapersPerSession,
    AVG(SubmissionCount) FILTER (WHERE SessionType = 'Poster') AS AvgPostersPerSession
FROM
    SessionInfo
GROUP BY
    ConferenceID, ConferenceName
ORDER BY
    ConferenceID;
