SELECT
    C.ConferenceID,
    C.Name AS ConferenceName,
    EXTRACT(YEAR FROM C.StartDate) AS ConferenceYear,
    COUNT(S.SubmissionID) AS TotalSubmissions,
    COUNT(CASE WHEN S.Decision = 'Accept' THEN 1 END) AS AcceptedSubmissions,
    ROUND(
        (COUNT(CASE WHEN S.Decision = 'Accept' THEN 1 END)::DECIMAL / COUNT(S.SubmissionID)) * 100,
        2
    ) AS PercentageAccepted
FROM
    A3Conference.Conference C
JOIN
    A3Conference.Session Se ON C.ConferenceID = Se.ConferenceID
JOIN
    A3Conference.Presentation P ON Se.SessionID = P.SessionID
JOIN
    A3Conference.Submission S ON P.SubmissionID = S.SubmissionID
GROUP BY
    C.ConferenceID,
    C.Name,
    ConferenceYear
ORDER BY
    C.ConferenceID,
    ConferenceYear;
