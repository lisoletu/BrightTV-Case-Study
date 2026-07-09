-- Databricks notebook source

---Telling Databricks to use the "brighttv" catalog and "analytics" schema---
USE brighttv.analytics;

---Running the full tables---
SELECT*
FROM user_profiles;

SELECT *
FROM viewership;

---GENDER CHECKS---
SELECT DISTINCT Gender
FROM user_profiles;

SELECT DISTINCT
    CASE
        WHEN Gender ='None' THEN 'Unknown' --Replaces the value "None" with "unknown"
        WHEN Gender =' ' THEN 'Unknown'--Replaces the empty space with "unknown"
    ELSE Gender -- if gender is male or female turn it as it is
    END AS Sex --new column name
FROM user_profiles;



