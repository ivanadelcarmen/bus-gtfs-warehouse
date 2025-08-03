/* 
============================
Create database and schemas
============================

This script creates a database called 'gtfswarehouse', dropping and reacreating it if
it already exists. Then, three schemas are set up within the database following the
Medallion architecture: 'bronze', 'silver', and 'gold'.
*/

USE master;
GO

-- Drop the database if it already exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'gtfswarehouse')
	BEGIN
		ALTER DATABASE gtfswarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		DROP DATABASE gtfswarehouse;
	END;
GO

-- Create the database
CREATE DATABASE gtfswarehouse;
GO
USE gtfswarehouse;
GO

-- Create schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;