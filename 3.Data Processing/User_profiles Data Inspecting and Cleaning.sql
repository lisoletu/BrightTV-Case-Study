-- Databricks notebook source
-- This is to check what my data looks like.
SELECT *
FROM user_profiles
LIMIT 10;
--------------------------------------------
-- Checking for Duplicates
--------------------------------------------
SELECT COUNT(*),
       userid
FROM brighttv.analytics.user_profiles
GROUP BY userid
HAVING COUNT(*)>1;

----------------------------------------------------------------------------------------------------------------
---PROVINCE CHECKS--Inspecting the Province column and replacing blanks, None, Other and Null with Uncategorized
-----------------------------------------------------------------------------------------------------------------
SELECT DISTINCT Province
FROM user_profiles;

SELECT DISTINCT
    CASE 
        WHEN Province=' ' THEN 'Uncategorized'
        WHEN Province='None' THEN 'Uncategorized'
        WHEN Province = 'other' THEN 'Uncategorized'
        WHEN Province IS NULL THEN 'Uncategorized'
    ELSE Province
    END AS Regions
FROM brighttv.analytics.user_profiles;
------------------------------------------------------------------
---AGE CHECKS--Inspecting the Age column and creating age groups
------------------------------------------------------------------
SELECT DISTINCT MIN(Age) AS min_age, -- 0  (to find age of the youngest person)
                MAX(Age) AS max_age, -- 114  (to find age of the oldest person)
                AVG (Age) AS mean_age-- 27.696  (to find average age between upper bound and lower bound)
FROM user_profiles;

SELECT 
   CASE
        WHEN age = 0 THEN 'Infant'
        WHEN age BETWEEN 1 AND 12 THEN 'Kid'
        WHEN age BETWEEN 13 AND 17 THEN 'Youth'
        WHEN age BETWEEN 18 AND 35 THEN 'Young Adult'
        WHEN age BETWEEN 36 AND 50 THEN 'Adult'
        WHEN age BETWEEN 51 AND 60 THEN 'Elder'
        WHEN age >60 THEN 'Pensioner'
        ELSE 'Unknown'
    END AS age_groups
FROM brighttv.analytics.user_profiles;

-----------------------------------------------------------------------------------------------
---GENDER CHECKS---checking the gender column and replacing blanks, None and Null with unknown
-----------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------------------
-----RACE CHECKS-----checking the race column and replacing Other, None, Null and blanks with unknown
------------------------------------------------------------------------------------------------------
SELECT DISTINCT Race
FROM user_profiles;

SELECT COUNT (DISTINCT UserID) AS Subs,
    CASE
        WHEN Race ='None' THEN 'Unknown' ----Replaces None with unknown
        WHEN Race ='other' THEN 'Unknown'-----Replaces other with unknown
        WHEN Race =' ' THEN 'Unknown'-----Replaces empty space with unknown
        WHEN Race IS NULL THEN 'Unknown'-----Replaces null with unknown
    ELSE Race --keep it as it is
   END AS ethnicity -- new column name
   FROM user_profiles
GROUP BY ethnicity;

----------------------------------------------------------------------------------------------------------------------
---EMAIL CHECKS---checking the number of users who have emails (return 1 if email is there and 0 if there is no email)
----------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT Email
FROM user_profiles;

SELECT DISTINCT UserID, Email,
    CASE
        WHEN Email IS NULL
            OR Email = ' '
            OR Email = 'None'
        THEN 0
        ELSE 1
    END AS email_flag
FROM brighttv.analytics.user_profiles;

----------------------------------------------------------------------------------------------------------------------
---SOCIAL MEDIA HANDLE CHECKS----Counting the number of users who have social media handles (return 1 if  Social Media Handle is there and 0 if not there)
----------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT UserID, `Social Media Handle`
FROM user_profiles;

SELECT DISTINCT UserID, `Social Media Handle`,
    CASE
        WHEN `Social Media Handle` IS NOT NULL 
            OR `Social Media Handle`<> '' 
            OR  `Social Media Handle` NOT IN ('None')THEN 1
    ELSE 0
    END AS socialmedia_flag
FROM brighttv.analytics.user_profiles;


----------------------------------------------------------------------
---Creating 'cleaned_user_profiles' TEMPORARY table
----------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE cleaned_user_profiles AS 
(
    SELECT UserID,
   CASE 
        WHEN Gender = 'None' THEN 'unknown' 
        WHEN Gender = ' ' THEN 'unknown' 
        WHEN Gender IS NULL THEN 'unknown' 
    ELSE Gender 
    END AS Sex,

   CASE
        WHEN Race = 'None' THEN 'unknown' 
        WHEN Race = ' ' THEN 'unknown' 
        WHEN Race = 'other' THEN 'unknown' 
        WHEN Race IS NULL THEN 'unknown' 
    ELSE Race 
    END AS Ethnicity,

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
        WHEN Province=' ' THEN 'Uncategorized'
        WHEN Province='None' THEN 'Uncategorized'
        WHEN Province = 'other' THEN 'Uncategorized'
        WHEN Province IS NULL THEN 'Uncategorized'
    ELSE Province
    END AS Region,

    CASE
        WHEN Email IS NULL
            OR Email = ' '
            OR Email = 'None'
        THEN 0
    ELSE 1
    END AS email_flag,

    CASE
        WHEN `Social Media Handle` IS NOT NULL 
            OR `Social Media Handle`<> '' 
            OR  `Social Media Handle` NOT IN ('None')THEN 1
    ELSE 0
    END AS socialmedia_flag
FROM brighttv.analytics.user_profiles
);

---------------------------------------------------------------------------------
---to see what is on my TEMP table
------------------------------------------------------------------------------------

SELECT COUNT(*) AS total_records ---5375
FROM cleaned_user_profiles;


SELECT *
FROM cleaned_user_profiles;


