/*
================================
DDL: Create silver stage tables
================================

This script creates tables in the 'silver' schema with adequate
column types, dropping existing tables if they already exist, and
includes indexes for some or all columns in specific tables.
*/

-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse;
GO

-- Create 'calendar_dates'
IF OBJECT_ID('silver.calendar_dates', 'U') IS NOT NULL
	DROP TABLE silver.calendar_dates;
GO

CREATE TABLE silver.calendar_dates(
	service_id INT,
	service_date DATE, -- Renamed to avoid reserved word 'date'
	service_type NVARCHAR(20)
);
GO
	-- Add clustered index to optimize querying unique values
	CREATE CLUSTERED INDEX service_id_idx
	ON silver.calendar_dates (service_id);
	GO

-- Create 'trips'
IF OBJECT_ID('silver.trips', 'U') IS NOT NULL
	DROP TABLE silver.trips;
GO

CREATE TABLE silver.trips(
	route_id INT,
	service_id INT,
	trip_id NVARCHAR(10),
	trip_headsign TEXT,
	direction_id INT,
	block_id NVARCHAR(20),
	shape_id INT
);
GO
	-- Add clustered index to optimize trip_id filtering and joins
	CREATE UNIQUE CLUSTERED INDEX trips_trip_id_idx
	ON silver.trips (trip_id);
	GO

	-- Add nonclustered index to optimize joins with shape_id
	CREATE INDEX trips_shape_id_idx
	ON silver.trips (shape_id);
	GO

-- Create 'routes'
IF OBJECT_ID('silver.routes', 'U') IS NOT NULL
	DROP TABLE silver.routes;
GO

CREATE TABLE silver.routes(
	route_id INT,
	agency_id INT,
	bus_line NVARCHAR(5), -- Derived column from route_short_name
	bus_branch NVARCHAR(5), -- Derived column from route_short_name
	route_long_name NVARCHAR(20),
	route_desc TEXT,
	route_type INT
);
GO

-- Create 'shapes'
IF OBJECT_ID('silver.shapes', 'U') IS NOT NULL
	DROP TABLE silver.shapes;
GO

CREATE TABLE silver.shapes(
	shape_id INT,
	shape_pt_lat FLOAT,
	shape_pt_lon FLOAT,
	shape_pt_sequence INT,
	shape_dist_traveled REAL
);
GO
	-- Add columnstore index to optimize aggregations
	CREATE CLUSTERED COLUMNSTORE INDEX shapes_cs_idx
	ON silver.shapes;
	GO

-- Create 'stop_times'
IF OBJECT_ID('silver.stop_times', 'U') IS NOT NULL
	DROP TABLE silver.stop_times;
GO

CREATE TABLE silver.stop_times(
	trip_id NVARCHAR(20),
	arrival_time NVARCHAR(8),
	stop_id BIGINT,
	stop_sequence INT,
	shape_dist_traveled INT
);
GO
	-- Add nonclustered index in both columns to optimize the aggregation strategy
	CREATE INDEX stop_times_arrival_trips_idx
	ON silver.stop_times (trip_id, arrival_time);
	GO

-- Create 'agency'
IF OBJECT_ID('silver.agency', 'U') IS NOT NULL
	DROP TABLE silver.agency;
GO

CREATE TABLE silver.agency(
	agency_id INT,
	agency_name NVARCHAR(100),
	agency_url NVARCHAR(100),
	timezone_country NVARCHAR(30),
	timezone_city NVARCHAR(30)
);