/*
Eric Born
CS779
8 Feb 2020
Homework wk. 2
*/

SELECT * FROM Rental
SELECT * FROM dvd


-- 1.
-- Create a sequence for the rental history tables ID
CREATE SEQUENCE RentalHistory_Seq
AS INT
START WITH 1
INCREMENT BY 1;

-- Create a rental history table
CREATE TABLE RentalHistory (
RentalHistoryId NUMERIC(12,0),
RentalId NUMERIC(12,0),
MemberId NUMERIC(12,0),
DVDCopyId NUMERIC(16,0),
DVDId NUMERIC(16,0),
ZipcodeId VARCHAR(5),
DVDTitle VARCHAR(100),
GenreName VARCHAR(20),
RentalRequestDate DATETIME,
RentalShippedDate DATETIME,
RentalReturnedDate DATETIME,
MembershipType VARCHAR(128),
MemberSinceDate DATETIME,
QueuePosition SMALLINT
);

-- alter statements to add genrename, ratingname and description to the DVD table
ALTER TABLE DVD
ADD GenreName VARCHAR(20),
	RatingName VARCHAR(10),
	RatingDescription VARCHAR(255);

-- set genre name within DVD
UPDATE DVD
SET GenreName = g.GenreName
FROM DVD AS d
INNER JOIN genre g ON d.GenreId = g.GenreId;

-- set RatingName and Description within DVD
UPDATE DVD
SET RatingName = r.RatingName,
	RatingDescription = r.RatingDescription
FROM DVD AS d
INNER JOIN rating r ON d.RatingId = r.RatingId;

SELECT * FROM DVD d
INNER JOIN rating r ON d.RatingId = r.RatingId;


SELECT * FROM Rental
WHERE RentalRequestDate < '20190203'

-- Add a queue position to the rental table
ALTER TABLE rental
ADD QueuePosition SMALLINT;

INSERT INTO RentalHistory
SELECT
NEXT VALUE FOR RentalHistoryId, r.RentalId, r.MemberId, r.DVDCopyId,
DC.DVDId, z.ZipcodeId, d.DVDTitle, d.GenreName, r.RentalRequestDate,
r.RentalShippedDate, r.RentalReturnedDate, ms.MembershipType,
m.MemberSinceDate, QueuePosition
FROM Rental r
JOIN DVD_Copy dc ON dc.DVDCopyId = r.DVDCopyId
JOIN DVD d ON d.DVDId = dc.DVDId
JOIN Member m ON m.MemberId = r.MemberId
JOIN Membership ms ON m.MembershipId = ms.MembershipId
JOIN ZipCode z	on z.ZipCodeId = m.MemberAddressId
WHERE RentalRequestDate < '20190203'

-- 2. Prevent deletions from RentalHistory to prevent deletions
CREATE OR ALTER TRIGGER Trig_Rental_hist_delete ON RentalHistory
BEGIN
	raise_application_error(-20001,'Records can not be deleted')
	dbms_output.put_line( 'Records can not be deleted')
END;

-- insert movie at beginning, middle and the end of the queue

-- 3. Trigger for updating RentalHistory table RentalShippedDate column when dvd sent to customer
-- trigger should probably be placed on rental table update


-- 4. Trigger for updating RentalHistory table RentalReturnedDate column when dvd received back from customer

-- 5. 
-- Code to expand RentalQueue to include queue position
ALTER TABLE RentalQueue
ADD QueuePosition SMALLINT;