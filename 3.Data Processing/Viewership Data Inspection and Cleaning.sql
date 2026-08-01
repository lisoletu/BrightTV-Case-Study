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
