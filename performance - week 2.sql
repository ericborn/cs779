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

-- Created an indexed view to work around the concat and substring functions.
-- Rewrote the query with explicit joins.
CREATE OR ALTER VIEW dbo.director_view
WITH SCHEMABINDING
AS
SELECT d.DVDTitle AS 'DVD_Title',  
	   CONCAT(SUBSTRING(mp.PersonFirstName,1,10), ' ',
	   SUBSTRING(mp.PersonLastName,1,10)) AS 'Director_Name'
FROM dbo.DVD d
INNER JOIN dbo.MoviePersonRole mpr ON d.DVDId = mpr.DVDId
INNER JOIN dbo.Role r ON mpr.RoleId = r.RoleId
INNER JOIN dbo.MoviePerson mp ON mp.PersonId = mpr.PersonId
WHERE r.RoleName = 'Director'
AND ((mp.PersonLastName = 'Spielberg') 
  OR (mp.PersonLastName = 'Hitchcock' 
AND mp.PersonFirstName = 'Alfred'));

SET STATISTICS IO ON
GO
SELECT * FROM director_view;
GO

-- Added indexes on dvd title and director name columns
CREATE UNIQUE CLUSTERED INDEX UCIDX_DVDID ON director_view(DVD_Title)
CREATE NONCLUSTERED INDEX UCIDX_director_name ON director_view(Director_Name)

SELECT * FROM director_view WITH(NOEXPAND);

-- 2.
