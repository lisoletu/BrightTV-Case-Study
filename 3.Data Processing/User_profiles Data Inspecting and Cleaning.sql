-- Databricks notebook source

-- This is to check what my data looks like.
SELECT *
FROM brighttv.analytics.user_profiles
LIMIT 10;
--------------------------------------------
-- Checking for Duplicates
--------------------------------------------
SELECT COUNT(*),
       userid
FROM brighttv.analytics.user_profiles
GROUP BY userid
HAVING COUNT(*)>1;

----------------------------------------------------------
---EMAIL CHECKS
----------------------------------------------------------
SELECT DISTINCT Email
FROM brighttv.analytics.user_profiles;

SELECT DISTINCT UserID, Email,
    CASE
        WHEN Email IS NOT NULL 
            OR Email <>' ' 
            OR Email NOT IN ('None') THEN 1
        ELSE 0
        END AS email_flag
FROM brighttv.analytics.user_profiles;

----------------------------------------------------------
---GENDER CHECKS
----------------------------------------------------------
SELECT DISTINCT Gender
FROM user_profiles;

SELECT DISTINCT
    CASE
        WHEN Gender ='None' THEN 'Unknown' --Replaces the value None with unknown
        WHEN Gender =' ' THEN 'Unknown'--Replaces the empty space with unknown
        WHEN Gender IS NULL THEN 'unkonwn' --Replaces the null with unknown
    ELSE Gender -- if gender is male or female turn it as it is
    END AS Sex --new column name
FROM brighttv.analytics.user_profiles;
-----------------------------------------------------------------
-----RACE CHECKS
-----------------------------------------------------------------
SELECT DISTINCT Race
FROM brighttv.analytics.user_profiles;

SELECT COUNT (DISTINCT UserID) AS Subs,
    CASE
        WHEN Race ='None' THEN 'Unknown' ----Replaces None with unknown
        WHEN Race ='other' THEN 'Unknown'-----Replaces other with unknown
        WHEN Race =' ' THEN 'Unknown'-----Replaces empty space with unknown
        WHEN Race IS NULL THEN 'Unknown'-----Replaces null with unknown
    ELSE Race --keep it as it is
   END AS ethnicity -- new column name
   FROM brighttv.analytics.user_profiles
GROUP BY ethnicity;

------------------------------------------------------------------
---AGE CHECKS
------------------------------------------------------------------
SELECT DISTINCT MIN(Age) AS min_age, -- 0  (to find age of the youngest person)
                MAX(Age) AS max_age, -- 114  (to find age of the oldest person)
                AVG (Age) AS mean_age-- 27.696  (to find average age between upper bound and lower bound)
FROM brighttv.analytics.user_profiles;

SELECT 
    CASE
         WHEN Age = 0 THEN 'Infant'
        WHEN Age BETWEEN 1 AND 12 THEN 'Kids'
        WHEN Age BETWEEN 13 AND 17 THEN 'Youth'
        WHEN Age BETWEEN 18 AND 35 THEN 'Young Adult'
        WHEN Age BETWEEN 36 AND 50 THEN 'Adults'
        WHEN Age > 50 AND AGE<=60 THEN 'Elder' --Another way of doing a BETWEEN statement using operations
        WHEN Age > 60 THEN 'Pensioner'
    END AS Age_group
FROM brighttv.analytics.user_profiles;


---------------------------------------------------------------------
---PROVINCE CHECKS
--------------------------------------------------------------------
SELECT DISTINCT Province
FROM brighttv.analytics.user_profiles;

SELECT DISTINCT
CASE
        WHEN Province ='None' THEN 'Unknown'
        WHEN Province =' ' THEN 'Unknown'
        WHEN Province IS NULL THEN 'Unknown'
    ELSE Province
    END AS Region
FROM brighttv.analytics.user_profiles;

---------------------------------------------------------------------
---SOCIAL MEDIA HANDLE CHECKS
--------------------------------------------------------------------
SELECT DISTINCT UserID, `Social Media Handle`
FROM brighttv.analytics.user_profiles;

SELECT DISTINCT UserID, `Social Media Handle`,
 CASE
        WHEN `Social Media Handle` IS NOT NULL 
        AND `Social Media Handle`<>' ' 
        AND  `Social Media Handle` <> 'None'
    THEN 1
    ELSE 0
    END AS sm_flag
FROM brighttv.analytics.user_profiles;


----------------------------------------------------------------------
---Creating clean user_profiles table using TEMPORARY TABLES
----------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE user_profiles AS (

    SELECT UserID,

    CASE 
        WHEN Province=' ' THEN 'Uncategorized'
        WHEN Province='None' THEN 'Uncategorized'
        WHEN Province ='other' THEN 'Uncategorized'
        WHEN Province IS NULL THEN 'Uncategorized'
    ELSE Province
    END AS Region,

    age,
    CASE
        WHEN age = 0 THEN 'Infants:0'
        WHEN age BETWEEN 1 AND 12 THEN 'Kids:1-12'
        WHEN age BETWEEN 13 AND 19 THEN 'Teenager:13-19'
        WHEN age BETWEEN 20 AND 35 THEN 'Youth:20-35'
        WHEN age BETWEEN 36 AND 50 THEN 'Adult:36-50'
        WHEN age BETWEEN 51 AND 65 THEN 'Elder:51-65'
        WHEN age >65 THEN 'Pensioner:>65'
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

FROM brighttv.analytics.user_profiles
);

---------------------------------------------------------------------------------
---to see what is on my TEMP table
------------------------------------------------------------------------------------
SELECT *
FROM user_profiles;

