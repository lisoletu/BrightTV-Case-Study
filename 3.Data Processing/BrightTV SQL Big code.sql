-- Databricks notebook source
--------------------------------------------------------------------------
---Running the full tables before analysis to see what I have in my data
--------------------------------------------------------------------------
SELECT*
FROM brighttv.analytics.user_profiles
LIMIT 10;

SELECT *
FROM brighttv.analytics.viewership
LIMIT 10;


-------------------------------------------------------------------------------------------
-- Combining the TWO tables (user_profiles and Viewership) and create Final table using CTE
-------------------------------------------------------------------------------------------

WITH user_profiles AS (
    SELECT
        UserID,

        -- Checking the gender column and replacing blanks, None and Null with unknown
        CASE
            WHEN Gender = 'None' THEN 'unknown'
            WHEN Gender = ' ' THEN 'unknown'
            WHEN Gender IS NULL THEN 'unknown'
            ELSE Gender
        END AS Sex,

        -- Checking the race column and replacing Other, None, Null and blanks with unknown
        CASE
            WHEN Race = 'None' THEN 'unknown'
            WHEN Race = ' ' THEN 'unknown'
            WHEN Race = 'other' THEN 'unknown'
            WHEN Race IS NULL THEN 'unknown'
            ELSE Race
        END AS Ethnicity,

        -- Inspecting the Age column and creating age groups
        CASE
            WHEN age = 0 THEN 'Infant'
            WHEN age BETWEEN 1 AND 12 THEN 'Kid'
            WHEN age BETWEEN 13 AND 17 THEN 'Youth'
            WHEN age BETWEEN 18 AND 35 THEN 'Young Adult'
            WHEN age BETWEEN 36 AND 50 THEN 'Adult'
            WHEN age BETWEEN 51 AND 60 THEN 'Elder'
            WHEN age > 60 THEN 'Pensioner'
            ELSE 'Unknown'
        END AS age_groups,

        -- Inspecting the Province column and replacing blanks, None, Other and Null with Uncategorized
        CASE
            WHEN Province = ' ' THEN 'Uncategorized'
            WHEN Province = 'None' THEN 'Uncategorized'
            WHEN Province = 'other' THEN 'Uncategorized'
            WHEN Province IS NULL THEN 'Uncategorized'
            ELSE Province
        END AS Regions,

        -- Checking the number of users who have emails
        -- 1 = email available, 0 = no email
        CASE
            WHEN Email IS NULL
                OR Email = ''
                OR Email = ' '
                OR Email = 'None'
            THEN 0
            ELSE 1
        END AS email_flag,

        -- Checking the number of users who have social media handles
        -- 1 = social media handle available, 0 = no handle
        CASE
            WHEN `Social Media Handle` IS NULL
                OR `Social Media Handle` = ''
                OR `Social Media Handle` = ' '
                OR `Social Media Handle` = 'None'
            THEN 0
            ELSE 1
        END AS socialmedia_flag

    FROM brighttv.analytics.user_profiles
),

base_viewership AS (
    SELECT
        COALESCE(UserID0, userid4) AS userid,
        RecordDate2,
        -- Converting UTC timestamp to South African time
        FROM_UTC_TIMESTAMP(
            RecordDate2,
            'Africa/Johannesburg'
        ) AS RecordDate_SAST,
        Channel2,
        `Duration 2`
    FROM brighttv.analytics.viewership
),

Cleaned_Viewership AS (
    SELECT
        userid,
        RecordDate_SAST,

        -- Converting timestamp to date
        TO_DATE(RecordDate_SAST) AS watch_date,

        -- Extracting day of the week
        DAYNAME(TO_DATE(RecordDate_SAST)) AS day_name,

        -- Classifying viewing day
        CASE
            WHEN DAYNAME(TO_DATE(RecordDate_SAST)) IN ('Sat', 'Sun')
                THEN '02.Weekend'
            ELSE '01.Weekday'
        END AS Day_classification,

        -- Extracting month
        MONTHNAME(TO_DATE(RecordDate_SAST)) AS month_name,

        -- Extracting year
        YEAR(TO_DATE(RecordDate_SAST)) AS event_year,

        -- Extracting day
        DAY(TO_DATE(RecordDate_SAST)) AS event_day,

        -- Extracting hour
        HOUR(RecordDate_SAST) AS Hour_of_day,

        -- Converting timestamp to time
        DATE_FORMAT(
            RecordDate_SAST,
            'HH:mm:ss'
        ) AS watch_time,

        -- Classifying viewing time
        CASE
            WHEN DATE_FORMAT(RecordDate_SAST, 'HH:mm:ss')
                BETWEEN '00:00:00' AND '05:59:59'
                THEN '01. Midnight'

            WHEN DATE_FORMAT(RecordDate_SAST, 'HH:mm:ss')
                BETWEEN '06:00:00' AND '11:59:59'
                THEN '02. Morning'

            WHEN DATE_FORMAT(RecordDate_SAST, 'HH:mm:ss')
                BETWEEN '12:00:00' AND '16:59:59'
                THEN '03. Afternoon'

            WHEN DATE_FORMAT(RecordDate_SAST, 'HH:mm:ss')
                BETWEEN '17:00:00' AND '23:59:59'
                THEN '04. Evening'
        END AS time_of_day,

        -- Inspecting the channel column
        Channel2,

        -- Standardising channel names
        CASE
            WHEN Channel2 IN ('SawSee', 'Sawsee')
                THEN 'SawSee'

            WHEN Channel2 IN (
                'SuperSport Live Events',
                'Live on SuperSport',
                'Supersport Live Events',
                'DStv Events 1'
            )
                THEN 'Live Events'

            ELSE Channel2
        END AS Tv_channel,

        -- Inspecting the Duration 2 column
        `Duration 2`,

        -- Converting duration into time format
        DATE_FORMAT(
            `Duration 2`,
            'HH:mm:ss'
        ) AS Duration,

        -- Converting duration into total hours
        (
            HOUR(`Duration 2`)
            + MINUTE(`Duration 2`) / 60.0
            + SECOND(`Duration 2`) / 3600.0
        ) AS Duration_hours,

        -- Converting duration into total seconds
        (
            HOUR(`Duration 2`) * 3600
            + MINUTE(`Duration 2`) * 60
            + SECOND(`Duration 2`)
        ) AS Duration_seconds,

        -- Creating screen-time categories
        CASE
            WHEN Duration_seconds BETWEEN 300 AND 1800
                THEN '01. Low Usage (≤30 min)'

            WHEN Duration_seconds BETWEEN 1801 AND 3599
                THEN '02. Medium Usage (<60 min)'

            WHEN Duration_seconds >= 3600
                THEN '03. High Usage (≥60 min)'

            ELSE '04. No Usage'
        END AS Screen_time_bucket

    FROM base_viewership
)

-- Creating the final table
SELECT
    COALESCE(A.userid, B.UserID) AS sub_id,

    -- Viewing date and time
    A.watch_date,
    A.RecordDate_SAST,
    A.day_name,
    A.Day_classification,
    A.month_name,
    A.event_year,
    A.event_day,
    A.Hour_of_day,
    A.watch_time,
    A.time_of_day,

    -- Viewing behaviour
    A.Tv_channel,
    A.Duration,
    A.Duration_seconds,
    A.Duration_hours,
    A.screen_time_bucket,

    -- User demographics
    B.Regions,
    B.age_groups,
    B.Sex,
    B.Ethnicity,

    -- User engagement/profile indicators
    B.email_flag,
    B.socialmedia_flag

FROM Cleaned_Viewership AS A
LEFT JOIN user_profiles AS B
    ON A.userid = B.UserID;

