SELECT d.genre, t.year, SUM(r.dvd_on_rent)
FROM RENTAL
JOIN DVD d ON d.dvd_key = r.dvd_key
JOIN time t ON t.time_key = r.time_key
JOIN distribution_center dc ON dc.distribution_center_key = r.distribution_center_key
WHERE t.year BETWEEN 2017 AND 2019
GROUP BY d.genre, t.year

SELECT t.month, COUNT(m.member_id) AS 'New Subscriptions'
FROM time t
JOIN member m ON m.time_key = t.time_key
GROUP BY t.month

SELECT ml.state, COUNT(m.member_id) AS 'Total Members'
FROM members m
JOIN member_location ml ON ml.location_key = m.location_key
GROUP BY ml.state
