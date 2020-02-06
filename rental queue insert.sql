--CREATE OR ALTER PROCEDURE ADD_RENTAL_QUEUE
--	@member_id NUMERIC(12,0),
--	@dvd_id NUMERIC(16,0),
--	@queue_position SMALLINT,
--	@queue_max SMALLINT,

-- Reset RentalQueue test data.
DELETE FROM RentalQueue
WHERE MemberId = 1;

-- Populate RentalQueue with test data
INSERT INTO RentalQueue(MemberId, DVDId, DateAddedInQueue, QueuePosition)
VALUES (1, 1, GETDATE(), 1),
	   (1, 2, GETDATE(), 2),
	   (1, 3, GETDATE(), 3),
	   (1, 4, GETDATE(), 4),
	   (1, 5, GETDATE(), 5);

SELECT * FROM RentalQueue
WHERE MemberId = 1;

DECLARE @member_id NUMERIC(12,0),
		@dvd_id NUMERIC(16,0),
		@queue_position SMALLINT,
		@queue_max SMALLINT,
		@queue_maxPlus SMALLINT

	SELECT @member_id = 1,
		   @dvd_id = 6,
		   @queue_position = 100

	SET @queue_max = (SELECT MAX(QueuePosition) FROM RentalQueue WHERE MemberId = @member_id)
	
	-- set @queue_maxP to max + 1 to track maximum queue values range
	SET @queue_maxPlus = @queue_max + 1

--PRINT @member_id
--PRINT @dvd_id
--PRINT @queue_position
--PRINT @queue_min
--PRINT @queue_max

-- If the selected queue position is greater than 0 or less than or equal to 1 
-- greater than the highest queue value proceed with the insert. Otherwise raise an error
IF (@queue_position > 0 AND @queue_position <= @queue_maxPlus)
	BEGIN
		PRINT('Number is fine');
		IF @queue_position = @queue_maxPlus
			BEGIN
				--Insert at max queue position
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
	RAISERROR('Error, please choose a queue positon between 1 and %d',11,1,@queue_maxPlus);

SELECT * FROM RentalQueue
WHERE MemberId = 1
ORDER BY QueuePosition