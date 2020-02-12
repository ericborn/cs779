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

-- Add balance column to the member table
--ALTER TABLE member
--ADD Balance INT;

-- update member 1 with a negative balance
UPDATE member
SET Balance = -25
WHERE MemberId = 1;

SELECT * FROM Member;

CREATE FUNCTION GetNextDVD (
	@MemberId NUMERIC(12,0)
)
RETURNS NUMERIC(12,0)
AS
BEGIN
	-- Check for a balance greater than or equal to 0
	IF (SELECT Balance FROM member WHERE MemberId = @MemberId) >= 0
		BEGIN
			-- Needs to find the lowest queued dvd that is also on hand = 1
			SELECT TOP 1 dc.DVDId
			FROM DVD_Copy dc
			INNER JOIN RentalQueue r ON r.DVDId = dc.DVDId
			WHERE dc.DVDQtyOnHand = 1 AND r.QueuePosition = (SELECT MIN(QueuePosition) FROM RentalQueue)
		END

	-- If members balance is negative throw an error and stop
	ELSE
		BEGIN
			RAISERROR('Error, you currently have an outstanding balance.',12,1,@queue_maxPlus);
		END;


-- working
WITH cte_queue_item AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY QueuePosition) AS row_num, 
		dc.DVDCopyId, QueuePosition
FROM DVD_Copy dc
INNER JOIN RentalQueue r ON r.DVDId = dc.DVDId
WHERE r.MemberId = 1 AND dc.DVDOnHand = 1
) SELECT DISTINCT DVDCopyId, QueuePosition
FROM cte_queue_item
WHERE row_num = 1


SELECT * FROM DVD_Copy

UPDATE DVD_Copy
SET DVDQtyOnHand = 1
WHERE DVDCopyId = 32


SELECT * --DVDId 
FROM RentalQueue
WHERE MemberId = 1


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
-- Create a trigger that wont allow a new rental row if the member has reached
-- their maximum current or monthly DVD's
CREATE TRIGGER Trig_Rental_Check_before_ship
ON dbo.Rental
INSTEAD OF INSERT
AS
DECLARE @MemberId NUMERIC(12,0),
		@DVDRemaining SMALLINT

SELECT @MemberId = ins.MemberId FROM INSERTED ins;
SELECT @DVDRemaining = (SELECT dbo.CountDVDLimits(@MemberId));
IF @DVDRemaining <= 0
	BEGIN
		RAISERROR('Member cannot rent another DVD at this time', 11,1)
	END;

-- Test should fail since member 2 has already rented 4 dvd's this month
-- Populate Rental with a row for member 2
INSERT INTO Rental(RentalId, MemberId, DVDCopyId, RentalRequestDate)
VALUES (NEXT VALUE FOR dbo.RentalId_Seq, 2, 1, GETDATE());