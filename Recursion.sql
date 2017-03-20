--These queries use the prior described schema to demonstrate recursion

-- Find the upward recommendation chain for member id 27
-- I.e. the member who recommended id 27 and the member who
-- recommended that one, etc
WITH RECURSIVE rec(recommender) AS (
  SELECT recommendedby
    FROM cd.members
    WHERE memid = 27
  UNION ALL
  SELECT m.recommendedby
    FROM rec r
    INNER JOIN cd.members m ON r.recommender = m.memid
)
SELECT r.recommender, m.firstname, m.surname
FROM rec r
INNER JOIN cd.members m ON r.recommender = m.memid
ORDER BY r.recommender DESC;


-- Find the downward recommendation chain for member id 1
-- I.e. the member(s) id 1 recommended and the members who
-- those members recommended, etc
-- This will include multiple branches since a member may
-- recommend multiple members
WITH RECURSIVE rec(memid) AS (
  SELECT memid
  FROM cd.members
  WHERE recommendedby = 1
  UNION ALL
  SELECT m.memid
  FROM rec r, cd.members m
  WHERE m.recommendedby = r.memid
)
SELECT r.memid, m.firstname, m.surname
FROM rec r
INNER JOIN cd.members m ON r.memid = m.memid
ORDER BY r.memid;


-- Use a CTE that can return the upward recommendation chain for any member
-- It is tested using member ids 12 and 22
WITH RECURSIVE rec(member, recommender) AS (
  SELECT memid, recommendedby
  FROM cd.members
  UNION ALL
  SELECT r.member, m.recommendedby
  FROM rec r
  INNER JOIN cd.members m ON r.recommender = m.memid
)
SELECT r.member, r.recommender, m.firstname, m.surname
FROM rec r
INNER JOIN cd.members m ON r.recommender = m.memid
WHERE (r.member = 12 OR r.member = 22)
ORDER BY r.member, r.recommender DESC;