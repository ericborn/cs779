

--DROP TABLE Deadlocker1
--DROP TABLE Deadlocker2

-- 2.
CREATE TABLE Deadlocker1 (x INTEGER);
CREATE TABLE Deadlocker2 (x INTEGER);

-- 3.
INSERT INTO Deadlocker1 VALUES(1);
INSERT INTO Deadlocker1 VALUES(2);
INSERT INTO Deadlocker2 VALUES(1);
INSERT INTO Deadlocker2 VALUES(2);

SELECT * FROM Deadlocker1;
SELECT * FROM Deadlocker2;

-- 4.
BEGIN TRAN TRAN1
UPDATE Deadlocker1 SET x=3 where x=1;

-- 7.
UPDATE Deadlocker2 SET x=5 where x=2; 