--These queries use the prior described schema to demonstrate aggregation

-- Count the number of facilities
SELECT COUNT(facid) FROM cd.facilities;


-- Count the number of facilities that have a cost for guests of 10 or more
SELECT COUNT(*) FROM cd.facilities
WHERE guestcost >= 10;


-- Count the number of reocmmendation that each member makes
SELECT recommendedby, COUNT(recommendedby) AS count
FROM cd.members
GROUP BY recommendedby
HAVING COUNT(recommendedby) > 0
ORDER BY recommendedby;


-- List the total slots booked per facilties
SELECT facid, SUM(slots) AS "Total Slots"
FROM cd.bookings
GROUP BY facid
ORDER BY facid;


-- List the total slots booked per facility in September 2012
SELECT facid, SUM(slots) AS "Total Slots"
  FROM cd.bookings
  WHERE starttime >= '2012-09-01'
  AND starttime < '2012-10-01'
  GROUP BY facid
ORDER BY "Total Slots";


-- List the total slots booked per facility per month in 2012
SELECT facid, EXTRACT(MONTH FROM starttime) AS month, SUM(slots) AS "Total Slots"
  FROM cd.bookings
  WHERE EXTRACT(YEAR FROM starttime) = 2012
  GROUP BY facid, month
  ORDER BY facid, "Total Slots";


-- Count the members who have made at least one booking
SELECT COUNT(DISTINCT memid) AS count
  FROM cd.bookings;


-- List the facilities with more than 1000 slots booked
SELECT facid, SUM(slots) AS "Total Slots"
  FROM cd.bookings
  GROUP BY facid
  HAVING SUM(slots) > 1000
ORDER BY facid;


-- Find the total revenue of each facility
-- Note that the cost for members and guests is different
SELECT f.name, SUM(
  CASE WHEN b.memid = 0 THEN f.guestcost*b.slots
  ELSE f.membercost*b.slots
  END) AS revenue
    FROM cd.bookings b
	  LEFT JOIN cd.facilities f ON b.facid = f.facid
	GROUP BY f.name
ORDER BY revenue;


-- Find the facilities with less than 1000 total revenue
SELECT name, revenue FROM
  (SELECT f.name, SUM(
    CASE WHEN b.memid = 0 THEN f.guestcost*b.slots
    ELSE f.membercost*b.slots
    END) AS revenue
      FROM cd.bookings b
	    LEFT JOIN cd.facilities f ON b.facid = f.facid
	  GROUP BY f.name) AS sales
 	WHERE revenue < 1000
ORDER BY revenue;


-- Get the facility ID with the highest number of slots booked
SELECT facid, SUM(slots) AS "Total Slots"
  FROM cd.bookings
  GROUP BY facid
  HAVING SUM(slots) = (
	SELECT MAX(sum2.total) FROM (
	  SELECT SUM(slots) AS total
	  FROM cd.bookings
	  GROUP BY facid) AS sum2);


-- List total slots booked per facility per month in 2012
-- In this query, include output rows containing the total sums for
-- all the months per facility AND a sum total at the end for all the
-- months for all facilities
SELECT facid, EXTRACT(MONTH FROM starttime) AS month, SUM(slots) AS slots
  FROM cd.bookings
  WHERE EXTRACT(YEAR FROM starttime) = 2012
  GROUP BY GROUPING SETS ((facid, month), (facid), ())
  ORDER BY facid, month;


-- Get the total number of hours booked per facility
SELECT f.facid, f.name, TRIM(TO_CHAR(SUM(b.slots)/2.0, '99999999999999999D99')) AS "Total Hours"
  FROM cd.facilities f
  LEFT JOIN cd.bookings b ON f.facid = b.facid
  GROUP BY f.facid
  ORDER BY f.facid;


-- Get each member's first booking after 2012-09-01
SELECT surname, firstname, memid, MIN(starttime) AS starttime
  FROM (
	SELECT m.surname, m.firstname, m.memid, b.starttime
	FROM cd.members m
	LEFT JOIN cd.bookings b ON m.memid = b.memid
	WHERE starttime > '2012-09-01') AS temp
	GROUP BY surname, firstname, memid
	ORDER BY memid;


-- Get a list of member names with each row containing the total member count
SELECT (SELECT COUNT(*) FROM cd.members), firstname, surname
  FROM cd.members
  ORDER BY joindate;


-- Produce a numbered list of members
-- STARTING WITH WINDOW FUNCTIONS
SELECT COUNT(*) OVER(ORDER BY joindate) AS row_number,
  firstname, surname
    FROM cd.members
	ORDER BY joindate;


-- Get the facility ID that has the most number of slots booked
-- This time use window functions
SELECT facid, total
  FROM (
	SELECT facid, SUM(slots) AS total,
	       RANK() OVER(ORDER BY SUM(slots) DESC) AS rank
	FROM cd.bookings
	GROUP BY facid
	) AS temp
	WHERE rank = 1;
--OPTION 2
SELECT DISTINCT facid, SUM(slots) AS total
  FROM cd.bookings
  GROUP BY facid
  ORDER BY total DESC
  LIMIT 1;


-- Rank members by hours that they have used the club facilities
-- rounded to the nearest 10 hours
SELECT m.firstname, m.surname,
  (SUM(b.slots)+10)/20*10 AS hours,
  RANK() OVER(ORDER BY (SUM(b.slots)+10)/20*10 DESC) AS rank
    FROM cd.bookings b
	LEFT JOIN cd.members m ON m.memid = b.memid
	GROUP BY m.firstname, m.surname, m.memid
ORDER BY rank, m.surname, m.firstname;


-- Get the top three revenue generating facilities
SELECT name, RANK() OVER (ORDER BY SUM(revenue) DESC) AS rank
  FROM (SELECT f.name, SUM(
		CASE WHEN b.memid = 0 THEN f.guestcost*b.slots
		ELSE f.membercost*b.slots
		END) AS revenue
		FROM cd.bookings b
		LEFT JOIN cd.facilities f ON b.facid = f.facid
		GROUP BY f.name) AS temp
    GROUP BY name
	LIMIT 3;


-- Classify facilities by value based on revenue
-- Each bucket is equally sized
SELECT name,
       CASE WHEN rev = 1 THEN 'high'
	   WHEN rev = 2 THEN 'average'
	   ELSE 'low'
	   END AS revenue
  FROM (
	SELECT f.name AS name, NTILE(3) OVER(ORDER BY SUM(
	  CASE WHEN b.memid = 0 THEN f.guestcost*b.slots
	  ELSE f.membercost*b.slots
	  END) DESC) AS rev
	FROM cd.bookings b
	LEFT JOIN cd.facilities f ON b.facid = f.facid
	GROUP BY f.name
	) AS temp
	ORDER BY rev, name;


-- Calculate the payback time for each facility
SELECT f.name, -f.initialoutlay/(f.monthlymaintenance-temp.revenue/3.0)
  AS months
  FROM (
	SELECT f.name AS name, SUM(
	CASE WHEN b.memid = 0 THEN f.guestcost*b.slots
	ELSE f.membercost*b.slots
	END) AS revenue
	FROM cd.bookings b
	LEFT JOIN cd.facilities f ON b.facid = f.facid
	GROUP BY f.name) AS temp
	LEFT JOIN cd.facilities f ON temp.name = f.name
ORDER BY name;


-- Calculate a rolling average of the total revenue for each day in August 2012
-- The rolling average should be over the last 15 days
-- Must account for the possibility that a day has zero revenue
SELECT temp.date, temp.revenue
FROM (
  SELECT ddata.date AS date,
    AVG(rdata.revenue) OVER(ORDER BY ddata.date ROWS 14 PRECEDING) AS revenue
  FROM (
	SELECT CAST(GENERATE_SERIES('2012-07-01', '2012-08-31',
								INTERVAL '1 day') AS DATE) AS date
	) AS ddata
  LEFT JOIN (
	SELECT CAST(b.starttime AS DATE) AS date,
	       SUM(CASE WHEN b.memid = 0 THEN f.guestcost*b.slots
			   ELSE f.membercost*b.slots
			   END) AS revenue
	FROM cd.bookings b
	LEFT JOIN cd.facilities f ON b.facid = f.facid
	GROUP BY CAST(b.starttime AS DATE)
  ) AS rdata
  ON ddata.date = rdata.date
) AS temp
  WHERE temp.date >= '2012-08-01'
ORDER BY temp.date;