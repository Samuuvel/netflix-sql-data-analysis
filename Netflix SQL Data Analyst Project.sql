CREATE DATABASE netflix_project;
USE netflix_project;

CREATE TABLE netflix_titles (
show_id VARCHAR(10),
type VARCHAR(20),
title VARCHAR(255),
director VARCHAR(255),
cast TEXT,
country VARCHAR(100),
date_added VARCHAR(50),
release_year INT,
rating VARCHAR(20),
duration VARCHAR(20),
listed_in VARCHAR(255),
description TEXT);

select * from netflix_titles;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/netflix_titles.csv"
INTO TABLE netflix_titles
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

ALTER TABLE netflix_titles MODIFY country VARCHAR(255);

-- DATA VALIDATION 

-- STEP1 - Row Count Validationn - First I confirmed the dataset size.

SELECT COUNT(*) FROM netflix_titles;

-- STEP2 Checking for Missing Values - This helps identify missing data.

SELECT COUNT(*)FROM netflix_titles WHERE show_id IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE title IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE type IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE director IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE cast IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE country IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE date_added IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE release_year IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE rating IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE duration IS NULL;
SELECT COUNT(*)FROM netflix_titles WHERE listed_in IS NULL;

-- STEP 3 - Checking Empty Strings - Sometimes data is not NULL but empty.

SELECT

SUM(show_id IS NULL OR TRIM(show_id)='') AS missing_show_id,
SUM(type IS NULL OR TRIM(type)='') AS missing_type,
SUM(title IS NULL OR TRIM(title)='') AS missing_title,
SUM(director IS NULL OR TRIM(director)='') AS missing_director,
SUM(`cast` IS NULL OR TRIM(`cast`)='') AS missing_cast,
SUM(country IS NULL OR TRIM(country)='') AS missing_country,
SUM(date_added IS NULL OR TRIM(date_added)='') AS missing_date_added,
SUM(release_year IS NULL) AS missing_release_year,
SUM(rating IS NULL OR TRIM(rating)='') AS missing_rating,
SUM(duration IS NULL OR TRIM(duration)='') AS missing_duration,
SUM(listed_in IS NULL OR TRIM(listed_in)='') AS missing_listed_in,
SUM(description IS NULL OR TRIM(description)='') AS missing_description,
SUM(date_added_clean IS NULL OR TRIM(date_added_clean)='') As Missing_date_added_clean

FROM netflix_titles;

-- STEP 4 - Replace Empty Strings (Keep NULL OR Replace value OR Remove row)

UPDATE netflix_titles SET director = Null WHERE TRIM(director)='';
UPDATE netflix_titles SET cast = 'Unknown' WHERE TRIM(cast)='';
UPDATE netflix_titles SET country = 'Unknown' WHERE TRIM(country)='';
UPDATE netflix_titles SET date_added = Null WHERE TRIM(date_added)='';
UPDATE netflix_titles SET rating = 'Not Rated' WHERE TRIM(rating)='';
UPDATE netflix_titles SET duration = 'Null' WHERE TRIM(duration)='' ;
UPDATE netflix_titles SET date_added_clean = 'Null' WHERE TRIM(date_added_clean)='' ;

-- STEP 5 Check for duplicate records

SELECT show_id, title, director, cast, country, date_added, release_year, rating, duration, listed_in, description, type, 
COUNT(*) AS cnt
FROM netflix_titles
GROUP BY show_id, title, director, cast, country, date_added, release_year, rating, duration, listed_in, description, type
HAVING cnt > 1;

-- STEP 6 Covert date column to proper SQL Date if it is not proper

ALTER TABLE netflix_titles ADD date_added_clean DATE;
UPDATE netflix_titles
SET date_added_clean = STR_TO_DATE(date_added, '%M %d, %Y')
WHERE TRIM(date_added) <> '';

-- STEP 7 Start Exploratory Data Analysis (EDA)

-- 1 . Content Type Distribution -- This shows the distribution of content.

SELECT type, COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY type;

/*Insight - Usually Movies dominate Netflix catalog.

Business meaning - Netflix invests more in movie content acquisition. */

-- 2 . Country Dominance Analysis

SELECT country, COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_titles DESC
LIMIT 10 ;

/* Insight - The United States dominates the content library ,but international marks like india and Uk 
are emerging contributors indicating netflix's localization strategy */

-- 3 . Content Growth Trend (Platform expansion )

SELECT YEAR ( date_added_clean) As Year_added,
COUNT(*) As Titles_added
from netflix_titles
Where date_added_clean IS NOT NULL
GROUP BY Year_added
ORDER BY Year_added;

/* Insight - Netflix Contents additions increased sharply after 2016, which aligns with the comnpany,s global expansion 
and investment in orginal content.*/

-- 4 . Audience Targeting Strategy

SELECT rating , Count(*) As Total_Titles
from netflix_titles
GROUP BY rating
ORDER BY Total_Titles DESC;

/* Insight - The most common rating is TV- MA suggrsting netflix,s primarily targets mature audience
 rather than family conntent */

-- 5 . Genre Popularity Analysis

SELECT listed_in , COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP  BY listed_in
ORDER BY Total_titles DESC
LIMIT 10;

/*  Insight - Genres such as Drama,international movies and comedy dominate the platform indicating a strong demand for 
emotionally engaging and globally appealing storytelling*/

-- 6 . Movie Duration pattern (Advanced insight)

SELECT CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS Movie_length,
       COUNT(*) AS Total_movies
FROM netflix_titles
WHERE type = 'Movie'
  AND duration LIKE '%min'
GROUP BY Movie_length
ORDER BY Total_movies DESC
LIMIT 10;

/* Insights - The majority of netflix movies fall within the 90- 100 minute range,which aligns with 
viewer attention span and streaming consumption patterns*/

-- 7 .  Director Productivity Analysis

SELECT director, COUNT(*) AS Total_Titles
FROM netflix_titles
WHERE director IS NOT NULL
GROUP BY director
ORDER BY Total_Titles DESC
LIMIT 10;

/* Insight - A small group of driectors contributes a disproportionately large number of titles,
suggesting repeated collaborations between netflix and certain flim makers*/

-- 8 . Seasonal Release Strategy

SELECT MONTHNAME(date_added_clean) AS Month_Added,
       COUNT(*) AS Titles_Added
FROM netflix_titles
WHERE date_added_clean IS NOT NULL
GROUP BY Month_Added
ORDER BY Titles_Added DESC;

 /* Insight - Netflix tends to relese more titles in later months of the year ,
 likely aligning with holiday viewing spikes */

-- 9 . International Content Growth

SELECT country,
       type,
       COUNT(*) AS Titles_After_2018
FROM netflix_titles
WHERE release_year >= 2018
  AND country IS NOT NULL
  AND country <> 'Unknown'
GROUP BY country, type
ORDER BY Titles_After_2018 DESC
LIMIT 10;

/*Insights - Post-2018 international markets contributed significantly more content 
reflecting netflix's investment in global storytelling*/

-- 10 . Content Added Delay Analysis(Very impressive) - How long does netflix take to add content after it is released ?

SELECT AVG(YEAR(date_added_clean) - release_year) AS AVG_DELAY
FROM netflix_titles
WHERE date_added_clean IS NOT NULL;

/* Insight - On average ,netflix adds content 1 year after release*/
/*Business meaning - If delay is samll - Netflix focuses on new content 
                     If delay is high  - Netflix relies on old licensed content */
                     
                     
-- 11 . Movies vs TV Shows Growth Trend (Comparision Insights) - How did movies and TV Shows grow over Time?

SELECT YEAR(date_added_clean) AS year_added,
       type,
       COUNT(*) AS total_titles
FROM netflix_titles
WHERE date_added_clean IS NOT NULL
GROUP BY year_added, type
ORDER BY year_added;

/* Insight - Movies dominated early years ,but TV shows start increasing rapidly after 2016*/
/*Buiness meaning - Netflix is shifting towards series_based engagement(binge watching model)*/

-- 12 . Top Country Genre Combination (very advanced thinking) - Which country produces which type of content most?

SELECT country,
       listed_in,
       COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country, listed_in
ORDER BY total_titles DESC
LIMIT 10;

/* Insight - Diffrent countries specialize in diffrent genres
Example: -
India -> Drama/Romance
US -> Comedy/Action */

/* Business meaning - Netflix tailors content based on regional audience prefrences*/

-- 13 - Top 10 Countries with Percentage Share  

SELECT country,
       COUNT(*) AS total_titles,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) 
                                 FROM netflix_titles 
                                 WHERE country IS NOT NULL), 2) AS percentage_share
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_titles DESC
LIMIT 10;

/* Insights -  This breakdown shows how heavily Netflix’s catalog leans toward U.S. productions, but also highlights 
the growing influence of India and South Korea, especially with the rise of Bollywood films and K-dramas*/


