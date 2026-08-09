-- Databricks notebook source
--- I want to see what is in this ORIGINAL viewership table/see the structure of the data
SELECT *
FROM brighttv.analytics.viewership
LIMIT 10;


--Applying DATE FUNCTIONS to extracting watch time in YY-MM-DD format from 'RecordDate2' column (timestamp) into Date
SELECT  RecordDate2,
        TO_DATE(RecordDate2) AS watch_date --TO_DATE function converts a string (timestamp) into a date (YYYY-MM-DD)
FROM brighttv.analytics.viewership;


---Using more DATE FUNCTIONS to extract dates (year, month, day) 
SELECT
    UserID0,
    RecordDate2,
    TO_DATE(RecordDate2) AS watch_date, --TO_DATE Converts a string into a date YYYY-MM-DD
    DAYNAME(TO_DATE(RecordDate2)) AS day_name, -- Extracts the day name (Mon-Sun)
    MONTHNAME(TO_DATE(RecordDate2)) AS month_name, -- Extracts the month name (Jan-Dec)
    YEAR(TO_DATE(RecordDate2)) AS event_year, -- Extracts the year value
    DAY(TO_DATE(RecordDate2)) AS event_dt -- Extracts day value (1-31)
FROM brighttv.analytics.viewership;


---Creating TEMPORARY table called 'clean_viwership' with clean/processed vieweriship result- to help us analyze veiwing patterns/trends


----------------------------------------------------------------------------------------
-- Creating a temporary table for the final cleaned viewership data
----------------------------------------------------------------------------------------

CREATE OR REPLACE TEMPORARY TABLE Final_cleaned_viewership AS

--CTE 1: Preparing the base viewership data by standardising the user ID,converting timestamps from UTC to South African time, and
--cleaning the duration column for further transformations.
WITH base_viewership AS (
    SELECT
        COALESCE(UserID0, UserID4) AS userid,
        RecordDate2,

        -- Converting UTC timestamp to South African time
        FROM_UTC_TIMESTAMP(
            RecordDate2,
            'Africa/Johannesburg'
        ) AS RecordDate_SAST,

        Channel2,

        -- Renaming Duration 2 because the original column contains a space
        `Duration 2` AS Duration_2

    FROM brighttv.analytics.viewership
),
-- CTE 2: Creating the cleaned viewership dataset by adding date and time attributes, classifying viewing periods, standardising channel names,calculating viewing duration, and creating screen-time categories.
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
        Duration_2,

        -- Converting duration into time format
        DATE_FORMAT(
            Duration_2,
            'HH:mm:ss'
        ) AS Duration,

        -- Converting duration into total hours
        (
            HOUR(Duration_2)
            + MINUTE(Duration_2) / 60.0
            + SECOND(Duration_2) / 3600.0
        ) AS Duration_hours,

        -- Converting duration into total seconds
        (
            HOUR(Duration_2) * 3600
            + MINUTE(Duration_2) * 60
            + SECOND(Duration_2)
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
-- Creating the final cleaned viewership table from all transformations performed in the previous CTEs.
SELECT *
FROM cleaned_Viewership;

-- Checking sample records from the final cleaned viewership table
SELECT *
FROM Final_cleaned_viewership
LIMIT 10;

-- Checking the number of records in the final cleaned viewership table
SELECT COUNT(*) AS total_records---1000
FROM Final_cleaned_viewership;




----------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE clean_viewership AS (
SELECT 
    COUNT(DISTINCT userID0) AS number_of_subs,--counting number of subscribers
    RecordDate2,
    TO_DATE (RecordDate2) AS watch_date, --converts a string into a date YYYY-MM-DD
    DAYNAME(TO_DATE (RecordDate2)) AS day_name, -- extract the day of the week name
        CASE 
            WHEN DAYNAME(TO_DATE (RecordDate2))  IN ('Sat', 'Sun') THEN '02.Weekend'
            ELSE '01.Weekday'
        END AS Day_classification,
    MONTHNAME(TO_DATE (RecordDate2)) AS month_name, --extracts the month name
    YEAR(TO_DATE (RecordDate2)) AS event_year,-- extracts the year
    DAY(TO_DATE (RecordDate2)) AS event_dt-- extracts the day value
    FROM brighttv.analytics.viewership
    WHERE userID0 IS NOT NULL
    GROUP BY ALL
    ORDER BY watch_date DESC);

----This shows me the output of the NEW viewership table (temp table-clean_viewership) created from the code above NOT the original viewership table
SELECT *
FROM clean_viewership;

--How many subs are watching weekdays and weekends
SELECT SUM(number_of_subs) AS subs,
       Day_classification
FROM clean_viewership
GROUP BY Day_classification;


