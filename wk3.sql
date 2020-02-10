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
ALTER TABLE member
ADD Balance INT;

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
			JOIN RentalQueue r ON r.DVDId = dc.DVDId
			WHERE dc.DVDQtyOnHand = 1 AND r.QueuePosition = (SELECT MIN(QueuePosition) FROM RentalQueue)
		END

	-- If members balance is negative throw an error and stop
	ELSE
		BEGIN
			RAISERROR('Error, you currently have an outstanding balance.',12,1,@queue_maxPlus);
		END;


SELECT * --DVDId 
FROM RentalQueue
WHERE MemberId = 1

SELECT * FROM DVD_Copy

UPDATE DVD_Copy
SET DVDQtyOnHand = 1
WHERE DVDCopyId = 23


SELECT * --DVDId 
FROM RentalQueue
WHERE MemberId = 1