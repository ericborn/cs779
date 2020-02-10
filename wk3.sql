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