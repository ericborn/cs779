/*
Eric Born
CS779
8 Feb 2020
Homework wk. 2
*/

-- 1.
-- Not used since we're doing an insert into to create the table
-- Create a rental history table
--CREATE TABLE RentalHistory (
--RentalHistoryId NUMERIC(12,0) NOT NULL,
--RentalId NUMERIC(12,0) NOT NULL,
--MemberId NUMERIC(12,0) NOT NULL,
--DVDCopyId NUMERIC(16,0) NOT NULL,
--DVDId NUMERIC(16,0) NOT NULL,
--ZipcodeId VARCHAR(5) NOT NULL,
--DVDTitle VARCHAR(100) NOT NULL,
--GenreName VARCHAR(20) NOT NULL,
--RentalRequestDate DATETIME NOT NULL,
--RentalShippedDate DATETIME NULL,
--RentalReturnedDate DATETIME NULL,
--MembershipType VARCHAR(128) NOT NULL,
--MemberSinceDate DATETIME NOT NULL,
--QueuePosition SMALLINT DEFAULT NULL
--);

-- alter statements to add genrename, ratingname and description to the DVD table
ALTER TABLE DVD
ADD GenreName VARCHAR(20),
	RatingName VARCHAR(10),
	RatingDescription VARCHAR(255);

-- set genre name within DVD
UPDATE DVD
SET GenreName = g.GenreName
FROM DVD AS d
INNER JOIN genre g ON d.GenreId = g.GenreId;

-- set RatingName and Description within DVD
UPDATE DVD
SET RatingName = r.RatingName,
	RatingDescription = r.RatingDescription
FROM DVD AS d
INNER JOIN rating r ON d.RatingId = r.RatingId;

-- Add a queue position to the rental table
ALTER TABLE rental
ADD QueuePosition SMALLINT;

--DROP SEQUENCE dbo.RentalHistory_Seq
-- Create a sequence for the rental history tables ID
CREATE SEQUENCE RentalHistory_Seq
AS NUMERIC(12,0)
START WITH 1
INCREMENT BY 1;

--DROP TABLE RentalHistory
-- Select into RentalHistory with information from each other table
SELECT
NEXT VALUE FOR dbo.RentalHistory_Seq AS 'RentalHistoryId',
r.RentalId, r.MemberId, r.DVDCopyId,
dc.DVDId, z.ZipcodeId, d.DVDTitle, d.GenreName, r.RentalRequestDate,
r.RentalShippedDate, r.RentalReturnedDate, ms.MembershipType,
m.MemberSinceDate, QueuePosition
INTO RentalHistory
FROM Rental r
JOIN DVD_Copy dc ON dc.DVDCopyId = r.DVDCopyId
JOIN DVD d ON d.DVDId = dc.DVDId
JOIN Member m ON m.MemberId = r.MemberId
JOIN Membership ms ON m.MembershipId = ms.MembershipId
JOIN ZipCode z	on z.ZipCodeId = m.MemberAddressId;

--SELECT * FROM RentalHistory

--SELECT * FROM Rental
--WHERE RentalRequestDate < '20190203'

--SELECT * FROM DVD d
--INNER JOIN rating r ON d.RatingId = r.RatingId;

-- 2. Prevent deletions from RentalHistory to prevent deletions
CREATE TRIGGER Trig_Rental_hist_delete
ON dbo.RentalHistory
INSTEAD OF DELETE
AS
BEGIN
	RAISERROR('Deletions not allowed from this table', 16,1)
END;

DELETE FROM RentalHistory
WHERE RentalHistoryId = 4

-- insert movie at beginning, middle and the end of the queue

-- 3. Trigger for updating RentalHistory table RentalShippedDate column when dvd sent to customer
CREATE TRIGGER Trig_Rental_hist_ship_update
ON dbo.Rental
FOR UPDATE
AS 
DECLARE @RentalId NUMERIC(16,0),
		@RentalShippedDate DATETIME

SELECT @RentalId = ins.RentalId FROM INSERTED ins;
SELECT @RentalShippedDate = ins.RentalShippedDate FROM INSERTED ins;

UPDATE RentalHistory
SET [RentalShippedDate] = @RentalShippedDate
WHERE [RentalId] = @RentalId
PRINT 'Updated shipped date inside of RentalHistory'
GO;

-- Shows the RentalShippedDate is NULL for rentalId 10 in both tables
SELECT  r.RentalId, r.RentalShippedDate, rh.RentalShippedDate
FROM Rental r
JOIN RentalHistory rh ON rh.RentalId = r.RentalId
WHERE r.RentalId = 10;

-- set the RentalShippedDate to the current date/time in the rental table
UPDATE RENTAL
SET RentalShippedDate = GETDATE()
WHERE RentalId = 10;

-- Shows the RentalShippedDate is filled for rentalId 10 in both tables
SELECT  r.RentalId, r.RentalShippedDate, rh.RentalShippedDate
FROM Rental r
JOIN RentalHistory rh ON rh.RentalId = r.RentalId
WHERE r.RentalId = 10;



-- 4. Trigger for updating RentalHistory table RentalReturnedDate column when dvd received back from customer
CREATE TRIGGER Trig_Rental_hist_ship_returned
ON dbo.Rental
FOR UPDATE
AS 
DECLARE @RentalId NUMERIC(16,0),
		@RentalReturnedDate DATETIME
SELECT @RentalId = ins.RentalId FROM INSERTED ins;
SELECT @RentalReturnedDate = ins.RentalReturnedDate FROM INSERTED ins;

UPDATE RentalHistory
SET [RentalReturnedDate] = @RentalReturnedDate
WHERE [RentalId] = @RentalId
PRINT 'Updated returned date inside of RentalHistory'
GO

-- Shows the RentalReturnedDate is NULL for rentalId 10 in both tables
SELECT  r.RentalId, r.RentalReturnedDate, rh.RentalReturnedDate
FROM Rental r
JOIN RentalHistory rh ON rh.RentalId = r.RentalId
WHERE r.RentalId = 10;

-- set the RentalReturnedDate to the current date/time in the rental table
UPDATE RENTAL
SET RentalReturnedDate = GETDATE()
WHERE RentalId = 10;

-- Shows the RentalReturnedDate is filled for rentalId 10 in both tables
SELECT  r.RentalId, r.RentalReturnedDate, rh.RentalReturnedDate
FROM Rental r
JOIN RentalHistory rh ON rh.RentalId = r.RentalId
WHERE r.RentalId = 10;


-- 5. 
-- Code to expand RentalQueue to include queue position
ALTER TABLE RentalQueue
ADD QueuePosition SMALLINT;