/*
Eric Born
CS779
8 Feb 2020
Homework wk. 3
*/

-- 1.
-- Function that returns DVDId of the next in stock movie from the customers queue
-- Takes customer ID as an input and returns the DVDId
-- Returns NULL if there is no DVD's in stock or the queue is empty
-- Performs error checking that the customers balance isnt negative
CREATE OR ALTER FUNCTION GetNextDVD (
	@MemberId NUMERIC(12,0)
)
RETURNS NUMERIC(16,0)
AS
BEGIN
DECLARE @NextDVD SMALLINT,
		@Balance SMALLINT

SELECT @Balance = (SELECT Balance FROM member WHERE MemberId = @MemberId);

SELECT @NextDVD =
	-- Selects DVDCopyId where row number is 1
	(SELECT DVDCopyId
	 FROM
	(
		-- Finds the row number, dvdCopyId and queue position where the dvd is on hand and in the members queue
		SELECT ROW_NUMBER() OVER (ORDER BY QueuePosition) AS row_num, dc.DVDCopyId
		FROM DVD_Copy dc
		INNER JOIN RentalQueue r ON r.DVDId = dc.DVDId
		WHERE r.MemberId = @MemberId AND dc.DVDOnHand = 1
	) AS tbl
	WHERE row_num = 1)

	-- Returns @NextDVD if the members balance is greater than or equal to 0
	-- No way to use RAISERROR within a function, so I used a case the checks if the balance is greater than or equal to 0
	-- It throws a conversion error since the return is expecting a SMALLINT from @Balance
	RETURN (
		CASE
			WHEN @Balance >= 0 THEN @NextDVD
			ELSE 'Error, you currently have an outstanding balance.'
		END
		);
END;

-- Error handling testing
-- Add balance column to the member table
ALTER TABLE member
ADD Balance INT;

-- update member 1 with a negative balance
UPDATE member
SET Balance = -25
WHERE MemberId = 1;

-- verify balance is negative for member 1
SELECT MemberId, Balance
FROM Member
WHERE MemberId = 1

-- run the next dvd function
SELECT dbo.GetNextDVD(1) AS 'Next DVD';

-- Populate RentalQueue with test data for member 2
INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
VALUES (2, 1, GETDATE(), 1),
	   (2, 2, GETDATE(), 2),
	   (2, 3, GETDATE(), 3)

-- check member 2's rental queue
SELECT *
FROM RentalQueue
WHERE MemberId = 2

-- check GetNextDVD function for member 2
SELECT dbo.GetNextDVD(2) AS 'Next DVD';

-- check dvd's on hand
SELECT * 
FROM DVD_Copy
WHERE DVDOnHand = 1

-- Populate RentalQueue with test data for member 3
INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
VALUES (3, 8, GETDATE(), 1),
	   (3, 3, GETDATE(), 2),
	   (3, 5, GETDATE(), 3)

-- check member 3's rental queue
SELECT *
FROM RentalQueue
WHERE MemberId = 3
ORDER BY QueuePosition

-- check GetNextDVD function for member 3
SELECT dbo.GetNextDVD(3) AS 'Next DVD';

-- check dvd's on hand
SELECT * 
FROM DVD_Copy
WHERE DVDOnHand = 1

-- check member 4's rental queue
SELECT *
FROM RentalQueue
WHERE MemberId = 4

-- check GetNextDVD function for member 4
SELECT dbo.GetNextDVD(4) AS 'Next DVD';

-- Populate RentalQueue with test data for member 5
INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
VALUES (5, 1, GETDATE(), 1),
	   (5, 2, GETDATE(), 2)

-- check member 5's rental queue
SELECT *
FROM RentalQueue
WHERE MemberId = 5

-- check GetNextDVD function for member 5
SELECT dbo.GetNextDVD(5) AS 'Next DVD';

-- 2.
-- Take the customer ID as an IN parameter, return the number of DVDs the customer can rent before they reach the limits of their contract
CREATE OR ALTER FUNCTION CountDVDLimits (
	@MemberId NUMERIC(12,0)
)
RETURNS NUMERIC(12,0)
AS
BEGIN
	DECLARE @currentRented SMALLINT,
			@TotalRented SMALLINT,
			@MaxPerMonth SMALLINT,
			@MaxAtTime SMALLINT
			--,@MemberId NUMERIC(12,0)

	--SELECT @MemberId = 1

	 -- First find the maximum DVD's a customer can have at a time
	 -- Subtract that from a count of DVD's that have a shipped timestamp, but no return timestamp
	 -- This will find movies shipped during a previous month that have still not been returned
	 SET @MaxAtTime = 
	 (SELECT ms.DVDAtTime 
	 FROM Member m
	 JOIN Membership ms ON ms.MembershipId = m.MembershipId
	 WHERE m.MemberId = @MemberId) -
	 (SELECT COUNT(*)
	 FROM Rental
	 WHERE MemberId = @MemberId AND RentalShippedDate IS NOT NULL AND RentalReturnedDate IS NULL)

	-- Finds maximum number of DVD's per month then subtracts that from a
	-- count of the total number of DVDs that were shipped to a 
	-- customer between the first and last day of the month
	SET @MaxPerMonth = 
	(SELECT ms.MembershipLimitPerMonth
	 FROM Member m
	 JOIN Membership ms ON ms.MembershipId = m.MembershipId
	 WHERE m.MemberId = @MemberId) -
	-- Dynamically finds first and last day of month then checks for rental shipped date between the two
	(SELECT COUNT(*)
	 FROM Rental
	 WHERE MemberId = @MemberId AND RentalShippedDate BETWEEN 
	(SELECT CONVERT(DATE, DATEADD(d, 1,DATEADD(d,-DAY(DATEADD(m,1,GETDATE())),GETDATE())),112)) AND EOMONTH(GETDATE()))

	-- Returns whichever value is lower
	RETURN (
		CASE
			WHEN @MaxAtTime < @MaxPerMonth THEN @MaxAtTime
			ELSE @MaxPerMonth
		END
		);
END;

-- Used for testing
-- Populate Rental with test data
--INSERT INTO Rental(RentalId, MemberId, DVDCopyId, RentalRequestDate)
--VALUES (NEXT VALUE FOR dbo.RentalId_Seq, 2, 1, GETDATE()),
--	   (NEXT VALUE FOR dbo.RentalId_Seq, 2, 13, GETDATE()),
--	   (NEXT VALUE FOR dbo.RentalId_Seq, 2, 29, GETDATE()),
--	   (NEXT VALUE FOR dbo.RentalId_Seq, 2, 37, GETDATE()),
--	   (NEXT VALUE FOR dbo.RentalId_Seq, 2, 43, GETDATE()),
--	   (NEXT VALUE FOR dbo.RentalId_Seq, 2, 41, GETDATE()),
--	   (NEXT VALUE FOR dbo.RentalId_Seq, 2, 57, GETDATE())

-- View rentals for a specific memberId
SELECT * 
FROM rental
WHERE memberId = 2;

-- Set movies as rented
UPDATE Rental
SET RentalShippedDate = GETDATE()
WHERE RentalID = 25;

-- Set movies as returned
UPDATE Rental
SET RentalReturnedDate = GETDATE()
WHERE RentalID = 26;

-- Used to test the function
-- member 1 is 3 at time, 99 per month
-- member 2 is 2 at time, 4 per month
-- member 3 is 2 at time, 4 per month
SELECT dbo.CountDVDLimits(2) AS 'DVDs Remaining';

-- 3.
-- Create a trigger that will not allow a new rental row if the member has reached
-- their maximum current or monthly DVD's
CREATE OR ALTER TRIGGER Trig_Rental_Check_before_ship
ON [dbo].[Rental]
INSTEAD OF INSERT
AS
BEGIN
DECLARE @MemberId NUMERIC(12,0),
		@DVDRemaining SMALLINT

-- Find the memberId and use the function CountDVDLimits to find the
-- total DVD's the member currently has rented.
SELECT @MemberId = ins.MemberId FROM INSERTED ins;
SELECT @DVDRemaining = (SELECT dbo.CountDVDLimits(@MemberId));

-- Insert into rental only if @DVDRemaining is greater than 0
INSERT INTO Rental(RentalId, MemberId, DVDCopyId, RentalRequestDate)
SELECT RentalId, MemberId, DVDCopyId, RentalRequestDate
FROM INSERTED
WHERE @DVDRemaining > 0

-- if @DVDRemaining is less than or equal to 0, throw an error
IF @DVDRemaining <= 0
	BEGIN
		RAISERROR('Member cannot rent another DVD at this time', 11,1)
	END
END;

-- Test should fail since member 2 has already rented 4 dvd's this month
-- Populate Rental with a row for member 2
INSERT INTO Rental(RentalId, MemberId, DVDCopyId, RentalRequestDate)
VALUES (NEXT VALUE FOR dbo.RentalId_Seq, 1, 1, GETDATE());

-- 4.
-- Stored proc that updates rental and dvd copy, will be used inside the next function
-- Takes memberId and the dvd copy id as inputs
-- If the DVD_Lost bit is 0 then update to put the DVDOnHand to 1 and OnRent to 0
-- If the DVD_Lost bit is 1 then update to put the DVDLost to 1,  OnRent to 0 and balance -25
CREATE OR ALTER PROCEDURE [dbo].[PROC_DVD_Return]
	@MemberId NUMERIC(12,0),
	@DVDCopyId NUMERIC(16,0),
	@DVD_Lost BIT = 0
AS
BEGIN
	IF @DVD_Lost = 0
		BEGIN
			-- Updates rental table to show the member returned a dvd
			-- Filters on memberId, DVDCopyID where the movie has been shipped but not returned
			UPDATE Rental
			SET RentalReturnedDate = GETDATE()
			WHERE MemberId = @MemberId AND DVDCopyId = @DVDCopyId 
			  AND RentalShippedDate IS NOT NULL AND RentalReturnedDate IS NULL

			-- Update DVD_Copy to show the DVD has been returned
			UPDATE DVD_Copy
			SET DVDOnHand = 1, DVDOnRent = 0
			WHERE DVDCopyId = @DVDCopyId
		END
	ELSE
		BEGIN
			-- updates member's balance with current balance minus 25 for a lost dvd
			UPDATE Member
			SET Balance = Balance - 25
			WHERE MemberId = @MemberId

			-- Updates rental table to show the member returned a dvd
			-- Filters on memberId, DVDCopyID where the movie has been shipped but not returned
			UPDATE Rental
			SET RentalReturnedDate = GETDATE()
			WHERE MemberId = @MemberId AND DVDCopyId = @DVDCopyId 
			  AND RentalShippedDate IS NOT NULL AND RentalReturnedDate IS NULL

			-- Update DVD_Copy to show the DVD was lost
			UPDATE DVD_Copy
			SET DVDLost = 1, DVDOnRent = 0
			WHERE DVDCopyId = @DVDCopyId
		END
END;

-- Created an additional stored proc to handle finding the next queue item, 
-- inserting it into the rental table, updating the quantity from on hand to rented
-- and removing it from the queue
CREATE OR ALTER PROCEDURE PROC_RENT_DVD
	@MemberId NUMERIC(12,0)
AS
	DECLARE @Next_dvd_copy_id NUMERIC(16,0),
			@Next_dvd_id NUMERIC(16,0)
			-- Test variables
	--		,@MemberId NUMERIC(12,0)

	--SELECT @MemberId = 2

	BEGIN
		-- Run the next dvd function which finds the next dvd in the members queue
		SELECT @Next_dvd_copy_id = (SELECT dbo.GetNextDVD(@MemberId));
		IF @Next_dvd_copy_id IS NOT NULL
			BEGIN
				-- Find the DVDId from the DVDCopyID
				SELECT @Next_dvd_id = (SELECT DVDId
									   FROM DVD_Copy 
									   WHERE DVDCopyId = @Next_dvd_copy_id)

				-- Insert the info into the rental table
				INSERT INTO Rental(RentalId, MemberId, DVDCopyId)
				VALUES (NEXT VALUE FOR dbo.RentalId_Seq, @MemberId, @Next_dvd_copy_id);

				-- updating rental with the original date added from the queue table and current date
				UPDATE Rental
				SET MemberId = @MemberId, DVDCopyId = @Next_dvd_copy_id, 
				RentalRequestDate = (SELECT DateAddedInQueue 
									 FROM RentalQueue rq
									 JOIN DVD d ON d.DVDId = rq.DVDId
									 WHERE MemberId = @MemberId AND rq.DVDId = @Next_dvd_id),
				RentalShippedDate = GETDATE()
				WHERE MemberId = @MemberId AND DVDCopyId = @Next_dvd_copy_id

				-- Update dvd_copy to indicate the dvd has been rented
				UPDATE DVD_Copy
				SET DVDOnHand = 0, DVDOnRent = 1, DVDLost = 0
				WHERE DVDCopyId = @Next_dvd_copy_id

				-- Delete the dvd from the rental queue
				EXEC DELETE_RENTAL_QUEUE @MemberId, @Next_dvd_id
			END
		ELSE
			BEGIN
				PRINT 'No items in your queue are currently available'
			END
	END;

-- Write a stored procedure that implements the processing when a DVD is 
-- Returned in the mail from a customer and the next DVD is sent out
-- Customer returns a DVD or notes the DVD is lost in which case they are charged against their account
-- Lost dvd is indicated by a 1 in the @Lost_DVD parameter
-- Function from question 2, CountDVDLimits, is used to set the @additional_DVD_count parameter
-- Function from question 1, GetNextDVD, is called within the PROC_RENT_DVD stored procedure
-- Stored procedure from homework wk 2, DELETE_RENTAL_QUEUE, is used in the PROC_RENT_DVD stored procedure
-- This Stored procedure will dynamically handle between 1 to 3 DVD's being returned and rented
-- DVD quantities are handled within the PROC_RENT_DVD stored procedure
CREATE OR ALTER PROCEDURE PROC_DVD_Processing
	@MemberId NUMERIC(12,0),
	@DVDCopyId_1_returned NUMERIC(16,0),
	@DVDCopyId_2_returned NUMERIC(16,0) = NULL,
	@DVDCopyId_3_returned NUMERIC(16,0) = NULL,
	@Lost_DVD_1 BIT,
    @Lost_DVD_2 BIT = NULL,
    @Lost_DVD_3 BIT = NULL
AS
BEGIN
	DECLARE @additional_DVD_count SMALLINT,
			@cnt SMALLINT = 1
			
			-- Test variables
	--		,@Next_dvd_copy_id NUMERIC(16,0),
	--		@Next_dvd_id NUMERIC(16,0),
	--		@parameterDefinition NVARCHAR(200),
	--		@statement VARCHAR(200),
	--		@MemberId NUMERIC(12,0),
	--		@DVDCopyId_1_returned NUMERIC(16,0),
	--		@DVDCopyId_2_returned NUMERIC(16,0) = NULL,
	--		@DVDCopyId_3_returned NUMERIC(16,0) = NULL,
	--		@Lost_DVD_1 BIT,
	--		@Lost_DVD_2 BIT = NULL,
	--		@Lost_DVD_3 BIT = NULL

	--SET @MemberId = 2

	--SET @DVDCopyId_1_returned = 31
	--SET @DVDCopyId_2_returned = 4
	--SET @DVDCopyId_3_returned = 12

	--SET @Lost_DVD_1 = 0
	--SET @Lost_DVD_2 = 0
	--SET @Lost_DVD_3 = 0

	-- I tried to set this up as a while loop using dynamic variable names dependent on
	-- how many dvd's were returned but couldn't get it to work.
	-- Setup as 3 individual IF statements since you cannot do elif in SQL and 
	-- CASE will not trigger an EXEC statement
	-- Checks for all 3 DVDs to not be null
	IF  @DVDCopyId_1_returned IS NOT NULL AND @DVDCopyId_2_returned IS NOT NULL
	AND @DVDCopyId_3_returned IS NOT NULL
		BEGIN
			EXEC PROC_DVD_Return @MemberId, @DVDCopyId_1_returned, @Lost_DVD_1
			EXEC PROC_DVD_Return @MemberId, @DVDCopyId_2_returned, @Lost_DVD_2
			EXEC PROC_DVD_Return @MemberId, @DVDCopyId_3_returned, @Lost_DVD_3
		END

	-- Checks DVDs 1 and 2 to not be null and 3 to be null
	IF  @DVDCopyId_1_returned IS NOT NULL AND @DVDCopyId_2_returned IS NOT NULL 
	AND @DVDCopyId_3_returned IS NULL 
		BEGIN
			EXEC PROC_DVD_Return @MemberId, @DVDCopyId_1_returned, @Lost_DVD_1
			EXEC PROC_DVD_Return @MemberId, @DVDCopyId_2_returned, @Lost_DVD_2
		END

	-- Checks for only DVD 1 to not be null and the other 2 as null
	IF  @DVDCopyId_1_returned IS NOT NULL AND @DVDCopyId_2_returned IS NULL 
	AND @DVDCopyId_3_returned IS NULL 
		BEGIN
			EXEC PROC_DVD_Return @MemberId, @DVDCopyId_1_returned, @Lost_DVD_1
		END

	-- Run the dvd count function which returns how many DVD's the memeber is elegible to rent
	SELECT @additional_DVD_count = (SELECT dbo.CountDVDLimits(@MemberId));
	PRINT @additional_DVD_count
	-- Runs a loop executing the rent dvd stored proc once for each additional DVD
	-- the member is able to rent
	IF @additional_DVD_count > 0
		BEGIN
			WHILE @cnt <= @additional_DVD_count
				BEGIN
					EXEC PROC_RENT_DVD @MemberId
					SET @cnt = @cnt + 1
				END
		END
	ELSE
		BEGIN
			PRINT 'You''re current ineligible for additional DVD''s at this time'
		END;
END

-- TESTING SETUP - MEMBER 1
UPDATE Rental
SET RentalReturnedDate = NULL
WHERE RentalId in (2,3,4)

UPDATE DVD_Copy
SET DVDOnHand = 0, DVDOnRent = 1, DVDLost = 0
WHERE DVDCopyId IN (4, 12, 31)

UPDATE Member
SET Balance = 0

DELETE FROM RentalQueue
WHERE MemberId = 1 

DELETE FROM Rental
WHERE RentalId > 4

--INSERT INTO Rental(RentalId, MemberId, DVDCopyId, RentalRequestDate, RentalShippedDate, RentalReturnedDate)
--VALUES (1, 1, 1, '20010101',  GETDATE(), GETDATE()),
--	   (2, 1, 4, '20010101',  GETDATE(), NULL),
--	   (3, 1, 12, '20010101',  GETDATE(), NULL),
--	   (4, 1, 31, '20010101',  GETDATE(), NULL)

INSERT INTO RentalQueue
VALUES (1, 8, '20200113', 1),
	   (1, 5, '20020101', 2),
	   (1, 6, '20030211', 3),
	   (1, 7, '20040505', 4),
	   (1, 3, '20180624', 5)

UPDATE DVD_Copy
SET DVDOnHand = 1, DVDOnRent = 0, DVDLost = 0
WHERE DVDCopyId IN (42, 57, 63) 

-- VIEW DATA
SELECT 'Member Table', MemberId,Balance
FROM Member WHERE MemberId = 1
SELECT 'Rental Table', * FROM Rental
WHERE MemberId = 1
SELECT 'RentalQueue Table', * FROM RentalQueue
WHERE MemberId = 1 ORDER BY QueuePosition
SELECT 'DVD_Copy Table', * FROM DVD_Copy
WHERE DVDCopyId IN (4, 12, 31, 42, 57, 63)

-- MemberId, DVDCopyID1, DVDCopyID2, DVDCopyID3, DVDLostBit1, DVDLostBit2, DVDLostBit3
-- Member 1 returning dvd 4, none lost
EXEC PROC_DVD_Processing 1, 4, NULL, NULL, 0, NULL, NULL

-- Member 1 returning dvd 4 and 31, none lost
EXEC PROC_DVD_Processing 1, 4, 31, NULL, 0, 0, NULL

-- Member 1 returning dvd 4, 12 and 31, none lost
EXEC PROC_DVD_Processing 1, 4, 31, 12, 0, 0, 0

-- Member 1 returning dvd 4 and 31, 31 was lost
EXEC PROC_DVD_Processing 1, 4, 31, NULL, 0, 1, NULL

----------------------------------------------------------------
-- TESTING SETUP - MEMBER 2

--INSERT INTO Rental(RentalId, MemberId, DVDCopyId, RentalRequestDate, RentalShippedDate, RentalReturnedDate)
--VALUES (1, 2, 1, '20010101',  GETDATE(), GETDATE()),
--	   (2, 2, 27, '20010101',  GETDATE(), GETDATE()),
--	   (3, 2, 31, '20010101',  GETDATE(), NULL),
--	   (4, 2, 65, '20010101',  GETDATE(), NULL)

UPDATE Rental
SET RentalReturnedDate = NULL
WHERE RentalId in (6,7,8)

UPDATE DVD_Copy
SET DVDOnHand = 0, DVDOnRent = 1, DVDLost = 0
WHERE DVDCopyId IN (31, 65)

UPDATE Member
SET Balance = 0

DELETE FROM RentalQueue
WHERE MemberId = 2 

DELETE FROM Rental
WHERE RentalId > 8

INSERT INTO RentalQueue
VALUES (2, 1, '20200113', 1),
	   (2, 2, '20020101', 2),
	   (2, 3, '20030211', 3)

-- VIEW DATA
SELECT 'Member Table', MemberId,Balance
FROM Member WHERE MemberId = 2
SELECT 'Rental Table', * FROM Rental
WHERE MemberId = 2
SELECT 'RentalQueue Table', * FROM RentalQueue
WHERE MemberId = 2 ORDER BY QueuePosition
SELECT 'DVD_Copy Table', * FROM DVD_Copy
WHERE DVDCopyId IN (1, 12, 27, 31, 65)

--select * from Membership

-- MemberId, DVDCopyID1, DVDCopyID2, DVDCopyID3, DVDLostBit1, DVDLostBit2, DVDLostBit3
-- Member 2 returning dvd 31, none lost
EXEC PROC_DVD_Processing 2, 31, NULL, NULL, 0, NULL, NULL