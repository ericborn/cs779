/*
Eric Born
CS779
8 Feb 2020
Homework wk. 2
*/

USE NETFLIX
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

-- Add a queue position to the rentalqueue table
ALTER TABLE RentalQueue
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
JOIN ZipCode z	on z.ZipCodeId = m.MemberAddressId
JOIN RentalQueue rq ON rq.MemberId = r.MemberId

-- 2. Prevent deletions from RentalHistory to prevent deletions
CREATE TRIGGER Trig_Rental_hist_delete
ON dbo.RentalHistory
INSTEAD OF DELETE
AS
BEGIN
	RAISERROR('Deletions not allowed from this table', 11,1)
END;

DELETE FROM RentalHistory
WHERE RentalHistoryId = 4

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
-- Create the stored proc for adding a DVD to the queue.
-- Takes MemberId, DVDId and Queue position as inputs.
-- Performs error checking on the following: 
-- Forces a queue position value of 1 for member's who do not currently have a queue
-- Queue position being less than 1 or greater than 1 higher than the current max queue position.
-- Invalid DVDId's.
-- DVDId already in the members queue.
CREATE OR ALTER PROCEDURE ADD_RENTAL_QUEUE
	@member_id NUMERIC(12,0),
	@dvd_id NUMERIC(16,0),
	@queue_position SMALLINT
AS
-- Create variables to store the highest value current in the queue and that value plus 1
DECLARE @queue_max SMALLINT,
		@queue_maxPlus SMALLINT
		
		-- Test variables
	--	,@member_id NUMERIC(12,0),
	--	 @dvd_id NUMERIC(16,0),
	--	 @queue_position SMALLINT
	
	---- Set test variables
	--SELECT @member_id = 3,
	--	   @dvd_id = 1,
	--	   @queue_position = 3

	-- Find the highest queue position
	SET @queue_max = (SELECT MAX(QueuePosition) FROM RentalQueue WHERE MemberId = @member_id)
	
	-- set @queue_maxP to max + 1 to track maximum queue values range
	SET @queue_maxPlus = @queue_max + 1

-- Check to see if member has an established queue by selecting top 1 row from
-- RentalQueue where MemberId equals @member_id
-- If they have a queue proceed to the next check
IF @member_id IN (SELECT TOP 1 MemberId FROM RentalQueue WHERE MemberId = @member_id)
	BEGIN
		-- Check to ensure the DVDId is valid
		IF @dvd_id IN (SELECT DVDId FROM DVD) 
			BEGIN
				-- If the DVDId is not currently in the rental queue for this customer proceed
				-- if it is, throw an error and stop
				IF @dvd_id NOT IN (SELECT DVDId FROM RentalQueue WHERE MemberId = @member_id)
					BEGIN
						-- If the selected queue position is greater than 0 or less than or equal to 1 
						-- greater than the highest queue value proceed with the insert. Otherwise raise an error
						IF (@queue_position > 0 AND @queue_position <= @queue_maxPlus)
							BEGIN
								--If queue position is one larger than the current highest queue item, insert without reorder
								IF @queue_position = @queue_maxPlus
									BEGIN
										INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
										VALUES (@member_id, @dvd_id, GETDATE(), @queue_position);
									END;
								-- If queue position is not the largest value, update all items in the queue
								-- from their current value to their value +1 then insert new item into the list
								ELSE
									BEGIN
										-- Reorder queue then insert
										UPDATE RentalQueue
										SET QueuePosition = QueuePosition + 1
										WHERE MemberId = @member_id AND QueuePosition >= @queue_position;
										 -- Insert new queue row
										INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
										VALUES (@member_id, @dvd_id, GETDATE(), @queue_position);
									END;
							END;
						-- If the queue position value is less than 1 or greater than +1 of their current max raise and error
						ELSE
							BEGIN
								RAISERROR('Error, please choose a queue positon between 1 and %d.',12,1,@queue_maxPlus);
							END;
					END;
				-- Raise and error for the DVD already being in the queue
				ELSE
					BEGIN
						RAISERROR('Error, please choose a DVD that is not already in your queue.',11,1);
					END;
			END;
		-- Raise an error for the DVDId being invalid
		ELSE
			BEGIN
				RAISERROR('Error, please choose a valid DVDId.',11,1);
			END;
	END;
-- If the member does not have a queue, did they choose queue position 1?
ELSE
	BEGIN
		-- If the member does not have a queue and chose position 1, insert a row
		IF @queue_position = 1
			BEGIN
				INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
				VALUES (@member_id, @dvd_id, GETDATE(), @queue_position);
			END;
		-- If they did not choose position 1 raise an error.
		ELSE
			BEGIN
				RAISERROR('Error, please choose queue position 1 since there are no other items in your queue.',11,1);
			END;
	END;

-- Test queue setup
-- Reset RentalQueue test data.
--DELETE FROM RentalQueue
--WHERE MemberId = 1;

---- Populate RentalQueue with test data
--INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
--VALUES (1, 1, GETDATE(), 1),
--	   (1, 2, GETDATE(), 2),
--	   (1, 3, GETDATE(), 3),
--	   (1, 4, GETDATE(), 4),
--	   (1, 5, GETDATE(), 5),
--	   (1, 6, GETDATE(), 6),
--	   (1, 7, GETDATE(), 7)

--SELECT * FROM RentalQueue
--WHERE MemberId = 2;

--EXEC ADD_RENTAL_QUEUE @member_id = 2, @dvd_id = 3, @queue_position = 1

--SELECT * FROM RentalQueue
--WHERE MemberId = 2
--ORDER BY QueuePosition