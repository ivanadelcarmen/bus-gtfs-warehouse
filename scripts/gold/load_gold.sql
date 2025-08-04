/*
======================================
Create procedure for loading gold data
======================================

This script creates the SQL procedure to load data from queries
using each table in the 'silver' schema to insert data into the 
'gold' schema, ensuring proper formatting, columns, and data 
integrity. Additionally, two temporary tables will be droped and 
recreated for populating the dependent tables.

RUN functions_gold.sql BEFORE LOADING THE PROCEDURE

Parameters:
	None

Start the procedure by running:

USE gtfswarehouse
EXEC gold.load_gold
*/

-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse;
GO

CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	-- Monitor total batch load duration (start)
	SET @batch_start_time = GETDATE();
		
	PRINT '=========================================';
	PRINT 'Loading temporary gold tables';
	PRINT '=========================================';
	PRINT '';
		
		SET @start_time = GETDATE();

		-- Create representative_trips_service temporary table
		IF OBJECT_ID('tempdb..#representative_trips_service') IS NOT NULL
			DROP TABLE #representative_trips_service;

		PRINT '>> Creating temporary table: #representative_trips_service';
		SELECT
			trip_id,
			route_id,
			shape_id,
			direction_id
		INTO #representative_trips_service
		FROM (
			SELECT
				trip_id,
				route_id,
				direction_id,
				shape_id,
				ROW_NUMBER() OVER (PARTITION BY route_id, direction_id, service_id ORDER BY trip_id) AS trip_rank
			FROM silver.trips
		) aux
		WHERE trip_rank = 1;

		-- Create representative_trips_direction temporary table
		IF OBJECT_ID('tempdb..#representative_trips_direction') IS NOT NULL
			DROP TABLE representative_trips_direction;

		PRINT '>> Creating temporary table: #representative_trips_direction';
		SELECT
			trip_id,
			route_id,
			direction_id,
			shape_id
		INTO #representative_trips_direction
		FROM (
			SELECT
				*,
				ROW_NUMBER() OVER (PARTITION BY route_id, direction_id ORDER BY trip_id) AS trip_rank
			FROM #representative_trips_service
		) aux
		WHERE trip_rank = 1

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================';
		PRINT '';

	PRINT '=========================================';
	PRINT 'Loading gold tables';
	PRINT '=========================================';
	PRINT '';
		
		-- Truncate and load data into dimension 'dim_agencies'
		SET @start_time = GETDATE();
		PRINT '>> Truncating dimension table: gold.dim_agencies';
		TRUNCATE TABLE gold.dim_agencies;

		PRINT '>> Populating dimension table: gold.dim_agencies';
		INSERT INTO gold.dim_agencies (
			agency_key,
			agency_id,
			agency_name,
			agency_url,
			timezone_country,
			timezone_city
		)
		SELECT
			ROW_NUMBER() OVER (ORDER BY agency_id) AS agency_key,
			*
		FROM silver.agency;

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================';

		-- Truncate and load data into dimension 'dim_routes'
		SET @start_time = GETDATE();
		PRINT '>> Truncating dimension table: gold.dim_routes';
		TRUNCATE TABLE gold.dim_routes;

		PRINT '>> Populating dimension table: gold.dim_routes';
		INSERT INTO gold.dim_routes (
			route_key,
			route_id,
			agency_id,
			bus_line,
			bus_branch,
			route_description,
			route_scope
		)
		SELECT
			ROW_NUMBER() OVER (ORDER BY route_id) AS route_key,
			route_id,
			agency_id,
			bus_line,
			bus_branch,
			route_desc AS route_description,
			route_scope
		FROM silver.routes;

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================';

		-- Create dimension gold.dim_markers
		SET @start_time = GETDATE();
		PRINT '>> Truncating dimension table: gold.dim_markers';
		TRUNCATE TABLE gold.dim_markers;

		PRINT '>> Populating dimension table: gold.dim_markers';
		INSERT INTO gold.dim_markers (
			marker_key,
			route_key,
			route_direction,
			marker_ordinal,
			marker_lat,
			marker_lon
		)
		SELECT
			ROW_NUMBER() OVER (ORDER BY r.route_key, t.direction_id, sh.shape_pt_sequence) AS marker_key,
			r.route_key,
			t.direction_id AS route_direction,
			sh.shape_pt_sequence AS marker_ordinal,
			sh.shape_pt_lat AS marker_lat,
			sh.shape_pt_lon AS marker_lon
		FROM #representative_trips_direction AS t
		INNER JOIN gold.dim_routes AS r
			ON t.route_id = r.route_id
		INNER JOIN silver.shapes AS sh
			ON t.shape_id = sh.shape_id;

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================';

		-- Create fact table gold.fact_services
		SET @start_time = GETDATE();
		PRINT '>> Truncating fact table: gold.fact_services';
		TRUNCATE TABLE gold.fact_services;

		PRINT '>> Populating fact table: gold.fact_services';
		INSERT INTO gold.fact_services (
			route_key,
			agency_key,
			service_type,
			service_trips
		)
		SELECT
			r.route_key,
			a.agency_key,
			svt.service_type,
			COUNT(svt.trip_id) AS service_trips
		FROM (
			SELECT
				t.trip_id,
				t.route_id,
				sv.service_type
			FROM silver.trips AS t
			INNER JOIN (
				SELECT DISTINCT service_type, service_id
				FROM silver.calendar_dates
			) AS sv
				ON t.service_id = sv.service_id
		) AS svt
		INNER JOIN gold.dim_routes AS r
			ON svt.route_id = r.route_id
		INNER JOIN gold.dim_agencies AS a
			ON r.agency_id = a.agency_id
		GROUP BY r.route_key, svt.service_type, a.agency_key

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================';

		-- Create fact table gold.fact_performance
		SET @start_time = GETDATE();
		PRINT '>> Truncating fact table: gold.fact_performance';
		TRUNCATE TABLE gold.fact_performance;

		PRINT '>> Populating fact table: gold.fact_performance';
		WITH average_distance_cte AS (
			SELECT
				route_id,
				FLOOR(AVG(max_trip_distance)) AS route_avg_distance
			FROM (
				SELECT
					rp.route_id,
					rp.trip_id,
					MAX(s.shape_dist_traveled) AS max_trip_distance
				FROM #representative_trips_direction AS rp
				INNER JOIN silver.shapes AS s
					ON rp.shape_id = s.shape_id
				GROUP BY rp.trip_id, rp.route_id
			) aux
			GROUP BY route_id
		),
		average_stops_cte AS (
			SELECT
				route_id,
				AVG(stops) AS route_avg_stops
			FROM (
				SELECT
					rp.route_id,
					rp.direction_id,
					COUNT(st.stop_id) AS stops
				FROM silver.stop_times AS st
				INNER JOIN #representative_trips_direction AS rp
					ON st.trip_id = rp.trip_id
				GROUP BY rp.route_id, rp.direction_id
			) aux
			GROUP BY route_id
		),
		average_time_cte AS (
			SELECT
				route_id,
				AVG(trip_time) AS route_avg_time
			FROM (
				SELECT
					rp.route_id,
					rp.direction_id,
					gold.gtfs_time_gap(times.start_time, times.end_time) AS trip_time
				FROM #representative_trips_service AS rp -- This temporary table is used due to differences in stop times between services
				INNER JOIN (
					SELECT
						trip_id,
						MIN(arrival_time) AS start_time,
						MAX(arrival_time) AS end_time
					FROM silver.stop_times
					GROUP BY trip_id 
				) AS times
					ON rp.trip_id = times.trip_id
			) aux
			GROUP BY route_id
		),
		total_trips_cte AS (
			SELECT
				route_key,
				SUM(service_trips) AS route_trips
			FROM gold.fact_services
			GROUP BY route_key
		)
		INSERT INTO gold.fact_performance (
			route_key,
			agency_key,
			route_trips,
			route_avg_distance,
			route_avg_stops,
			route_avg_time
		)
		SELECT
			r.route_key,
			a.agency_key,
			tt.route_trips,
			avgd.route_avg_distance,
			avgs.route_avg_stops,
			avgt.route_avg_time
		FROM gold.dim_routes AS r
		INNER JOIN gold.dim_agencies AS a
			ON r.agency_id = a.agency_id
		INNER JOIN average_distance_cte AS avgd
			ON r.route_id = avgd.route_id
		INNER JOIN average_stops_cte AS avgs
			ON r.route_id = avgs.route_id
		INNER JOIN average_time_cte AS avgt
			ON r.route_id = avgt.route_id
		INNER JOIN total_trips_cte AS tt
			ON r.route_key = tt.route_key;

		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================';

		-- Monitor total batch load duration (end)
	SET @batch_end_time = GETDATE();

	PRINT '';
	PRINT '=========================================';
	PRINT '>> BATCH LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
	PRINT '=========================================';
END