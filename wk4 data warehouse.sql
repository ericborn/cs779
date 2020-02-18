SELECT d.genre, t.year, SUM(r.dvd_on_rent)
FROM RENTAL
JOIN DVD d ON d.dvd_key = r.dvd_key
JOIN time t ON t.time_key = r.time_key
JOIN distribution_center dc ON dc.distribution_center_key = r.distribution_center_key
WHERE t.year BETWEEN 2017 AND 2019
GROUP BY d.genre, t.year, r.dvd_on_rent

SELECT t.month, t.year, COUNT(m.time_key)
FROM time t
JOIN member m ON m.time_key = t.time_key
GROUP BY 