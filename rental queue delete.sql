/*
Eric Born
CS779
8 Feb 2020
Homework wk. 2
*/

-- 6.
-- Create the stored proc for deleting a DVD from the queue.
-- Takes MemberId and DVDId inputs.
-- Performs error checking on the following: 
-- Invalid DVDId's.
-- DVDId not in the members queue.
-- Member does not have any items in their queue
CREATE OR ALTER PROCEDURE DELETE_RENTAL_QUEUE
	@member_id NUMERIC(12,0),
	@dvd_id NUMERIC(16,0)
AS

-- initialize a variable to find where the dvd currently sits in the queue
DECLARE @queue_position SMALLINT

--		-- Test variables
--DECLARE
--		@member_id NUMERIC(12,0),
--		@dvd_id NUMERIC(16,0),
--		@queue_position SMALLINT
	
--	-- Set test variables
--	SELECT @member_id = 1,
--		   @dvd_id = 3

-- Check to see if member has an established queue by selecting top 1 row from
-- RentalQueue where MemberId equals @member_id
-- If they have a queue proceed to the next check, else throw and error and stop
IF @member_id IN (SELECT TOP 1 MemberId FROM RentalQueue WHERE MemberId = @member_id)
	BEGIN
		-- Check to ensure the DVDId is valid, else throw and error and stop
		IF @dvd_id IN (SELECT DVDId FROM DVD) 
			BEGIN
				-- If the DVDId is currently in the rental queue for this customer proceed,
				-- else throw an error and stop
				IF @dvd_id IN (SELECT DVDId FROM RentalQueue WHERE MemberId = @member_id)
					BEGIN
					-- Find the dvd's current queue position and set a variable with it
					SET @queue_position = (SELECT QueuePosition 
										   FROM RentalQueue 
										   WHERE MemberId = @member_id AND DVDId = @dvd_id)
						
						-- Delete from the queue
						DELETE FROM RentalQueue
						WHERE MemberId = @member_id AND @dvd_id = DVDId;
						
						-- Update all queue items that had a greater queue value than the dvd that was deleted
						UPDATE RentalQueue
						SET QueuePosition = QueuePosition - 1
						WHERE MemberId = @member_id AND QueuePosition > @queue_position;
					END;
				-- Raise an error if the DVD is not in the queue
				ELSE
					BEGIN
						RAISERROR('Error, please choose a DVD that is currently in your queue.',11,1);
					END;
			END;
		-- Raise an error if the DVDId is invalid
		ELSE
			BEGIN
				RAISERROR('Error, please choose a valid DVDId.',11,1);
			END;
	END;
-- If the member does not have a queue raise an error
ELSE
	BEGIN
		RAISERROR('Error, you currently have no items in your queue.',11,1);
	END;

-- Test queue setup
-- Reset RentalQueue test data.
DELETE FROM RentalQueue
WHERE MemberId = 1;

-- Populate RentalQueue with test data
INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
VALUES (1, 1, GETDATE(), 1),
	   (1, 2, GETDATE(), 2),
	   (1, 3, GETDATE(), 3),
	   (1, 4, GETDATE(), 4),
	   (1, 5, GETDATE(), 5),
	   (1, 6, GETDATE(), 6),
	   (1, 7, GETDATE(), 7)

SELECT * FROM RentalQueue
WHERE MemberId = 1;

EXEC DELETE_RENTAL_QUEUE @member_id = 1, @dvd_id = 7

SELECT * FROM RentalQueue
WHERE MemberId = 1
ORDER BY QueuePosition