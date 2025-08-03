/*
================================
DDL: Create bronze stage tables
================================

This script creates tables in the 'bronze' schema, dropping 
existing tables if they already exist, and includes indexes
for some columns in specific tables.
*/

-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse
GO

-- Create 'calendar_dates'
IF OBJECT_ID('bronze.calendar_dates', 'U') IS NOT NULL
	DROP TABLE bronze.calendar_dates
GO

CREATE TABLE bronze.calendar_dates(
	service_id INT,
	date NVARCHAR(10),
	exception_type INT
);
GO

-- Create 'trips'
IF OBJECT_ID('bronze.trips', 'U') IS NOT NULL
	DROP TABLE bronze.trips
GO

CREATE TABLE bronze.trips(
	route_id INT,
	service_id INT,
	trip_id NVARCHAR(10),
	trip_headsign NVARCHAR(100),
	trip_short_name NVARCHAR(20),
	direction_id INT,
	block_id NVARCHAR(20),
	shape_id INT,
	exceptional INT
);
GO

-- Create 'routes'
IF OBJECT_ID('bronze.routes', 'U') IS NOT NULL
	DROP TABLE bronze.routes
GO

CREATE TABLE bronze.routes(
	route_id NVARCHAR(10), -- The route_id column in 'routes.txt' has double quotes
	agency_id NVARCHAR(10), -- The agency_id column in 'routes.txt' has double quotes
	route_short_name NVARCHAR(20),
	route_long_name NVARCHAR(20),
	route_desc NVARCHAR(100),
	route_type INT
);
GO

-- Create 'shapes'
IF OBJECT_ID('bronze.shapes', 'U') IS NOT NULL
	DROP TABLE bronze.shapes
GO

CREATE TABLE bronze.shapes(
	shape_id INT,
	shape_pt_lat FLOAT,
	shape_pt_lon FLOAT,
	shape_pt_sequence INT,
	shape_dist_traveled REAL
);
GO

-- Create 'stop_times'
IF OBJECT_ID('bronze.stop_times', 'U') IS NOT NULL
	DROP TABLE bronze.stop_times
GO

CREATE TABLE bronze.stop_times(
	trip_id NVARCHAR(20),
	arrival_time NVARCHAR(10),
	departure_time NVARCHAR(10),
	stop_id BIGINT,
	stop_sequence INT,
	timepoint INT,
	shape_dist_traveled INT
);
GO
	-- Add nonclustered index to optimize querying the table
	CREATE INDEX bronze_stop_times_cs_idx
	ON bronze.stop_times (trip_id);
	GO

-- Create 'agency'
IF OBJECT_ID('bronze.agency', 'U') IS NOT NULL
	DROP TABLE bronze.agency
GO

CREATE TABLE bronze.agency(
	agency_id INT,
	agency_name NVARCHAR(100),
	agency_url NVARCHAR(100),
	agency_timezone NVARCHAR(50),
	agency_lang NVARCHAR(5),
	agency_phone NVARCHAR(10)
);