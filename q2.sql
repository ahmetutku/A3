SELECT
    p.PersonID,
    p.FullName,
    COUNT(DISTINCT a.ConferenceID) AS ConferencesAttended
FROM
    A3Conference.Person p
JOIN
    A3Conference.Attendee a ON p.PersonID = a.PersonID
GROUP BY
    p.PersonID, p.FullName
ORDER BY
    ConferencesAttended DESC, p.FullName;
