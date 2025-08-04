/*
========================================
Create procedure for loading silver data
========================================

This script creates the SQL procedure to load data from queries
using each table in the 'bronze' schema to insert data into the 
'silver' schema, ensuring proper formatting, columns, and data integrity.

Parameters:
	None

Start the procedure by running:

USE gtfswarehouse
EXEC silver.load_silver
*/

-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	-- Monitor total batch load duration (start)
	SET @batch_start_time = GETDATE();

	PRINT '=================================';
	PRINT 'Loading silver tables';
	PRINT '=================================';
	PRINT '';

		-- Truncate and load data into 'calendar_dates'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.calendar_dates';
		TRUNCATE TABLE silver.calendar_dates;

		PRINT '>> Populating table: silver.calendar_dates';
		INSERT INTO silver.calendar_dates (
			service_id,
			service_date,
			service_type
		)
		SELECT 
			service_id,
			CAST(date AS DATE) AS service_date,
			CASE WHEN service_id = 1 THEN 'Saturday'
				 WHEN service_id = 2 THEN 'Sunday'
				 WHEN service_id = 3 THEN 'Weekday'
				 WHEN service_id = 4 THEN 'Holiday'
				 ELSE 'N/A'
			END AS service_type
		FROM bronze.calendar_dates

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'trips'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.trips';
		TRUNCATE TABLE silver.trips;

		PRINT '>> Populating table: silver.trips';
		INSERT INTO silver.trips(
			route_id,
			service_id,
			trip_id,
			trip_headsign,
			direction_id,
			block_id,
			shape_id
		)
		SELECT
			route_id,
			service_id,
			trip_id,
			UPPER(TRIM('"' FROM trip_headsign)) AS trip_headsign,
			direction_id,
			TRIM('"' FROM block_id) AS block_id,
			shape_id
		FROM bronze.trips
	
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'routes'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.routes';
		TRUNCATE TABLE silver.routes;

		PRINT '>> Populating table: silver.routes';
		WITH routes_and_buses_cte AS (
			SELECT
				route_id,
				agency_id,
				CASE
					WHEN route_short_name NOT LIKE '%[0-9]%' OR route_short_name NOT LIKE '%[A-Z]%' -- Get full string
						THEN route_short_name
					WHEN route_short_name LIKE '[0-9]%'
						THEN LEFT(route_short_name, PATINDEX('%[A-Z]%', route_short_name)-1) -- Get digits before letters
					WHEN route_short_name LIKE '[A-Z]%'
						-- Additionally replace the 'OE' value with 'OESTE'
						THEN REPLACE(
						LEFT(route_short_name, PATINDEX('%[0-9]%', route_short_name)-1), -- Get letters before digits
						'OE', 'OESTE')
				END AS bus_line,
				CASE
					WHEN route_short_name LIKE '[0-9]%'
						-- Additionally replace the 'ENIE' value with 'Ñ'
						THEN REPLACE(
						RIGHT(route_short_name, LEN(route_short_name)-(PATINDEX('%[A-Z]%', route_short_name)-1)), -- Get last letters
						'ENIE', 'Ñ')
					ELSE RIGHT(route_short_name, LEN(route_short_name)-(PATINDEX('%[0-9]%', route_short_name)-1)) -- Get last digits or line in the lack thereof
				END AS bus_branch,
				route_long_name,
				route_desc
			FROM (
				SELECT
					CAST(TRIM('"' FROM route_id) AS INT) AS route_id,
					CAST(TRIM('"' FROM agency_id) AS INT) AS agency_id,
					UPPER(TRIM('"' FROM route_short_name)) AS route_short_name,
					UPPER(TRIM('"' FROM route_long_name)) AS route_long_name,
					UPPER(TRIM('"' FROM route_desc)) AS route_desc
				FROM bronze.routes
			) aux
		)
		INSERT INTO silver.routes (
			route_id,
			agency_id,
			bus_line,
			bus_branch,
			route_long_name,
			route_desc,
			route_scope
		)
		SELECT
			*,
			CASE
				WHEN ISNUMERIC(bus_line) = 1 AND CAST(bus_line AS INT) < 200 THEN 'Capital'
				WHEN ISNUMERIC(bus_line) = 1 AND CAST(bus_line AS INT) < 500 THEN 'Province'
				ELSE 'Municipality'
			END AS route_scope
		FROM routes_and_buses_cte

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'shapes'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.shapes';
		TRUNCATE TABLE silver.shapes;

		PRINT '>> Populating table: silver.shapes';
		INSERT INTO silver.shapes
		SELECT * FROM bronze.shapes
	
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'stop_times'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.stop_times';
		TRUNCATE TABLE silver.stop_times;

		PRINT '>> Populating table: silver.stop_times';
		INSERT INTO silver.stop_times
		SELECT 
			trip_id,
			arrival_time,
			stop_id,
			stop_sequence,
			shape_dist_traveled
		FROM bronze.stop_times
	
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'agency'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.agency';
		TRUNCATE TABLE silver.agency;

		PRINT '>> Populating table: silver.agency';
		WITH filtered_timezones_cte AS (
			SELECT
				*,
				-- Only the country and region info. is taken
				SUBSTRING(
					agency_timezone,
					CHARINDEX('/', agency_timezone) + 1,
					LEN(agency_timezone)
				) AS timezone_region
			FROM (
				SELECT 
					agency_id,
					TRIM('"' FROM agency_name) AS agency_name,
					TRIM('"' FROM agency_url) AS agency_url,
					TRIM('"' FROM agency_timezone) AS agency_timezone
				FROM bronze.agency
			) aux
		)
		INSERT INTO silver.agency (
			agency_id,
			agency_name,
			agency_url,
			timezone_country,
			timezone_city
		)
		SELECT 
			agency_id,
			agency_name,
			agency_url,
			SUBSTRING(
				timezone_region,
				1,
				CHARINDEX('/', timezone_region) - 1
			) AS timezone_country,
			REPLACE(
				SUBSTRING(
					timezone_region,
					CHARINDEX('/', timezone_region) + 1,
					LEN(timezone_region)
				), '_', ' ' -- Additionally replace underscores with spaces
			) AS timezone_city
		FROM filtered_timezones_cte

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

	-- Monitor total batch load duration (end)
	SET @batch_end_time = GETDATE();

	PRINT '';
	PRINT '=================================';
	PRINT '>> BATCH LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
	PRINT '=================================';
END