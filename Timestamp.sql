--These queries use the prior described schema to demonstrate work with dates/timestamps

-- Produce a timestamp for 1am on August 31st
SELECT TIMESTAMP '2012-08-31' + INTERVAL '1 hour' AS timestamp;
--Option 2
SELECT DATE '2012-08-31' + INTERVAL '1 hour' AS timestamp;


-- Subtract 2012-07-30 @ 1am from 2012-08-31 @ 1am
SELECT TIMESTAMP '2012-08-31 01:00:00' - TIMESTAMP '2012-07-30 01:00:00'
  AS interval;
--Option 2
SELECT '2012-08-31 01:00:00' - '2012-07-30 01:00:00'::TIMESTAMP AS interval;


-- Generate list of all dates in October 2012
SELECT GENERATE_SERIES('2012-10-01 00:00:00', '2012-10-31 00:00:00',
							INTERVAL '1 day') AS ts;


-- Get day of the month from a timestamp
-- 2012-08-31 in this case
SELECT EXTRACT(DAY FROM TIMESTAMP '2012-08-31');


-- Get number of seconds between 2012-08-31 @ 1am to 2012-09-02 @ midnight
SELECT EXTRACT(EPOCH FROM (
  TIMESTAMP '2012-09-02 00:00:00' - TIMESTAMP '2012-08-31 01:00:00'))
  AS date_part;


-- Get number of days in each money of 2012
SELECT EXTRACT(MONTH FROM temp.date1) AS month,
       temp.date2-temp.date1 AS length
  FROM (
	SELECT GENERATE_SERIES(TIMESTAMP '2012-01-01', TIMESTAMP '2012-12-01',
					       INTERVAL '1 month') AS date1,
	       GENERATE_SERIES(TIMESTAMP '2012-02-01', TIMESTAMP '2013-01-01',
					       INTERVAL '1 month') AS date2
	) AS temp;


-- Get number of days remaining in the month
-- Using 2012-02-11 01:00:00 as an example
SELECT DATE_TRUNC('month', temp.temp + INTERVAL '1 month') -
       DATE_TRUNC('day', temp.temp) AS remaining
  FROM (SELECT TIMESTAMP '2012-02-11 01:00:00' AS temp) AS temp;
--Option 2
SELECT DATE_TRUNC('month', TIMESTAMP '2012-02-11 01:00:00' + INTERVAL '1 month') -
       DATE_TRUNC('day', TIMESTAMP '2012-02-11 01:00:00')
	   AS remaining;


-- Get the end times of the last 10 bookings
SELECT temp.starttime, temp.endtime
FROM (
  SELECT starttime, slots,
         starttime + INTERVAL '30 minutes' * slots AS endtime
  FROM cd.bookings
  ) AS temp
ORDER BY temp.endtime DESC
LIMIT 10;


-- Get the count of bookings for each month
SELECT DISTINCT temp.month, COUNT(*) OVER(PARTITION BY month) AS count
FROM (
  SELECT DATE_TRUNC('month', starttime) AS month
  FROM cd.bookings
  ) AS temp
ORDER BY temp.month;


-- Get the utilization rate for each facility by month
-- Note that the club and its facilities open at 08:00 and close at 20:30
-- Assume that the club and its facilities are open every day of the month
SELECT f.name, temp.month,
       ROUND(
		 CAST(
		   SUM(temp.slots/2.0)/(12.5*EXTRACT(EPOCH FROM (
			 temp.month + INTERVAL '1 month' -
			 temp.month))/86400)*100
			 AS NUMERIC), 1) AS utilization
FROM (
  SELECT facid, DATE_TRUNC('month', starttime) AS month, slots
  FROM cd.bookings
  ) AS temp
INNER JOIN cd.facilities f ON temp.facid = f.facid
GROUP BY f.name, month
ORDER BY f.name, month;