SET SEARCH_PATH TO A3Conference;
DROP TABLE IF EXISTS q2 cascade;

SELECT p.PersonID, p.FullName, COALESCE(COUNT(DISTINCT a.ConferenceID), 0) AS ConferencesAttended
FROM Person p
LEFT JOIN Attendee a ON p.PersonID = a.PersonID
GROUP BY p.PersonID, p.FullName;
