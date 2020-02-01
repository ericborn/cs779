USE NetFlix

-- 1. Adding and populating columns, SQL string operators

-- a. Select all data from the memebership table to see the columns
SELECT * FROM membership;

-- Select with all columns specified
SELECT MembershipId, MembershipType, MembershipLimitPerMonth, 
MembershipMonthlyPrice, MembershipMonthlyTax, MembershipDVDLostPrice
FROM membership;

-- b. Add an attribute called DVDAtTime to the membership table
ALTER TABLE membership
ADD DVDAtTime SMALLINT;

-- c. Updates the rows with the appropriate value for DVDAtTime
-- Uses a left select 1 to get the first character from the MembershipType column
-- joins membership back on itself on the MembershipId column to ensure it updates the correct record
UPDATE membership
SET DVDAtTime = (SELECT LEFT(MembershipType,1) 
				 FROM membership m2
				 WHERE membership.MembershipId = m2.MembershipId
				);

-- d.	Select all data from the membership table to verify that you obtained the intended results.
SELECT MembershipId, MembershipType, MembershipLimitPerMonth, MembershipMonthlyPrice, 
	   MembershipMonthlyTax, MembershipDVDLostPrice, DVDAtTime
FROM membership;

--2. Sequences
-- View the rental table
SELECT * FROM rental;

-- a.	Implement a single sequence 
-- Starting the sequence at 11 since there are already 10 records inside the rental table
CREATE SEQUENCE RentalId_Seq
AS INT
START WITH 11
INCREMENT BY 1;

-- c.	Demonstrate sequence by inserting two new records into the rental table.
-- calls next value for from the RentalID_Seq sequence as the RentalId column of the rental table
INSERT INTO rental (RentalId, MemberId, DVDId, RentalRequestDate, RentalShippedDate, RentalReturnedDate)
VALUES (NEXT VALUE FOR dbo.RentalId_Seq, 9, 3, GETDATE(), NULL, NULL),
	   (NEXT VALUE FOR dbo.RentalId_Seq, 8, 4, GETDATE(), NULL, NULL);

-- 3.	Schema augmentation, nullability, CHECK

-- View memeber and dvd tables
SELECT * FROM Member;
SELECT * FROM DVD;

-- Creates a sequence which will be used to increment the DVD review Id
CREATE SEQUENCE DVDReviewId_Seq
AS INT
START WITH 1
INCREMENT BY 1;

-- Creates the DVDReview table
-- a. MemberId is a foreign key which references MemberId from the member table
-- a. DVDId is a foreign key which references DVDId from the DVD table
-- b. Table has the StarValue column which is NOT NULL
-- c. review date defaults to the current date/time and cannot be null
-- d. Comment column is optional and allows variable character lengths up to 500
-- e. StarValue is using a check to ensure its a value between 0 and 5
-- f. Uses DVDReviewId_Seq to increment the ReviewId column
CREATE TABLE DVDReview (
	ReviewId NUMERIC(16) DEFAULT (NEXT VALUE FOR DVDReviewId_Seq) NOT NULL,
	MemberId NUMERIC(12) NOT NULL,
	DVDId NUMERIC(16) NOT NULL,
	StarValue INT CHECK (StarValue >= 0 AND StarValue <= 5) NOT NULL,
	ReviewDate DATETIME DEFAULT GETDATE() NOT NULL,
	Comment VARCHAR(500) NULL
	CONSTRAINT DVDReview_ReviewId_PK PRIMARY KEY (ReviewId),
	CONSTRAINT DVDReview_MemberId_FK FOREIGN KEY (MemberId) REFERENCES Member(MemberId),
	CONSTRAINT DVDReview_DVDId_FK FOREIGN KEY (DVDId) REFERENCES DVD(DVDId)
);

--  4.	Testing schema augmentation, DBMS date function, view, code reuse
-- Ensure the table is empty
SELECT * FROM DVDReview;

-- a.	Insert three records into the DVDREVIEW
INSERT INTO DVDReview(MemberId, DVDId, StarValue, ReviewDate, Comment)
VALUES (6, 1, 5, '2018-06-24','Groundhog Day is a Bill Murray classic!'),
	   (10, 7, 2, GETDATE(), 'Very average even for a Bond film.'),
	   (2, 2, 1, '2015-02-11', 'I''d rather see Tom back on the island.');

-- b.	Write a view that returns the following columns: 
--		a concatenated Member Name containing the Member’s First and Last Name, 
--		the Title of the DVD, and the Member’s Review including STARVALUE, REVIEWDATE and Comment

-- Use concat to combine the members first and last name. Extra empty string included to give the names a space
-- Joins the DVDReview, Member and DVD tables using table abbreviation
CREATE VIEW review_view AS
SELECT CONCAT(m.MemberFirstName, ' ', m.MemberLastName) AS 'Member Name', d.DVDTitle, dr.StarValue, dr.ReviewDate, dr.Comment
FROM DVDReview dr
INNER JOIN Member m ON m.MemberId = dr.MemberId
INNER JOIN DVD d ON d.DVDId = dr.DVDId;

SELECT *
FROM review_view
WHERE DVDTitle = 'Groundhog Day'

-- c.	Write an insert statement that tries to insert a review that violates the STARVALUE check constraint.
-- Statement fails due to the star value being 10
INSERT INTO DVDReview(MemberId, DVDId, StarValue, ReviewDate, Comment)
VALUES (3, 5, 10, '2013-11-17','10 STARS BECAUSE IT WAS THAT GOOD!!!!!!!');

-- d. Updates a review for member 2 on dvd 2 to a star value of 5
UPDATE DVDReview
SET StarValue = 5
WHERE MemberId = 2 AND DVDId = 2;

-- e. Deletes a row based on member id 10 and dvd id 7 to ensure its the correct record.
DELETE FROM DVDReview
WHERE DVDReview.MemberId = 10 AND DVDId = 7;

-- !!!!!!!!TODO!!!!!!!!!!!
-- COMPLETE QUESTION 5

-- 5.	Schema extension
SELECT * FROM DVD
SELECT * FROM rental
WHERE RentalReturnedDate IS NULL
ORDER BY DVDCopyId


--DROP TABLE DVD_Copy
--DROP SEQUENCE DVDCopyId_Seq

-- Creates a sequence which will be used to increment the DVD_Copy table
CREATE SEQUENCE DVDCopyId_Seq
AS INT
START WITH 1
INCREMENT BY 1;

-- DVD_Copy contains a unique ID for each dvd the store owns, even if they own multiples of the same movie.
-- This is incremented by the sequence DVDCopyId_Seq
CREATE TABLE DVD_Copy (
	DVDCopyId NUMERIC(16) DEFAULT (NEXT VALUE FOR DVDCopyId_Seq) NOT NULL,
	DVDId NUMERIC(16) NOT NULL,
	DVDQtyOnHand BIT DEFAULT 0,
	DVDQtyOnRent BIT DEFAULT 0,
	DVDQtyLost BIT DEFAULT 0,
	CONSTRAINT DVD_Copy_PK PRIMARY KEY (DVDCopyId)
);


-- Purpose of this while loop is to populate the dvd_copy table with a record for each dvd the store owns
-- Setup variables to store a counter and total number of records within the dvd table
DECLARE @cnt INT = 1;
DECLARE @total INT = (
SELECT COUNT(*) AS 'total' FROM DVD);

-- While loop that iterates from 1 to the total number of rows in the dvd table
WHILE @cnt <= @total 
BEGIN
	-- setup new variables used to track the total sum of the 
	-- DVDQuantityOnHand, DQuantityOnRent and DVDLostQuantity
	-- columns from the dvd table. Uses @cnt to iterate one row at a time
	-- calculating the sum
	DECLARE @rowCnt INT = 1;
	DECLARE @dvdTotal INT = (
	SELECT SUM(DVDQuantityOnHand + DVDQuantityOnRent + DVDLostQuantity) AS 'dvd total'
	FROM DVD
	WHERE DVDId = @cnt);
	
	-- second loop that actually performs the insert into dvd_copy based on how many
	-- copies the dvd store owns
	WHILE @rowCnt < @dvdTotal + 1
		BEGIN
			INSERT INTO DVD_Copy (DVDCopyId, DVDId)
			VALUES (NEXT VALUE FOR dbo.DVDCopyId_Seq, @cnt)
		SET @rowCnt = @rowCnt + 1;
		END;
	--print @cnt
	SET @cnt = @cnt + 1;
END;

-- Drops the quantity columns since they've been moved to DVD_copy
ALTER TABLE DVD
DROP COLUMN DVDQuantityOnHand, DVDQuantityOnRent, DVDLostQuantity;

-- Drops the foreign key from rental to dvd
ALTER TABLE Rental
DROP CONSTRAINT Rental_DVDId_FK;

-- rename DVDId to DVDCopyId
EXEC sp_rename 'Rental.DVDId', 'DVDCopyId';

-- creates a FK constraint from rental to dvd_copy
ALTER TABLE Rental
ADD CONSTRAINT Rental_DVDCopyId_FK
FOREIGN KEY (DVDCopyId) REFERENCES DVD_Copy(DVDCopyId);

-- Update DVD's that are shipped but have no return date from the rental table
UPDATE DVD_Copy
SET DVDQtyOnRent = 1
WHERE DVDCopyId IN (11, 12, 31, 32, 41);

-- Update rental table DVDCopyId to match new ID's from the DVD_Copy table
UPDATE Rental
SET DVDCopyId = 11
WHERE RentalId = 7 AND MemberId = 9;

UPDATE Rental
SET DVDCopyId = 12
WHERE RentalId = 8 AND MemberId = 8;

UPDATE Rental
SET DVDCopyId = 31
WHERE RentalId = 4 AND MemberId = 5;

UPDATE Rental
SET DVDCopyId = 32
WHERE RentalId = 9 AND MemberId = 1;

UPDATE Rental
SET DVDCopyId = 41
WHERE RentalId = 5 AND MemberId = 5;

UPDATE Rental
SET DVDCopyId = 52
WHERE RentalId = 10 AND MemberId = 15;

--SELECT * FROM DVD_Copy
--SELECT * FROM DVD
--SELECT * FROM Rental ORDER BY DVDCopyId

-- Part 2 - Joins and Subqueries 
-- 6. Select all dramas
SELECT d.DVDTitle, g.GenreName, rat.RatingName, CONCAT(mp.PersonFirstName, ' ', mp.PersonLastName) AS 'Movie Person', r.RoleName
FROM DVD D
INNER JOIN Genre g ON g.GenreId = d.GenreId
INNER JOIN Rating rat ON rat.RatingId = d.RatingId
INNER JOIN MoviePersonRole mpr ON mpr.DVDId = d.DVDId
INNER JOIN MoviePerson mp ON mp.PersonId = mpr.PersonId
INNER JOIN role r ON r.RoleId = mpr.RoleId
WHERE g.GenreName = 'Drama'
ORDER BY d.DVDTitle;

-- 7. IS NULL, composite restrictions, subqueries
-- Subquery to find only rentals with no return date and a shipped date
-- Where clause to include only directors
SELECT CONCAT(m.MemberFirstName, ' ', m.memberLastName) AS 'Members name', d.DVDTitle, 
g.GenreName, rat.RatingName, CONCAT(mp.PersonFirstName, ' ', mp.PersonLastName) AS 'Director Name',
r.DVDCopyId, r.RentalRequestDate, r.RentalShippedDate
FROM Rental r
INNER JOIN Member m ON m.MemberId = r.MemberId
INNER JOIN DVD_Copy dc ON dc.DVDCopyId = r.DVDCopyId
INNER JOIN DVD d ON d.DVDId = dc.DVDId
INNER JOIN Genre g ON g.GenreId = d.GenreId
INNER JOIN Rating rat ON rat.RatingId = d.RatingId
INNER JOIN MoviePersonRole mpr ON mpr.DVDId = d.DVDId
INNER JOIN MoviePerson mp ON mp.PersonId = mpr.PersonId
INNER JOIN role ro ON ro.RoleId = mpr.RoleId 
WHERE r.RentalId IN (SELECT RentalId FROM Rental WHERE RentalReturnedDate IS NULL AND RentalShippedDate IS NOT NULL)
AND ro.RoleName = 'Director'
ORDER BY DVDTitle;

-- 8.
-- !!! ISNT RETURNING A SINGLE ROW PER MEMBER!!!
-- Note is to consider using top 1
SELECT CONCAT(m.MemberFirstName, ' ', m.memberLastName) AS 'Members name', d.DVDTitle,
g.GenreName, rat.RatingName, r.DVDCopyId, RentalShippedDate
FROM Rental r
INNER JOIN Member m ON m.MemberId = r.MemberId
INNER JOIN DVD_Copy dc ON dc.DVDCopyId = r.DVDCopyId
INNER JOIN DVD d ON d.DVDId = dc.DVDId
INNER JOIN Genre g ON g.GenreId = d.GenreId
INNER JOIN Rating rat ON rat.RatingId = d.RatingId
WHERE r.RentalShippedDate IN (SELECT MAX(RentalShippedDate) FROM Rental GROUP BY MemberId);

-- Part 3
-- 9. aggregates, joins, GROUP BY
SELECT d.DVDTitle, g.GenreName, rat.RatingName, COUNT(d.DVDId) AS 'Rental Count'
FROM Rental r
INNER JOIN DVD_Copy dc ON dc.DVDCopyId = r.DVDCopyId
INNER JOIN DVD d ON d.DVDId = dc.DVDId
INNER JOIN Genre g ON g.GenreId = d.GenreId
INNER JOIN Rating rat ON rat.RatingId = d.RatingId
GROUP BY d.DVDTitle, g.GenreName, rat.RatingName, d.DVDId;

-- 10. aggregates, date differences, grouping
-- Updates to the rental table with fake dvd return dates
UPDATE rental
SET RentalReturnedDate = GETDATE()
WHERE RentalId = 4;

UPDATE rental
SET RentalReturnedDate = '20191031'
WHERE RentalId = 5;

UPDATE rental
SET RentalReturnedDate = '20190315'
WHERE RentalId = 7;

UPDATE rental
SET RentalReturnedDate = '20190401'
WHERE RentalId = 8;

UPDATE rental
SET RentalReturnedDate = '20190225'
WHERE RentalId = 9;

-- use average on datediff between shipped and returned date to find the average rental days
SELECT d.DVDId, d.DVDTitle, g.GenreName, rat.RatingName, AVG(DATEDIFF(DAY, RentalShippedDate, RentalReturnedDate)) AS 'Avg Rental days'
FROM rental r
INNER JOIN DVD_Copy dc ON dc.DVDCopyId = r.DVDCopyId
INNER JOIN DVD d ON d.DVDId = dc.DVDId
INNER JOIN Genre g ON g.GenreId = d.GenreId
INNER JOIN Rating rat ON rat.RatingId = d.RatingId
WHERE RentalReturnedDate IS NOT NULL
GROUP BY d.DVDId, d.DVDTitle, g.GenreName, rat.RatingName;

-- 11. Aggregates, TOP, Filtering within Having clause, CTE/Subquery
WITH cte_rental_counts AS (
SELECT g.GenreName, COUNT(d.DVDId) AS 'Rental_Count'
FROM rental r
INNER JOIN DVD_Copy dc ON dc.DVDCopyId = r.DVDCopyId
INNER JOIN DVD d ON d.DVDId = dc.DVDId
INNER JOIN Genre g ON g.GenreId = d.GenreId
WHERE RentalShippedDate >= DATEADD(YEAR, -5,GETDATE())
GROUP BY g.GenreName, d.DVDId
)
SELECT TOP 3 GenreName, Rental_Count
FROM cte_rental_counts;

-- 12. RANK, GROUP BY
SELECT ms.MembershipType, COUNT(m.MemberId) AS 'Count', 
RANK() OVER(ORDER BY ms.MembershipType) AS Rank,
DENSE_RANK() OVER(ORDER BY ms.MembershipType) AS 'Dense_Rank'
FROM Membership ms
JOIN Member m ON ms.MembershipId = m.MembershipId
JOIN rental r ON r.MemberId = m.MemberId
GROUP BY ms.MembershipType

SELECT ms.MembershipType, COUNT(r.MemberId) AS 'Count', 
RANK() OVER(ORDER BY ms.MembershipType) AS Rank,
DENSE_RANK() OVER(ORDER BY ms.MembershipType) AS 'Dense_Rank'
FROM Membership ms
JOIN Member m ON ms.MembershipId = m.MembershipId
JOIN rental r ON r.MemberId = m.MemberId
WHERE r.RentalShippedDate IS NOT NULL
GROUP BY ms.MembershipType

SELECT memberid, count(memberid)
FROM rental
WHERE RentalShippedDate IS NOT NULL
group by memberid