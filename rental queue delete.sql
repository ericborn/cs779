--Reset RentalQueue test data.
--DELETE FROM RentalQueue
--WHERE MemberId = 2;

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
		@dvd_id NUMERIC(16,0)
	
	-- Set test variables
	SELECT @member_id = 3,
		   @dvd_id = 1

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
	

SELECT * FROM RentalQueue
WHERE MemberId = 2
ORDER BY QueuePosition