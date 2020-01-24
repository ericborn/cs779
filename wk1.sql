use NetFlix

-- 1. Adding and populating columns, SQL string operators

-- a. Select all data from the memebership table
SELECT * FROM membership;

-- b. Add an attribute called DVDAtTime to the membership table
ALTER TABLE membership
ADD DVDAtTime SMALLINT;

-- c. Updates the rows with the apropriate value for DVDAtTime
-- Uses a left select 1 to get the first character from the MembershipType column
-- joins membership back on itself on the MembershipId column to ensure it updates the correct record
UPDATE membership
SET DVDAtTime = (SELECT LEFT(MembershipType,1) 
				 FROM membership m2
				 WHERE membership.MembershipId = m2.MembershipId
				);

-- d.	Select all data from the membership table to verify that you obtained the intended results.
SELECT MembershipId, MembershipType, MembershipLimitPerMonth, MembershipMonthlyPrice, 
	   MembershipMonthlyTax, MembershipDVDLostPrice, DVDAtTime
FROM membership;

--2. Sequences
-- View the rental table
SELECT * FROM rental;

-- a.	Implement a single sequence 
-- Starting the squence at 11 since there are already 10 records inside the rental table
CREATE SEQUENCE RentalId
AS INT
START WITH 11
INCREMENT BY 1;

-- c.	Demonstrate sequence by inserting two new records into the rental table.
-- calls next value for from the RentalID sequence as the RentalId column of the rental table
INSERT INTO rental (RentalId, MemberId, DVDId, RentalRequestDate, RentalShippedDate, RentalReturnedDate)
VALUES (NEXT VALUE FOR dbo.RentalId, 9, 3, GETDATE(), NULL, NULL),
	   (NEXT VALUE FOR dbo.RentalId, 8, 4, GETDATE(), NULL, NULL);

-- 3.	Schema augmentation, nullability, CHECK
SELECT * FROM Member;
SELECT * FROM DVD;

CREATE SEQUENCE DVDReviewId
AS INT
START WITH 1
INCREMENT BY 1;

CREATE TABLE DVDReview (
	ReviewId INT PRIMARY KEY 
		DEFAULT (NEXT VALUE FOR DVDReviewId),
	MemberId INT FOREIGN KEY REFERENCES Member(MemberId),
	StarValue INT NOT NULL CHECK (StarValue >= 0 AND StarValue <= 5),
	ReviewDate DATETIME NOT NULL DEFAULT GETDATE(),
	DVDReview VARCHAR(255),

);