WITH AcceptedPapers AS (
    SELECT
        Se.ConferenceID,
        S.SubmissionID
    FROM
        A3Conference.Submission S
    JOIN
        A3Conference.Presentation P ON S.SubmissionID = P.SubmissionID
    JOIN
        A3Conference.Session Se ON P.SessionID = Se.SessionID
    WHERE
        S.Type = 'Paper'
        AND S.Decision = 'Accept'
    GROUP BY
        Se.ConferenceID, S.SubmissionID
),
ConferenceRank AS (
    SELECT
        ConferenceID,
        COUNT(SubmissionID) AS AcceptedPapersCount
    FROM
        AcceptedPapers
    GROUP BY
        ConferenceID
    ORDER BY
        AcceptedPapersCount DESC
    LIMIT 1
),
FirstAuthors AS (
    SELECT
        AP.ConferenceID,
        A.AuthorID,
        MIN(A.AuthorOrder) AS AuthorOrder
    FROM
        Authorship A
    JOIN
        AcceptedPapers AP ON A.SubmissionID = AP.SubmissionID
    GROUP BY
        AP.ConferenceID, A.AuthorID
    HAVING
        MIN(A.AuthorOrder) = 1
)
SELECT
    FA.ConferenceID,
    C.Name AS ConferenceName,
    P.FullName AS FirstAuthorName,
    P.Email AS FirstAuthorEmail
FROM
    FirstAuthors FA
JOIN
    A3Conference.Person P ON FA.AuthorID = P.PersonID
JOIN
    A3Conference.Conference C ON FA.ConferenceID = C.ConferenceID;
