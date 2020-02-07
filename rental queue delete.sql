--Reset RentalQueue test data.
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

-- Create the stored proc for deleting a DVD from the queue.
-- Takes MemberId and DVDId inputs.
-- Performs error checking on the following: 
-- Invalid DVDId's.
-- DVDId not in the members queue.

--CREATE OR ALTER PROCEDURE DELETE_RENTAL_QUEUE
--	@member_id NUMERIC(12,0),
--	@dvd_id NUMERIC(16,0)
--AS
-- Create variables to store the highest value current in the queue and that value plus 1
DECLARE
		-- Test variables
		@member_id NUMERIC(12,0),
		@dvd_id NUMERIC(16,0),
		@queue_position SMALLINT
	
	-- Set test variables
	SELECT @member_id = 1,
		   @dvd_id = 3

-- Check to see if member has an established queue by selecting top 1 row from
-- RentalQueue where MemberId equals @member_id
-- If they have a queue proceed to the next check
IF @member_id IN (SELECT TOP 1 MemberId FROM RentalQueue WHERE MemberId = @member_id)
	BEGIN
		-- Check to ensure the DVDId is valid
		IF @dvd_id IN (SELECT DVDId FROM DVD) 
			BEGIN
				-- If the DVDId is currently in the rental queue for this customer proceed
				-- if its not, throw an error and stop
				IF @dvd_id IN (SELECT DVDId FROM RentalQueue WHERE MemberId = @member_id)
					BEGIN
					SET @queue_position = (SELECT QueuePosition 
										   FROM RentalQueue 
										   WHERE MemberId = @member_id AND DVDId = @dvd_id)
						
						DELETE FROM RentalQueue
						WHERE MemberId = @member_id AND QueuePosition = @queue_position;
						
						UPDATE RentalQueue
						SET QueuePosition = QueuePosition - 1
						WHERE MemberId = @member_id AND QueuePosition > @queue_position;

						--SELECT * FROM RentalQueue
						--WHERE MemberId = 1 AND QueuePosition > 5;
					END;
				-- Raise an error if the DVD is not in the queue
				ELSE
					BEGIN
						RAISERROR('Error, please choose a DVD that is currently in your queue.',11,1);
					END;
			END;
		-- Raise an error for the DVDId being invalid
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

SELECT * FROM RentalQueue
WHERE MemberId = 1
ORDER BY QueuePosition