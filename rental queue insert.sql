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

-- Create the stored proc for adding a DVD to the queue.
-- Takes MemberId, DVDId and Queue position as inputs.
-- Performs error checking on the following: 
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
		,@member_id NUMERIC(12,0),
		 @dvd_id NUMERIC(16,0),
		 @queue_position SMALLINT
	
	-- Set test variables
	SELECT @member_id = 1,
		   @dvd_id = 8,
		   @queue_position = 2

	-- Find the highest queue position
	SET @queue_max = (SELECT MAX(QueuePosition) FROM RentalQueue WHERE MemberId = @member_id)
	
	-- set @queue_maxP to max + 1 to track maximum queue values range
	SET @queue_maxPlus = @queue_max + 1

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
				ELSE
					BEGIN
						RAISERROR('Error, please choose a queue positon between 1 and %d.',12,1,@queue_maxPlus);
					END;
			END;
		ELSE
			BEGIN
				RAISERROR('Error, please choose a DVD that is not already in your queue.',11,1);
			END;
	END;
ELSE
	BEGIN
		RAISERROR('Error, please choose a valid DVDId.',11,1);
	END;


SELECT * FROM RentalQueue
WHERE MemberId = 1
ORDER BY QueuePosition