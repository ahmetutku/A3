SELECT
    P.PersonID,
    P.FullName,
    COUNT(DISTINCT A.ConferenceID) AS ConferencesAttended
FROM
    A3Conference.Person P
JOIN
    A3Conference.Attendee A ON P.PersonID = A.PersonID
JOIN
    A3Conference.Conference C ON A.ConferenceID = C.ConferenceID
GROUP BY
    P.PersonID,
    P.FullName
ORDER BY
    ConferencesAttended DESC, P.FullName;
