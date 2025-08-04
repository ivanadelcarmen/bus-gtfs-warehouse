/*
================================
DDL: Create gold stage tables
================================

This script creates tables in the 'gold' schema with adequate
column types, dropping existing tables if they already exist.
*/

-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse;
GO

-- Create 'dim_agencies'
IF OBJECT_ID('gold.dim_agencies', 'U') IS NOT NULL
	DROP TABLE gold.dim_agencies;
GO

CREATE TABLE gold.dim_agencies (
    agency_key INT,
    agency_id INT,
    agency_name NVARCHAR(100),
	agency_url NVARCHAR(100),
	timezone_country NVARCHAR(30),
	timezone_city NVARCHAR(30)
);
GO

-- Create 'dim_routes'
IF OBJECT_ID('gold.dim_routes', 'U') IS NOT NULL
	DROP TABLE gold.dim_routes;
GO

CREATE TABLE gold.dim_routes (
	route_key INT,
	route_id INT,
	agency_id INT,
	bus_line NVARCHAR(5),
	bus_branch NVARCHAR(5),
	route_description TEXT,
	route_scope NVARCHAR(20)
);
GO

-- Create 'dim_markers'
IF OBJECT_ID('gold.dim_markers', 'U') IS NOT NULL
	DROP TABLE gold.dim_markers;
GO

CREATE TABLE gold.dim_markers (
	marker_key INT,
	route_key INT,
	route_direction INT,
	marker_ordinal INT,
	marker_lat FLOAT,
	marker_lon FLOAT
);
GO

-- Create 'fact_services'
IF OBJECT_ID('gold.fact_services', 'U') IS NOT NULL
	DROP TABLE gold.fact_services;
GO

CREATE TABLE gold.fact_services (
	route_key INT,
	agency_key INT,
	service_type NVARCHAR(20),
	service_trips INT
);
GO

-- Create 'fact_performance'
IF OBJECT_ID('gold.fact_performance', 'U') IS NOT NULL
	DROP TABLE gold.fact_performance;
GO

CREATE TABLE gold.fact_performance (
	route_key INT,
	agency_key INT,
	route_trips INT,
	route_avg_distance INT,
	route_avg_stops INT,
	route_avg_time INT
);