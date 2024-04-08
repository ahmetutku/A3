WITH ConferenceSubmissions AS (
    SELECT
        c.ConferenceID,
        c.StartDate,
        SUM(CASE WHEN s.Decision = 'Accept' THEN 1 ELSE 0 END) AS AcceptedSubmissions,
        COUNT(*) AS TotalSubmissions
    FROM
        A3Conference.Conference c
    JOIN
        A3Conference.Session ses ON c.ConferenceID = ses.ConferenceID
    JOIN
        A3Conference.Presentation p ON ses.SessionID = p.SessionID
    JOIN
        A3Conference.Submission s ON p.SubmissionID = s.SubmissionID
    GROUP BY
        c.ConferenceID, c.StartDate
)
SELECT
    ConferenceID,
    StartDate AS ConferenceYear,
    ROUND((AcceptedSubmissions::DECIMAL / TotalSubmissions) * 100, 2) AS PercentageAccepted
FROM
    ConferenceSubmissions
ORDER BY
    StartDate, ConferenceID;
