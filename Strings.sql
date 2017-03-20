--These queries use the prior described schema to demonstrate work with strings

-- Find the names of all members formatted by surname, firstname
SELECT surname||', '||firstname AS name
FROM cd.members;


-- Find all the facilties by a name prefix; tennis in this case
SELECT *
FROM cd.facilities
WHERE name LIKE 'Tennis%';


-- Find all facilities with tennis prefix, case in sensitive!
SELECT * FROM cd.facilities
WHERE UPPER(name) LIKE UPPER('tennis%');
-- Option 2
SELECT * FROM cd.facilities
WHERE name ILIKE 'tennis%';


-- Find all telephone numbers with parentheses (since they have
-- different formatting in the database)
SELECT memid, telephone
FROM cd.members
WHERE telephone LIKE '(%'
ORDER BY memid;


-- Pad the zip codes with leading zeroes
-- Due to the data type numeric, the leading zeroes have been truncated
SELECT LPAD(CAST(zipcode AS CHAR(5)), 5, '0') AS zip
FROM cd.members
ORDER BY zip;
-- Option 2
SELECT CASE
  WHEN zipcode>=0 AND zipcode<10 THEN TO_CHAR(zipcode, '00009')
  WHEN zipcode>=10 AND zipcode<100 THEN TO_CHAR(zipcode, '00099')
  WHEN zipcode>=100 AND zipcode<1000 THEN TO_CHAR(zipcode, '00999')
  WHEN zipcode>=1000 AND zipcode<10000 THEN TO_CHAR(zipcode, '09999')
  ELSE TO_CHAR(zipcode, '99999')
  END AS zip
FROM cd.members
ORDER BY zip;


-- Count the number of members whose surname starts with each number of the alphabet
-- only counting those letters with at least 1
SELECT DISTINCT temp.letter,
       COUNT(*) OVER(PARTITION BY temp.letter)
FROM (
  SELECT SUBSTRING(surname FROM '^.') AS letter, surname
  FROM cd.members
  ) temp
ORDER BY temp.letter;


-- Clean up the telephone number formats
-- I.e. remove - ( ) and spaces
SELECT memid, regexp_replace(telephone, '[^0-9]', '', 'g') as telephone
    FROM cd.members
    ORDER BY memid;
-- Option 2
SELECT memid, REGEXP_REPLACE(CAST(telephone AS CHAR(15)),
							 '[()\- ]',
							 '',
							 'g') AS telelphone
FROM cd.members
ORDER BY memid;