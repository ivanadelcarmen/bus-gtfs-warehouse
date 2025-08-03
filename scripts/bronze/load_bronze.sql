/*
========================================
Create procedure for loading bronze data
========================================

This script creates the SQL procedure to load data from the TXT files
to each table in the 'bronze' schema following the CSV format and using
bulk insert, also logging load durations and ensuring UTF-8 encoding.

CHANGE EACH PATH AS NEEDED.

Parameters:
	None

Start the procedure by running:

USE gtfswarehouse
EXEC bronze.load_bronze
*/

-- Make sure the 'gtfswarehouse' database is being used
USE gtfswarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	-- Monitor total batch load duration (start)
	SET @batch_start_time = GETDATE();

	PRINT '=================================';
	PRINT 'Loading bronze tables';
	PRINT '=================================';
	PRINT '';

		-- Truncate and load data into 'calendar_dates'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.calendar_dates';
		TRUNCATE TABLE bronze.calendar_dates;

		PRINT '>> Populating table: bronze.calendar_dates';
		BULK INSERT bronze.calendar_dates
		FROM 'source\calendar_dates.txt'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'trips'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.trips';
		TRUNCATE TABLE bronze.trips;

		PRINT '>> Populating table: bronze.trips';
		BULK INSERT bronze.trips
		FROM 'source\trips.txt'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'routes'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.routes';
		TRUNCATE TABLE bronze.routes;

		PRINT '>> Populating table: bronze.routes';
		BULK INSERT bronze.routes
		FROM 'source\routes.txt'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'shapes'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.shapes';
		TRUNCATE TABLE bronze.shapes;

		PRINT '>> Populating table: bronze.shapes';
		BULK INSERT bronze.shapes
		FROM 'source\shapes.txt'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'stop_times'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.stop_times';
		TRUNCATE TABLE bronze.stop_times;

		PRINT '>> Populating table: bronze.stop_times';
		BULK INSERT bronze.stop_times
		FROM 'source\stop_times.txt'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================';

		-- Truncate and load data into 'agency'
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.agency';
		TRUNCATE TABLE bronze.agency;

		PRINT '>> Populating table: bronze.agency';
		BULK INSERT bronze.agency
		FROM 'source\agency.txt'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
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