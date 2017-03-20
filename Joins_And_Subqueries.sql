--These queries use the prior described schema to demonstrate joins and subqueries

-- Get the booking start times of member, David Farrell
SELECT starttime FROM cd.members m
    LEFT JOIN cd.bookings b ON (m.memid = b.memid)
	WHERE firstname||' '||surname = 'David Farrell';


-- Get the start times of bookings for the tennis courts on 2012-09-21
SELECT starttime AS start, name
FROM cd.bookings b LEFT JOIN cd.facilities f ON(b.facid = f.facid)
    WHERE starttime > '2012-09-21' AND starttime < '2012-09-22'
	AND
	name LIKE '%Tennis Court%'
	ORDER BY start;


-- Get list of members who have recommended another member
SELECT DISTINCT m1.firstname, m1.surname
FROM cd.members m1
INNER JOIN cd.members m2 ON m1.memid = m2.recommendedby
ORDER BY surname, firstname;


-- Get list of all members and their recommender
SELECT m1.firstname AS memfname, m1.surname AS memsname,
m2.firstname AS recfname, m2.surname AS recsname
FROM cd.members m1
LEFT JOIN cd.members m2 ON m1.recommendedby = m2.memid
ORDER BY memsname, memfname;


-- Get list of all members who have used a tennis court
SELECT DISTINCT m.firstname||' '||m.surname AS member, temp.name AS facility
FROM cd.members m RIGHT JOIN (
  SELECT memid, name FROM cd.bookings b LEFT JOIN cd.facilities f
  ON b.facid = f.facid) temp
  ON m.memid = temp.memid
  WHERE temp.name LIKE '%Tennis Court%';


-- Get list of bookings on 2012-09-14 that cost more than $30
-- Note that the cost for members and guests is different
SELECT m.firstname||' '||m.surname AS member, f.name AS facility,
    CASE WHEN m.memid = 0 THEN f.guestcost*b.slots
	ELSE f.membercost*b.slots
	END AS cost
	FROM cd.bookings b
	LEFT JOIN cd.members m ON b.memid = m.memid
	LEFT JOIN cd.facilities f ON b.facid = f.facid
    WHERE b.starttime >= '2012-09-14' AND b.starttime < '2012-09-15'
	AND(
	(m.memid = 0 AND f.guestcost*b.slots > 30)
	OR
	(m.memid != 0 AND f.membercost*b.slots >30))
ORDER BY cost DESC;


-- Get list of all members along with their recommender
-- WITHOUT using joins
SELECT DISTINCT m1.firstname||' '||m1.surname AS member,
    (SELECT m2.firstname||' '||m2.surname AS recommender
    FROM cd.members m2
	WHERE m1.recommendedby = m2.memid)
	FROM cd.members m1
ORDER BY member;


-- Get list of bookings on 2012-09-14 over $30 WITHOUT using subqueries
SELECT member, facility, cost FROM (
  SELECT m.firstname||' '||m.surname AS member, f.name AS facility,
  CASE WHEN m.memid = 0 THEN f.guestcost*b.slots
  ELSE f.membercost*b.slots
  END AS cost
  FROM cd.bookings b
  LEFT JOIN cd.members m ON b.memid = m.memid
  LEFT JOIN cd.facilities f ON b.facid = f.facid
  WHERE b.starttime >= '2012-09-14' AND b.starttime < '2012-09-15'
  ) AS bookings
WHERE cost > 30
ORDER BY cost DESC;