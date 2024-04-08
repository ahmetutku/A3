WITH SessionCounts AS (
    SELECT
        C.ConferenceID,
        C.Name AS ConferenceName,
        C.StartDate,
        Se.Type AS SessionType,
        COUNT(P.SubmissionID) AS SubmissionCount
    FROM
        A3Conference.Conference C
    JOIN
        A3Conference.Session Se ON C.ConferenceID = Se.ConferenceID
    JOIN
        A3Conference.Presentation P ON Se.SessionID = P.SessionID
    JOIN
        A3Conference.Submission S ON P.SubmissionID = S.SubmissionID AND S.Decision = 'Accept'
    GROUP BY
        C.ConferenceID, C.Name, C.StartDate, Se.Type
),
AverageCounts AS (
    SELECT
        ConferenceID,
        ConferenceName,
        StartDate,
        AVG(CASE WHEN SessionType = 'Paper' THEN SubmissionCount ELSE NULL END) AS AvgPapersPerSession,
        AVG(CASE WHEN SessionType = 'Poster' THEN SubmissionCount ELSE NULL END) AS AvgPostersPerSession
    FROM
        SessionCounts
    GROUP BY
        ConferenceID, ConferenceName, StartDate
)
SELECT
    ConferenceID,
    ConferenceName,
    StartDate,
    COALESCE(AvgPapersPerSession, 0) AS AvgPapersPerSession,
    COALESCE(AvgPostersPerSession, 0) AS AvgPostersPerSession
FROM
    AverageCounts
ORDER BY
    StartDate, ConferenceName;
