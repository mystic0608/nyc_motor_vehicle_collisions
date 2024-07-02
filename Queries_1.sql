USE who;

-- Preparing table for bulk insert command
DROP TABLE IF EXISTS dbo.Motor_Vehicle_Collisions
CREATE TABLE Motor_Vehicle_Collisions (
	[CRASH_DATE] DATE NULL,
	[CRASH_TIME] TIME(7) NULL,
	[BOROUGH] VARCHAR(50) NULL,
	[ZIP_CODE] SMALLINT NULL,
	[LATITUDE] DECIMAL(8,5) NULL,
	[LONGITUDE] DECIMAL(9,6) NULL,
	[LOCATION] VARCHAR(50) NULL,
	[ON_STREET_NAME] VARCHAR(50) NULL,
	[CROSS_STREET_NAME] VARCHAR(50) NULL,
	[OFF_STREET_NAME] VARCHAR(50) NULL,
	[NUMBER_OF_PERSONS_INJURED] TINYINT NULL,
	[NUMBER_OF_PERSONS_KILLED] TINYINT NULL,
	[NUMBER_OF_PEDESTRIANS_INJURED] TINYINT NULL, 
	[NUMBER_OF_PEDESTRIANS_KILLED] TINYINT NULL,
	[NUMBER_OF_CYCLIST_INJURED] TINYINT NULL,
	[NUMBER_OF_CYCLIST_KILLED] TINYINT NULL,
	[NUMBER_OF_MOTORIST_INJURED] TINYINT NULL,
	[NUMBER_OF_MOTORIST_KILLED] TINYINT NULL,
	[CONTRIBUTING_FACTOR_VEHICLE_1] VARCHAR(MAX) NULL,
	[CONTRIBUTING_FACTOR_VEHICLE_2] VARCHAR(MAX) NULL,
	[CONTRIBUTING_FACTOR_VEHICLE_3] VARCHAR(MAX) NULL,
	[CONTRIBUTING_FACTOR_VEHICLE_4] VARCHAR(MAX) NULL,
	[CONTRIBUTING_FACTOR_VEHICLE_5] VARCHAR(MAX) NULL,
	[COLLISION_ID] INT NOT NULL PRIMARY KEY,
	[VEHICLE_TYPE_CODE_1] VARCHAR(50) NULL,
	[VEHICLE_TYPE_CODE_2] VARCHAR(50) NULL,
	[VEHICLE_TYPE_CODE_3] VARCHAR(50) NULL,
	[VEHICLE_TYPE_CODE_4] VARCHAR(50) NULL,
	[VEHICLE_TYPE_CODE_5] VARCHAR(50) NULL
);

-- Using bulk insert command due to large file size
BULK INSERT Motor_Vehicle_Collisions
FROM "C:\Users\mysti\OneDrive\Documents\SQL Projects\NYC_Vehicle_Collisions\Motor_Vehicle_Collisions_-_Crashes_20240613.csv"
WITH (FORMAT = 'CSV'
	  , FIRSTROW = 2
	  , FIELDTERMINATOR = ','
	  , ROWTERMINATOR = '0x0a');


-- Identifying any duplicate records. None found
WITH duplicates AS (
SELECT 
		CRASH_DATE,
		CRASH_TIME,
		BOROUGH,
		ZIP_CODE,
		LATITUDE,
		LONGITUDE,
		ON_STREET_NAME,
		CROSS_STREET_NAME,
		OFF_STREET_NAME,
		NUMBER_OF_PERSONS_INJURED,
		NUMBER_OF_PERSONS_KILLED,
		NUMBER_OF_PEDESTRIANS_INJURED,
		NUMBER_OF_PEDESTRIANS_KILLED,
		NUMBER_OF_CYCLIST_INJURED,
		NUMBER_OF_CYCLIST_KILLED,
		NUMBER_OF_MOTORIST_INJURED,
		NUMBER_OF_MOTORIST_KILLED,
		CONTRIBUTING_FACTOR_VEHICLE_1,
		CONTRIBUTING_FACTOR_VEHICLE_2,
		CONTRIBUTING_FACTOR_VEHICLE_3,
		CONTRIBUTING_FACTOR_VEHICLE_4,
		CONTRIBUTING_FACTOR_VEHICLE_5,
		COLLISION_ID,
		VEHICLE_TYPE_CODE_1,
		VEHICLE_TYPE_CODE_2,
		VEHICLE_TYPE_CODE_3,
		VEHICLE_TYPE_CODE_4,
		VEHICLE_TYPE_CODE_5,
ROW_NUMBER() OVER(
	PARTITION BY 
		CRASH_DATE,
		CRASH_TIME,
		BOROUGH,
		ZIP_CODE,
		LATITUDE,
		LONGITUDE,
		ON_STREET_NAME,
		CROSS_STREET_NAME,
		OFF_STREET_NAME,
		NUMBER_OF_PERSONS_INJURED,
		NUMBER_OF_PERSONS_KILLED,
		NUMBER_OF_PEDESTRIANS_INJURED,
		NUMBER_OF_PEDESTRIANS_KILLED,
		NUMBER_OF_CYCLIST_INJURED,
		NUMBER_OF_CYCLIST_KILLED,
		NUMBER_OF_MOTORIST_INJURED,
		NUMBER_OF_MOTORIST_KILLED,
		CONTRIBUTING_FACTOR_VEHICLE_1,
		CONTRIBUTING_FACTOR_VEHICLE_2,
		CONTRIBUTING_FACTOR_VEHICLE_3,
		CONTRIBUTING_FACTOR_VEHICLE_4,
		CONTRIBUTING_FACTOR_VEHICLE_5,
		COLLISION_ID,
		VEHICLE_TYPE_CODE_1,
		VEHICLE_TYPE_CODE_2,
		VEHICLE_TYPE_CODE_3,
		VEHICLE_TYPE_CODE_4,
		VEHICLE_TYPE_CODE_5
	ORDER BY (SELECT 0)
	) AS row_num
FROM dbo.Motor_Vehicle_Collisions)
SELECT *
FROM duplicates
WHERE row_num > 1

-- Identifying all latitude and longitude column nulls. 234,947 records found
SELECT 
	*
FROM 
	dbo.Motor_Vehicle_Collisions
WHERE 
	LATITUDE IS NULL OR LONGITUDE IS NULL;

-- Identifying how many crashes per year
SELECT 
	DATEPART(year, CRASH_DATE) AS yr,
	COUNT(*) AS crashes_per_year
FROM 
	dbo.Motor_Vehicle_Collisions
GROUP BY DATEPART(year, CRASH_DATE)

-- Data from 2012-07-01 to 2024-06-09
SELECT MIN(CRASH_DATE) AS first_crash_date, MAX(CRASH_DATE) AS last_crash_date
FROM dbo.Motor_Vehicle_Collisions;

-- Identifying vehicle crashes per borough. 651,906 NULL boroughs found. Highest crashes in Brooklyn while the lowest by far is Staten Island
SELECT 
	COUNT(*) AS crashes_per_borough, COALESCE(borough, 'Unknown') AS borough
FROM 
	dbo.Motor_Vehicle_Collisions
GROUP BY 
	BOROUGH
ORDER BY 
	crashes_per_borough DESC;



-- 239,456 records found with invalid coordinates. Using a subquery amd UNION command to join both tables with NULL values or 0 values
SELECT 
    COUNT(*) AS total_invalid_coordinates
FROM (
    SELECT 
        *
    FROM 
        dbo.Motor_Vehicle_Collisions
    WHERE 
        LATITUDE = 0 OR LONGITUDE = 0

    UNION ALL

    SELECT
        *
    FROM
        dbo.Motor_Vehicle_Collisions
    WHERE
        LATITUDE IS NULL OR LONGITUDE IS NULL
) AS combined_invalid_coordinates;


/** I'm adding an error column to address some of the NULL values found in BOROUGH values, lat/long values not within NYC
boundaires or have 0 values **/
ALTER TABLE dbo.Motor_Vehicle_Collisions
ADD error INT;

UPDATE dbo.Motor_Vehicle_Collisions
SET error = 
	CASE WHEN BOROUGH IS NULL 
		AND (LATITUDE NOT BETWEEN 40.4774 AND 40.9176
              OR LONGITUDE NOT BETWEEN -74.2556 AND -73.7004 
			  OR LATITUDE IS NULL OR LONGITUDE IS NULL
              OR LATITUDE = 0 OR LONGITUDE = 0) THEN 1
	ELSE 0
END;
		

/** I have confirmed all values in the error column in this query are assigned a value of 1 **/
SELECT 
	*
FROM 
	dbo.Motor_Vehicle_Collisions
WHERE 
	BOROUGH IS NULL 
    AND (LATITUDE NOT BETWEEN 40.4774 AND 40.9176
    OR LONGITUDE NOT BETWEEN -74.2556 AND -73.7004 
    OR LATITUDE = 0 OR LONGITUDE = 0)
ORDER BY 
	LATITUDE DESC, LONGITUDE ASC;

/** In the queries below, I am attempting to update all NULL values for the Borough column with records that have existing Lat and Long
values. Because some coordinates could overlap with some boroughs, I am first finding the center coordinates for each borough and
then updating the NULL borough values based on their euclidean distance from each borough. **/

-- This first CTE will act as an anchor and initialize the 5 different boroughs as well as the center coordinates for each.
WITH BoroughCenters AS (
    SELECT 'Manhattan' AS Borough, 40.7831 AS CenterLat, -73.9712 AS CenterLong UNION ALL
    SELECT 'Brooklyn', 40.6782, -73.9442 UNION ALL
    SELECT 'Queens', 40.7282, -73.7949 UNION ALL
    SELECT 'Bronx', 40.8448, -73.8648 UNION ALL
	SELECT 'Staten Island', 40.5795, -74.1502
), 
/** This next CTE will select all the relevant columns, calculate the euclidean distance based on center longitude and latitude coordinates.
Then they will be ranked by assigning a row number based on the formula. It will then cross join the initial CTE table and compare distances
for each borough. **/
BoroughDistances AS (
	SELECT
		mvc.LATITUDE AS Lat,
		mvc.LONGITUDE AS Long,
		bc.Borough,
		SQRT(POWER(mvc.LATITUDE - bc.CenterLat, 2) + POWER(mvc.LONGITUDE - bc.CenterLong, 2)) AS Distance,
		ROW_NUMBER() OVER (PARTITION BY mvc.LATITUDE, mvc.LONGITUDE ORDER BY SQRT(POWER(mvc.LATITUDE - bc.CenterLat, 2) + POWER(mvc.LONGITUDE - bc.CenterLong, 2))) AS RowNum
	FROM dbo.Motor_Vehicle_Collisions AS mvc
	CROSS JOIN BoroughCenters bc
	WHERE mvc.BOROUGH IS NULL AND (LATITUDE IS NOT NULL AND LONGITUDE IS NOT NULL)
), 
-- This CTE is selecting the closest boroughs based on the ranking logic
ClosestBoroughs AS (
	SELECT
	Lat,
	Long,
	Borough
	From BoroughDistances
	WHERE RowNum = 1 
)
/** Our update statement is setting a new borough value for each NULL value found that has an existing Lat and Long coordinates.
In total, 452,919 rows were updated. 198,987 records currently have NULL boroughs or NULL latitude/longitude values. **/
UPDATE mvc
SET mvc.borough = cb.borough
FROM dbo.Motor_Vehicle_Collisions AS mvc
INNER JOIN ClosestBoroughs AS cb
	ON mvc.LATITUDE = cb.Lat AND mvc.LONGITUDE = cb.Long
WHERE mvc.BOROUGH IS NULL AND Lat > 0 AND Long < 0;


/** Here I am identifying the peak hours of when collisions happen. Unsurprisingly, the top # of collisions happen during rush hour when most people are on the road. **/
SELECT 
	DATEPART(hour, CRASH_TIME) AS crash_hour,
	COUNT(*) AS no_of_collissions
FROM 
	dbo.Motor_Vehicle_Collisions
GROUP BY
	DATEPART(hour, CRASH_TIME)
ORDER BY
	no_of_collissions DESC;

/** In this query I have indentified that friday has the highest # of motor vehicle collisions **/
SELECT 
	DATEPART(WEEKDAY, CRASH_DATE) AS day_of_week,
	COUNT(*) AS no_of_collissions
FROM 
	dbo.Motor_Vehicle_Collisions
GROUP BY
	DATEPART(WEEKDAY, CRASH_DATE)
ORDER BY
	no_of_collissions DESC;

/** It's a common assumption that winter should have the highest # of car collisions due to hazaradous weather. However, that's also the reason why there is less
traffic on the road and why Fall is the highest season for car collisions.  **/
WITH crashes_per_month AS(
	SELECT 
		DATEPART(MONTH, CRASH_DATE) AS month_of_year, 
		COUNT(*) AS CollisionCount
	FROM 
		dbo.Motor_Vehicle_Collisions
	GROUP BY 
		DATEPART(MONTH, CRASH_DATE)
)
SELECT
    'Winter' AS Season,
    SUM(CASE
        WHEN month_of_year IN (12, 1, 2) THEN CollisionCount 
        ELSE 0 
    END) AS TotalCollisions
FROM 
    crashes_per_month
UNION ALL
SELECT
    'Spring' AS Season,
    SUM(CASE
        WHEN month_of_year IN (3, 4, 5) THEN CollisionCount 
        ELSE 0 
    END) AS TotalCollisions
FROM 
    crashes_per_month
UNION ALL
SELECT
    'Summer' AS Season,
    SUM(CASE
        WHEN month_of_year IN (6, 7, 8) THEN CollisionCount 
        ELSE 0 
    END) AS TotalCollisions
FROM 
    crashes_per_month
UNION ALL
SELECT
    'Fall' AS Season,
    SUM(CASE
        WHEN month_of_year IN (9, 10, 11) THEN CollisionCount 
        ELSE 0 
    END) AS TotalCollisions
FROM 
    crashes_per_month;

/** Expanding on the query above, we know that Fall has the highest # of collisions and Winter being the lowest. I now want to go deeper and see how severe these car collisions
vary by season. This confirms a few assumptions we had in the prior query. Some variables that could affect increased traffic volume: weather conditions, behavioral factors,
daylight/visibility, seasonal events, and more interestingly pedestrian and cyclist activity. In this data we see more pedestrians are injured/killed in Winter comparatively to
Summer and less cyclists injured/killed in Winter. Without deeper analysis, one could likely assume more pedestrians walking because people would opt to travel by walking 
for short distances rather than rely on delayed public transporatation or hazardous road conditions. The drop in cyclists injured/killed in Winter seems pretty straight forward.
 Cyclists tend to prefer better riding conditions and therefore less of them are cycling in the winter. **/
WITH Seasonal_Months AS (
	SELECT 
		CRASH_DATE,
		NUMBER_OF_PERSONS_INJURED,
		NUMBER_OF_PERSONS_KILLED,
		NUMBER_OF_PEDESTRIANS_INJURED,
		NUMBER_OF_PEDESTRIANS_KILLED,
		NUMBER_OF_CYCLIST_INJURED,
		NUMBER_OF_CYCLIST_KILLED,
		NUMBER_OF_MOTORIST_INJURED,
		NUMBER_OF_MOTORIST_KILLED,
		CASE 
			WHEN DATEPART(MONTH, CRASH_DATE) IN (12, 1, 2) THEN 'Winter' 
			WHEN DATEPART(MONTH, CRASH_DATE) IN (3, 4, 5) THEN 'Srping' 
			WHEN DATEPART(MONTH, CRASH_DATE) IN (6, 7, 8) THEN 'Summer' 
			WHEN DATEPART(MONTH, CRASH_DATE) IN (9, 10, 11) THEN 'Fall' 
			ELSE 'Unknown'
		END AS Season
	FROM 
		dbo.Motor_Vehicle_Collisions
)
SELECT 
	SUM(NUMBER_OF_PERSONS_INJURED) AS persons_injured,
	SUM(NUMBER_OF_PERSONS_KILLED) AS persons_killed,
	SUM(NUMBER_OF_PEDESTRIANS_INJURED) AS pedestrians_injured,
	SUM(NUMBER_OF_PEDESTRIANS_KILLED) AS pedestrians_killed,
	SUM(NUMBER_OF_CYCLIST_INJURED) AS cyclicst_injured,
	SUM(NUMBER_OF_CYCLIST_KILLED) AS cyclist_killed,
	SUM(NUMBER_OF_MOTORIST_INJURED) AS motorist_injured,
	SUM(NUMBER_OF_MOTORIST_KILLED) AS motorist_killed,
	SUM(NUMBER_OF_PERSONS_INJURED + NUMBER_OF_PEDESTRIANS_INJURED + NUMBER_OF_CYCLIST_INJURED + NUMBER_OF_MOTORIST_INJURED + NUMBER_OF_MOTORIST_INJURED) AS total_injured,
	SUM(NUMBER_OF_PERSONS_KILLED + NUMBER_OF_PEDESTRIANS_KILLED + NUMBER_OF_CYCLIST_KILLED + NUMBER_OF_MOTORIST_KILLED + NUMBER_OF_MOTORIST_KILLED) AS total_killed,
	Season
FROM 
	Seasonal_Months
GROUP BY 
	Season
ORDER BY
	total_injured DESC, 
	total_killed DESC;


/** In this query we can see that Brooklyn has the highest # of collisions. **/
WITH Collisions_By_Borough AS (
	SELECT
		BOROUGH,
		COUNT(*) AS total_collisions
	FROM 
		dbo.Motor_Vehicle_Collisions
	WHERE
		BOROUGH IS NOT NULL
	GROUP BY 
		BOROUGH
)
SELECT
	BOROUGH,
	total_collisions,
	RANK() OVER(ORDER BY total_collisions DESC) AS rnk
FROM Collisions_By_Borough;

/** Taking a closer look at Brooklyn, I want to identify if there are any reoccuring street names. I have identified Atlantic Avenue as being the highest collision rate by street.
**/
SELECT
	ON_STREET_NAME,
	COUNT(*) AS crashes_cnt,
	CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS decimal(5,2)) AS percentage_of_total
FROM
	dbo.Motor_Vehicle_Collisions
WHERE
	BOROUGH = 'BROOKLYN' AND ON_STREET_NAME IS NOT NULL
GROUP BY
	ON_STREET_NAME
ORDER BY
	crashes_cnt DESC


/** In this query it is apparent that the #1 contributing factor leading to injuries/deaths is due to driver distractions. **/
SELECT 
    CONTRIBUTING_FACTOR_VEHICLE_1,
    COUNT(*) AS total_collisions,
    SUM(NUMBER_OF_PERSONS_INJURED) AS total_injuries,
    SUM(NUMBER_OF_PERSONS_KILLED) AS total_deaths
FROM 
    dbo.Motor_Vehicle_Collisions
WHERE
	CONTRIBUTING_FACTOR_VEHICLE_1 NOT IN ('Unspecified')
GROUP BY 
    CONTRIBUTING_FACTOR_VEHICLE_1
ORDER BY 
    Total_Collisions DESC;

/** In this query I am identifying the highest percentage of injuries and deaths by collision per borough. Interestingly enough, brooklyn has the highest # of collisions but
the Bronx has a higher injury and fatality rate. **/
SELECT
	BOROUGH,
	SUM(NUMBER_OF_PERSONS_INJURED) * 1.0 / COUNT(*) AS avg_injured_by_collision,
	SUM(NUMBER_OF_PERSONS_KILLED) * 1.0 / COUNT(*) AS avg_killed_by_collision
FROM
	dbo.Motor_Vehicle_Collisions
WHERE
	BOROUGH IS NOT NULL
GROUP BY
	BOROUGH
ORDER BY
	avg_injured_by_collision DESC,
	avg_killed_by_collision DESC