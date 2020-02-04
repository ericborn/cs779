-- Assignment 2, Part B
-- 1.
-- Original query
SELECT DVD.DVDTitle AS "DVD Title",  
		CONCAT(SUBSTRING(MoviePerson.PersonFirstName,1,10), ' ',
		SUBSTRING(MoviePerson.PersonLastName,1,10)) AS 'Director Name'
FROM DVD, MoviePersonRole, Role, MoviePerson
WHERE DVD.DVDId = MoviePersonRole.DVDId
		AND MoviePersonRole.RoleId = Role.RoleId
		AND MoviePersonRole.PersonId = MoviePerson.PersonId
		AND Role.RoleName = 'Director'
		AND ((MoviePerson.PersonLastName = 'Spielberg') 
		     OR (MoviePerson.PersonLastName = 'Hitchcock' 
		AND MoviePerson.PersonFirstName = 'Alfred'));

-- Rewrote with explicit joins
SELECT d.DVDTitle AS "DVD Title",  
		CONCAT(SUBSTRING(mp.PersonFirstName,1,10), ' ',
		SUBSTRING(mp.PersonLastName,1,10)) AS 'Director Name'
FROM DVD d
INNER JOIN MoviePersonRole mpr ON d.DVDId = mpr.DVDId
INNER JOIN Role r ON mpr.RoleId = r.RoleId
INNER JOIN MoviePerson mp ON mp.PersonId = mpr.PersonId
WHERE r.RoleName = 'Director'
AND ((mp.PersonLastName = 'Spielberg') 
  OR (mp.PersonLastName = 'Hitchcock' 
AND mp.PersonFirstName = 'Alfred'));

