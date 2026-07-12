-- Databricks notebook source

---Telling Databricks to use the "brighttv" catalog and "analytics" schema---
-----------------------------------------------------------------------------
USE brighttv.analytics;


---Running the full tables before analysis to see what I have in my data
--------------------------------------------------------------------------
SELECT*
FROM user_profiles
LIMIT 10;

SELECT *
FROM viewership
LIMIT 10;



-- Checking for Duplicates
---------------------------------------
SELECT UserID, 
       COUNT(*) AS duplicate_count
FROM user_profiles
GROUP BY UserID
HAVING COUNT(*) > 1;



-- Checking the size of the data
--------------------------------------------------
SELECT COUNT(*) AS number_of_rows,
       COUNT(DISTINCT UserID) AS number_subs
FROM user_profiles;



-- Checking if there is any rows where UserID is NULL
--------------------------------------------------------- 
SELECT COUNT(*) AS cnt
FROM user_profiles
WHERE UserID IS NULL;

SELECT DISTINCT UserID
FROM user_profiles;



---Gender Checks
--------------------------------------------------------
SELECT DISTINCT Gender
FROM user_profiles;

SELECT 
        COUNT(DISTINCT UserID) AS Subs,
    CASE
        WHEN Gender ='None' THEN 'Unknown' --Replaces the value "None" with "unknown"
        WHEN Gender =' ' THEN 'Unknown'--Replaces the empty space with "unknown"
    ELSE Gender -- if gender is male or female turn it as it is
    END AS Gender_clean --result column name
FROM user_profiles
GROUP BY Gender;


----Race Checks
------------------------------------------------------------------
SELECT COUNT(*) AS num_rows
FROM user_profiles
WHERE Race IS NULL;

SELECT DISTINCT Race
FROM user_profiles;

SELECT COUNT(DISTINCT UserID)  AS subs,
        CASE 
            WHEN race = 'other' THEN 'unknown' -- Replace "other" with "unknown"
            WHEN race = 'None' THEN 'unknown' -- Replace "None" with "unknown"
            WHEN race = ' ' THEN 'unknown' -- Replace empty with "unknown"
        ELSE Race -- keep it as it is
        END AS Race -- result column name
FROM user_profiles
GROUP BY Race;


--Province checks
---------------------------------------------------------
SELECT DISTINCT Province
FROM user_profiles;

SELECT COUNT(DISTINCT UserID) AS Subs,
    CASE 
        WHEN Province=' ' THEN 'Uncategorized'
        WHEN Province='None' THEN 'Uncategorized'
    ELSE Province
    END AS Region
FROM user_profiles
GROUP BY Province;



--Age Checks
---------------------------------------------------------
 SELECT MIN(Age) AS min_age, --- = 0
        MAX(Age) AS max_age -- = 114
 FROM user_profiles;

 SELECT COUNT(*) AS cnt
 FROM user_profileS
 WHERE age IS NULL;


---Final table after processing
----------------------------------------------------------------------------------
 WITH user_profiles AS (
SELECT UserID,

    CASE 
        WHEN Province=' ' THEN 'Uncategorized'
        WHEN Province='None' THEN 'Uncategorized'
    ELSE Province
    END AS Region,

    age,
    CASE
        WHEN age = 0 THEN 'Infants'
        WHEN age BETWEEN 1 AND 12 THEN 'Kids'
        WHEN age BETWEEN 13 AND 19 THEN 'Teenager'
        WHEN age BETWEEN 20 AND 35 THEN 'Youth'
        WHEN age BETWEEN 36 AND 50 THEN 'Adult'
        WHEN age BETWEEN 51 AND 65 THEN 'Elder'
        WHEN age >65 THEN 'Pensioner'
    END AS age_groups,

    CASE
        WHEN (email IS NOT NULL )OR (email=' ') OR  (email NOT IN ('None'))THEN 1
    ELSE 0
    END AS email_flag,

    CASE
        WHEN `Social Media Handle` IS NOT NULL OR `Social Media Handle`=' ' OR  `Social Media Handle` NOT IN ('None')THEN 1
        ELSE 0
    END AS sm_flag,

    CASE
        WHEN Race='other' THEN 'None'
        WHEN Race=' ' THEN 'None'
    ELSE Race
    END AS Race,

    CASE
        WHEN gender =' ' THEN 'None'
        ELSE gender
    END AS Gender

FROM user_profiles
),
viewership AS (
    SELECT
    COALESCE(UserID0,userid4) AS userid,
    TO_CHAR(RecordDate2, 'yyyyMM') AS month_id,
    TO_DATE(RecordDate2) AS watch_date,
    --TIME(RecordDate2) AS watch_time,
    TO_CHAR(RecordDate2, 'DD') AS day_of_week,
    DAYNAME(RecordDate2) AS day_name,

    CASE
        WHEN day_name IN ('Sat', 'Sun') THEN 'weekend'
        ELSE 'weekday'
    END AS day_classification,

    MONTHNAME(RecordDate2) AS month_name,

    CASE 
        WHEN Channel2 IN ('SawSee','Sawsee') THEN 'SawSee'
        WHEN Channel2 IN ('SuperSport Live Events','Live on SuperSport', 'Supersport Live Events', 'DStv Events 1') THEN 'Live Events'
    ELSE Channel2
    END AS Tv_channel,

    date_format(RecordDate2, 'HH:mm:ss') AS watch_time,
    CASE
        WHEN watch_time BETWEEN '00:00:00' AND '05:59:59' THEN '01. Midnight'
        WHEN watch_time BETWEEN '06:00:00' AND '11:59:59' THEN '02. Morning'
        WHEN watch_time BETWEEN '12:00:00' AND '16:59:59' THEN '03. Afternoon'
        WHEN watch_time BETWEEN '17:00:00' AND '23:59:59' THEN '04. Evening'
    END AS time_of_day,

    DATE_FORMAT(`Duration 2`, 'HH:mm:ss') AS duration,
    CASE 
        WHEN duration BETWEEN '00:05:00' AND '00:30:00' THEN '01. Low Usage: <30 min'
        WHEN duration BETWEEN '00:30:01' AND '00:59:59' THEN '02. Med Usage: <60 min'
        WHEN duration > '00:59:59' THEN '03. High Usage: >60 min'
        ELSE '04. No Usage'
    END AS screen_time_bucket,

    HOUR(RecordDate2) AS hour_of_day

FROM viewership
)
SELECT Coalesce(A.userid,B.userid) AS sub_id,
       month_id,
       watch_date,
       day_of_week,
       day_name,
       day_classification,
       month_name,
       Tv_channel,
       time_of_day,
       hour_of_day,
       screen_time_bucket,
       --user_flag,
       duration,
       Region,
       age_groups,
       email_flag,
       sm_flag,
       Race,
       Gender
FROM viewership AS A
LEFT JOIN user_profiles AS B
ON A.userid=B.userid;


