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
SET STATISTICS IO ON
SET STATISTICS TIME ON

-- old query with NOT IN
SELECT DVDTitle AS 'DVD Title'
FROM DVD 
WHERE DVDId NOT IN 
	 (SELECT DISTINCT DVDId FROM Rental WHERE MemberId = 123);

-- new query using NOT EXISTS
SELECT DVDTitle AS 'DVD Title'
FROM DVD 
WHERE NOT EXISTS 
	 (SELECT DISTINCT DVDId FROM Rental WHERE MemberId = 123);

-- 3.
-- Suggested an index on DVDId in the Rental table
SELECT DVDId, DVDTitle AS 'DVD Title'
FROM DVD
WHERE DVDId IN (SELECT DVDId FROM Rental 
				WHERE RentalReturnedDate IS NULL);

SELECT DVDId, DVDTitle AS 'DVD Title'
FROM DVD
WHERE EXISTS (SELECT DVDId FROM Rental 
				WHERE RentalReturnedDate IS NULL);

-- 4.
SELECT  CONCAT(SUBSTRING(m.MemberFirstName,1,10),
		SUBSTRING(m.MemberLastName,1,10)) AS 'Name',
		SUBSTRING(m.MemberAddress,1,30) AS 'Address', 
		SUBSTRING(c.CityName,1,12) AS 'City',
		SUBSTRING(s.StateName,1,12) AS 'State',
		z.ZipCode AS 'Zip'
FROM Member m
INNER JOIN ZipCode z ON z.ZipCodeId = m.MemberAddressId
INNER JOIN City c ON c.CityId = z.CityId
INNER JOIN State s ON s.StateId = z.StateId  
WHERE m.MemberFirstName = 'Yong'
AND m.MemberLastName = 'Lee' 
AND m.MemberAddressId = z.ZipCodeId
AND z.CityId = c.CityId
AND z.StateId = s.StateId;

-- 5.
SELECT DISTINCT DVD.DVDId, DVD.DVDTitle, Genre.GenreName 
FROM Rental, DVD, Genre
WHERE MemberId = 
(SELECT MemberId FROM Member
WHERE MemberFirstName = 'Alfred'
AND MemberLastName = 'Newman')
	AND Rental.DVDId = DVD.DVDId
AND DVD.GenreId = Genre.GenreId
	AND Genre.GenreName = 'Horror';

SELECT DISTINCT d.DVDId, d.DVDTitle, g.GenreName 
FROM Rental r
INNER JOIN Member m ON r.MemberId = m.MemberId
INNER JOIN dvd d ON d.DVDId = r.DVDId
INNER JOIN genre g ON g.GenreId = d.GenreId
WHERE m.MemberFirstName = 'Alfred'
  AND m.MemberLastName = 'Newman' 
  AND g.GenreName = 'Horror';

-- 6.
-- Original
CREATE OR ALTER VIEW DVDView AS
SELECT DVDId, DVDTitle, Genre.GenreName AS Genre, 
	Rating.RatingName AS Rating
FROM DVD, Genre, Rating 
WHERE DVD.GenreId = Genre.GenreId
AND DVD.RatingId = Rating.RatingId;

SELECT * FROM DVDView WHERE Genre = 'Horror' AND Rating = 'R';

-- Updated
-- Created an indexed view to work around the joins
-- Rewrote the query with explicit joins.
CREATE OR ALTER VIEW dbo.DVDView
WITH SCHEMABINDING
AS
SELECT DVDId, DVDTitle, g.GenreName AS Genre, r.RatingName AS Rating
FROM dbo.DVD d
JOIN dbo.Genre g ON d.GenreId = g.GenreId
JOIN dbo.Rating r ON r.RatingId = d.RatingId

-- Added indexes on dvd title and director name columns
CREATE UNIQUE CLUSTERED INDEX UCIDX_DVDID ON DVDView(DVDId)
CREATE NONCLUSTERED INDEX UCIDX_genre ON DVDView(Genre)

SELECT * FROM DVDView WITH(NOEXPAND) WHERE Genre = 'Horror' AND Rating = 'R';

-- 7.
-- Created a way to dynamically find the highest current id and start the sequence from there
-- Replace the count(*) with a sequence
--SELECT COUNT(*)+1 FROM Payment

-- create a variable to store the max payment id 
DECLARE @payid INT = 0;

-- Find the highest payment Id then add 1
SET @payid = (SELECT MAX(paymentid)+1 FROM Payment);

-- Create a variable to store the SQL command to create the sequence
DECLARE @sql NVARCHAR(MAX)

-- Creates a sequence which will be used to increment the Payment table
SET @sql = 'CREATE SEQUENCE dbo.PaymentId_Seq
AS [BIGINT]
START WITH ' + CONVERT(NVARCHAR(10), @payid) +
'INCREMENT BY 1'
EXEC(@sql)