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