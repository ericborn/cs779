USE NetFlix

-- 1. Adding and populating columns, SQL string operators

-- a. Select all data from the memebership table
SELECT * FROM membership;

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
SELECT * FROM DVDReview

-- a.	Insert three records into the DVDREVIEW
INSERT INTO DVDReview(MemberId, DVDId, StarValue, ReviewDate, Comment)
VALUES (6, 1, 5, '2018-06-24','Groundhog Day is a Bill Murray classic!'),
	   (10, 7, 2, GETDATE(), 'Very average even for a Bond film.'),
	   (2, 2, 1, '2015-02-11', 'I''d rather see Tom back on the island.')

-- b.	Write a view that returns the following columns: 
--		a concatenated Member Name containing the Member’s First and Last Name, 
--		the Title of the DVD, and the Member’s Review including STARVALUE, REVIEWDATE and Comment

-- Use concat to combine the members first and last name. Extra empty string included to give the names a space
-- Joins the DVDReview, Member and DVD tables using table abbreviation
CREATE VIEW review_view AS
SELECT CONCAT(m.MemberFirstName, ' ', m.MemberLastName) AS 'Member Name', d.DVDTitle, dr.StarValue, dr.ReviewDate, dr.Comment
FROM DVDReview dr
JOIN Member m ON m.MemberId = dr.MemberId
JOIN DVD d ON d.DVDId = dr.DVDId;

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

-- Creates a sequence which will be used to increment the DVD_Copy table
CREATE SEQUENCE RentalDVDId_Seq
AS INT
START WITH 1
INCREMENT BY 1;

-- DVD_Copy contains a unique ID for each dvd the store owns, even if they own multiples of the same movie.
-- This is incremented by the sequence DVDCopyId_Seq
-- The MovieId column is linked as a foreign key which references a DVDId from the DVD table.
CREATE TABLE DVD_Copy (
	DVDCopyId NUMERIC(16) DEFAULT (NEXT VALUE FOR RentalDVDId_Seq) NOT NULL,
	DVDId NUMERIC(16) NOT NULL,
	CONSTRAINT DVD_Copy_PK PRIMARY KEY (DVDCopyId),
	CONSTRAINT DVD_DVDId_FK FOREIGN KEY (DVDId) REFERENCES DVD(DVDId)
);

-- Drops the foreign key from rental to dvd
ALTER TABLE Rental
DROP CONSTRAINT Rental_DVDId_FK

ALTER TABLE Rental
ADD FOREIGN KEY (DVDId) REFERENCES DVD_Copy(DVDCopyId)

SELECT * FROM DVD_Copy

-- !!!!!!!!TODO!!!!!!!!!!!
-- COMPLETE QUESTION 5


-- Part 2 - Joins and Subqueries 
-- 6. Select all dramas
SELECT d.DVDTitle, g.GenreName, rat.RatingName, CONCAT(mp.PersonFirstName, ' ', mp.PersonLastName) AS 'Movie Person', r.RoleName
FROM DVD D
JOIN Genre g ON g.GenreId = d.GenreId
JOIN Rating rat ON rat.RatingId = d.RatingId
JOIN MoviePersonRole mpr ON mpr.DVDId = d.DVDId
JOIN MoviePerson mp ON mp.PersonId = mpr.PersonId
JOIN role r ON r.RoleId = mpr.RoleId
WHERE g.GenreName = 'Drama'
ORDER BY d.DVDTitle

SELECT * FROM Member
SELECT * FROM 