-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse;
GO

/*
===================================
TESTS FOR DIMENSION TABLES
===================================
*/

/*
===================================
Quality checks for 'dim_agencies'
===================================
*/

-- Ensure there are no nulls in the possible columns
-- EXPECT: No results
SELECT * FROM gold.dim_agencies
WHERE
    agency_key IS NULL OR
    agency_id IS NULL OR
    agency_name IS NULL OR
    agency_url IS NULL OR
    timezone_country IS NULL OR
    timezone_city IS NULL;
GO

-- Ensure all the agencies listed in silver.agency are covered
-- EXPECT: Equal numbers in both queries
SELECT COUNT(agency_key) FROM gold.dim_agencies;
SELECT COUNT(agency_id) FROM silver.agency;
GO

/*
===================================
Quality checks for 'dim_routes'
===================================
*/

-- Ensure there are no nulls in the possible columns
-- EXPECT: No results
SELECT * FROM gold.dim_routes
WHERE
    route_key IS NULL OR
    route_id IS NULL OR
    bus_line IS NULL OR
	bus_branch IS NULL OR
    route_description IS NULL;
GO

-- Ensure all the routes listed in silver.routes are covered
-- EXPECT: Equal numbers in both queries
SELECT COUNT(route_key) FROM gold.dim_routes;
SELECT COUNT(route_id) FROM silver.routes;
GO

/*
===================================
Quality checks for 'dim_markers'
===================================
*/

-- Ensure there are no nulls in the possible columns
-- EXPECT: No results
SELECT * FROM gold.dim_markers
WHERE
    marker_key IS NULL OR
    route_key IS NULL OR
    route_direction IS NULL OR
    marker_ordinal IS NULL OR
    marker_lat IS NULL OR
    marker_lon IS NULL;
GO

-- Ensure all the routes listed in silver.routes are covered
-- EXPECT: Equal numbers in both queries
SELECT COUNT(DISTINCT route_key) FROM gold.dim_markers;
SELECT COUNT(route_id) FROM silver.routes;
GO

/*
===================================
TESTS FOR FACT TABLES
===================================
*/

/*
===================================
Quality checks for 'fact_services'
===================================
*/

-- Ensure there are no nulls in the possible columns
-- EXPECT: No results
SELECT * FROM gold.fact_services
WHERE
    route_key IS NULL OR
    agency_key IS NULL OR
    service_type IS NULL OR
    service_trips IS NULL;
GO

-- Ensure the number of trips per service is correct, taking route_id 143 as test case
-- EXPECT: Equal numbers in both queries
SELECT
    sv.service_type,
    COUNT(t.trip_id)
FROM silver.trips AS t
INNER JOIN (
    SELECT DISTINCT service_id, service_type
    FROM silver.calendar_dates
) AS sv
    ON t.service_id = sv.service_id
WHERE route_id = 143
GROUP BY t.route_id, sv.service_type
ORDER BY sv.service_type;

SELECT
    service_type,
    service_trips
FROM gold.fact_services AS sv
INNER JOIN gold.dim_routes AS r
    ON sv.route_key = r.route_key
WHERE r.route_id = 143
ORDER BY service_type;
GO

/*
===================================
Quality checks for 'fact_performance'
===================================
*/

-- Ensure there are no nulls in the possible columns
-- EXPECT: No results
SELECT * FROM gold.fact_performance
WHERE
    route_key IS NULL OR
    agency_key IS NULL OR
    route_trips IS NULL OR
	route_avg_distance IS NULL OR
	route_avg_stops IS NULL OR
	route_avg_time IS NULL;
GO

-- Ensure all the routes listed in silver.routes are covered
-- EXPECT: Equal numbers in both queries
SELECT COUNT(DISTINCT route_key) FROM gold.fact_performance;
SELECT COUNT(route_id) FROM silver.routes;
GO

-- Ensure data consistency for route average statistics among each distinct route entry
-- EXPECT: No results
SELECT 
	route_key,
	COUNT(DISTINCT route_avg_distance) AS distances,
	COUNT(DISTINCT route_avg_stops) AS stops,
	COUNT(DISTINCT route_avg_time) AS times
FROM gold.fact_performance
GROUP BY route_key
HAVING 
    COUNT(DISTINCT route_avg_distance) > 1 OR
    COUNT(DISTINCT route_avg_stops) > 1 OR
    COUNT(DISTINCT route_avg_time) > 1;
GO

-- Ensure the number of route trips is correct, taking route_id 143 as test case
-- EXPECT: Equal numbers for each service type in both queries
SELECT
	COUNT(*) AS route_trips
FROM silver.trips
WHERE route_id = 143;

SELECT route_trips
FROM gold.fact_performance AS fp
INNER JOIN gold.dim_routes AS r 
    ON fp.route_key = r.route_key
WHERE r.route_id = 143;
GO

-- Ensure the average route distance is correct, taking route_id 143 as test case with one random trip per direction
-- EXPECT: Equal numbers in both queries
WITH distances_cte AS (
    SELECT
        t.trip_id,
        MAX(s.shape_dist_traveled) as max_distance
    FROM silver.trips AS t
    INNER JOIN silver.shapes AS s
        ON t.shape_id = s.shape_id
    WHERE t.trip_id IN ('227939-1', '228047-1')
    GROUP BY t.trip_id
)
SELECT 
    FLOOR(AVG(max_distance))
FROM distances_cte;

SELECT DISTINCT route_avg_distance
FROM gold.fact_performance AS fp
INNER JOIN gold.dim_routes AS r 
    ON fp.route_key = r.route_key
WHERE r.route_id = 143;
GO

-- Ensure the average number of route stops is correct, taking route_id 143 as test case with one random trip per direction
-- EXPECT: Equal numbers in both queries
WITH stops_cte AS (
    SELECT 
        t.trip_id,
        COUNT(st.stop_id) AS num_of_stops
    FROM silver.trips AS t
    INNER JOIN silver.stop_times AS st
        ON t.trip_id = st.trip_id
    WHERE t.trip_id IN ('125448-1', '228109-1')
    GROUP BY t.trip_id
)
SELECT
    AVG(num_of_stops)
FROM stops_cte;

SELECT DISTINCT route_avg_stops
FROM gold.fact_performance AS fp
INNER JOIN gold.dim_routes AS r 
    ON fp.route_key = r.route_key
WHERE r.route_id = 143;
GO

-- Ensure the average route time is correct, taking route_id 143 as test case with one random trip per direction and service
-- EXPECT: Equal numbers in both queries
WITH trip_times AS (
	SELECT
		trip_id,
		MIN(arrival_time) AS start_time,
		MAX(arrival_time) AS end_time
	FROM silver.stop_times
	WHERE trip_id IN (
        '125371-1', '125517-1', '14209-1', '14379-1', -- Direction 0
	    '227827-1', '228039-1', '366269-1', '366372-1' -- Direction 1
    )
	GROUP BY trip_id
)
SELECT
	AVG(gold.gtfs_time_gap(start_time, end_time))
FROM trip_times;

SELECT DISTINCT route_avg_time
FROM gold.fact_performance AS fp
INNER JOIN gold.dim_routes AS r 
    ON fp.route_key = r.route_key
WHERE r.route_id = 143;