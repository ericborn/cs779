-- 2.
ALTER TABLE membership
ADD DVDAtTime SMALLINT;

UPDATE membership
SET DVDAtTime = (SELECT LEFT(MembershipType,1) 
				 FROM membership m2
				 WHERE membership.MembershipId = m2.MembershipId
			   );

-- Creates a sequence which will be used to increment the DVD_Copy table
CREATE SEQUENCE DVDCopyId_Seq
AS INT
START WITH 1
INCREMENT BY 1;

-- DVD_Copy contains a unique ID for each dvd the store owns, even if they own multiples of the same movie.
-- This is incremented by the sequence DVDCopyId_Seq
CREATE TABLE DVD_Copy (
	DVDCopyId NUMERIC(16) DEFAULT (NEXT VALUE FOR DVDCopyId_Seq) NOT NULL,
	DVDId NUMERIC(16) NOT NULL,
	DVDQtyOnHand BIT DEFAULT 1,
	DVDQtyOnRent BIT DEFAULT 0,
	DVDQtyLost BIT DEFAULT 0,
	CONSTRAINT DVD_Copy_PK PRIMARY KEY (DVDCopyId)
);

-- 3.
-- SQL files which load the data into the tables
:setvar path "C:\Netflix\"
:r $(path)\dvd_script.sql

:setvar path "C:\Netflix\"
:r $(path)\movieperson_script.sql

:setvar path "C:\Netflix\"
:r $(path)\movieperson_role_script.sql

:setvar path "C:\Netflix\"
:r $(path)\dvd_quantity_script.sql

:setvar path "C:\Netflix\"
:r $(path)\rental_queue_script.sql

:setvar path "C:\Netflix\":r $(path)\rental_script.sql

-- Output verifying the loaded data
SELECT COUNT(*) AS 'DVD'
FROM DVD

SELECT COUNT(*) AS 'Rental'
FROM Rental

SELECT COUNT(*) AS 'Movie Person'
FROM MoviePerson

SELECT COUNT(*) AS 'Movie Person Role'
FROM MoviePersonRole

SELECT COUNT(*) AS 'Rental Queue'
FROM RentalQueue

-- Purpose of this while loop is to populate the dvd_copy table with a record for each dvd the store owns
-- Setup variables to store a counter and total number of records within the dvd table
DECLARE @cnt INT = 1;
DECLARE @total INT = (SELECT COUNT(*) AS 'total' FROM DVD);

-- While loop that iterates from 1 to the total number of rows in the dvd table
WHILE @cnt <= @total 
BEGIN
	-- setup new variables used to track the total sum of the 
	-- DVDQuantityOnHand, DQuantityOnRent and DVDLostQuantity
	-- columns from the dvd table. Uses @cnt to iterate one row at a time
	-- calculating the sum
	DECLARE @rowCnt INT = 1;
	DECLARE @dvdTotal INT = (
	SELECT SUM(DVDQuantityOnHand + DVDQuantityOnRent + DVDLostQuantity) AS 'dvd total'
	FROM DVD
	WHERE DVDId = @cnt);
	
-- second loop that actually performs the insert into dvd_copy based on how many
-- copies the dvd store owns
	WHILE @rowCnt < @dvdTotal + 1
		BEGIN
			INSERT INTO DVD_Copy (DVDCopyId, DVDId)
			VALUES (NEXT VALUE FOR dbo.DVDCopyId_Seq, @cnt)
		SET @rowCnt = @rowCnt + 1;
		END;
	--print @cnt
	SET @cnt = @cnt + 1;
END;

-- The last update that would need to take place is converting the data in the rental 
-- table to the correct DVD’s in the DVD_Copy table.  This is difficult since the DVDId 
-- in the rental table is not unique so a count needs to be gathered for each ID and then 
-- used to increment the correct number of rows for that DVD within the DVD_Copy table.

SELECT DVDId, COUNT(*) AS 'dvd count'
FROM rental --DVD_Copy
WHERE RentalReturnedDate IS NULL AND RentalShippedDate IS NOT NULL
GROUP BY DVDId

-- Sets DVDQtyOnRent = 1 where the dvd from the rental table 
UPDATE DVD_Copy
SET DVDQtyOnRent = 1
WHERE DVDCopyId IN (SELECT DVDId
					FROM rental
					WHERE RentalReturnedDate IS NULL AND
					RentalShippedDate IS NOT NULL)

-- Finally set the quantity on hand to 0 wherever a dvd is currently out to a customer
UPDATE DVD_Copy
SET DVDQtyOnHand = 0
WHERE DVDQtyOnRent = 1
