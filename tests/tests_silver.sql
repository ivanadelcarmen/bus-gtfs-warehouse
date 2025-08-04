-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse;
GO

/*
===================================
Quality checks for 'calendar_dates'
===================================
*/

-- Ensure the number of service_id unique elements is correct
-- EXPECT: 4
SELECT COUNT(DISTINCT service_id)
FROM silver.calendar_dates;
GO

-- Ensure there are no nulls in the table
-- EXPECT: No results
SELECT *
FROM silver.calendar_dates
WHERE service_id IS NULL OR service_date IS NULL;
GO

/*
===================================
Quality checks for 'trips'
===================================
*/

-- Ensure there are unique or not null trip_id elements
-- EXPECT: No results
SELECT
    trip_id,
    COUNT(trip_id)
FROM silver.trips
GROUP BY trip_id
HAVING COUNT(trip_id) > 1 OR trip_id IS NULL;
GO

-- Ensure there are no nulls in the rest of the table
-- EXPECT: No results
SELECT *
FROM silver.trips
WHERE
    route_id IS NULL OR
    service_id IS NULL OR
    trip_headsign IS NULL OR
    direction_id IS NULL OR
    block_id IS NULL OR
    shape_id IS NULL;
GO

/*
===================================
Quality checks for 'routes'
===================================
*/

-- Ensure there are unique or not null route_id elements
-- EXPECT: No results
SELECT
    route_id,
    COUNT(route_id)
FROM silver.routes
GROUP BY route_id
HAVING COUNT(route_id) > 1 OR route_id IS NULL;
GO

-- Ensure there are no nulls in the rest of the table
-- EXPECT: No results
SELECT *
FROM silver.routes
WHERE
    agency_id IS NULL OR
    bus_line IS NULL OR
    bus_branch IS NULL OR
    route_long_name IS NULL OR
    route_desc IS NULL OR
    route_scope IS NULL;
GO

-- Ensure bus_line does not contain empty strings or 'N/A' values
-- EXPECT: No results
SELECT bus_line
FROM silver.routes
WHERE bus_line = '' OR bus_line = 'N/A';
GO

-- Ensure bus lines have the correct route_scope value attributed with four different test cases
-- EXPECT: 130 - Capital | 243 - Province | 522 - Municipality | OESTE - Municipality
SELECT
    DISTINCT bus_line, route_scope
FROM silver.routes
WHERE 
    bus_line = 'OESTE' OR
    bus_line = '130' OR
    bus_line = '243' OR
    bus_line = '522'
ORDER BY bus_line;
GO

/*
===================================
Quality checks for 'shapes'
===================================
*/

-- Ensure there are no nulls in the table
-- EXPECT: No results
SELECT *
FROM silver.shapes
WHERE
    shape_id IS NULL OR
    shape_pt_lat IS NULL OR
    shape_pt_lon IS NULL OR
    shape_pt_sequence IS NULL OR
    shape_dist_traveled IS NULL;
GO

/*
===================================
Quality checks for 'stop_times'
===================================
*/

-- Ensure there are only 1 or 2 (for round trips) identical stop IDs per trip
-- EXPECT: No results
SELECT
    trip_id,
    stop_id,
    COUNT(stop_id)
FROM silver.stop_times
GROUP BY trip_id, stop_id
HAVING COUNT(stop_id) NOT IN (1, 2);
GO

-- Ensure there are no nulls in the rest of the table
-- EXPECT: No results
SELECT *
FROM silver.stop_times
WHERE
    arrival_time IS NULL OR
    departure_time IS NULL OR
    stop_id IS NULL OR
    stop_sequence IS NULL OR
    shape_dist_traveled IS NULL;
GO

/*
===================================
Quality checks for 'agency'
===================================
*/

-- Ensure there are no nulls in the table
-- EXPECT: No results
SELECT *
FROM silver.agency
WHERE
    agency_id IS NULL OR
    agency_name IS NULL OR
    agency_url IS NULL OR
    timezone_country IS NULL OR
    timezone_city IS NULL;
GO

-- Ensure timezone_country and timezone_city have correct values, taking agency_id 10 as test case
-- EXPECT: Argentina | Buenos Aires
SELECT
    timezone_country,
    timezone_city
FROM silver.agency
WHERE agency_id = 10;