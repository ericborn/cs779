/*
Eric Born
CS779
8 Feb 2020
Homework wk. 2
*/

SELECT * FROM Rental

-- 1. Create a rental history table
-- 
CREATE TABLE RentalHistory(
RentalShippedDate,
RentalReturnedDate

)

-- insert movie at beginning, middle and the end of the queue



-- 2. Prevent deletions from RentalHistory to prevent deletions

-- 3. Trigger for updating RentalHistory table RentalShippedDate column when dvd sent to customer
-- trigger should probably be placed on rental table update

-- 4. Trigger for updating RentalHistory table RentalReturnedDate column when dvd received back from customer

--5. 
-- Code to expand RentalQueue to include queue position
ALTER TABLE RentalQueue
ADD QueuePosition SMALLINT;