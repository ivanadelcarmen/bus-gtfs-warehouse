-- Make sure the gtfswarehouse database is used
USE gtfswarehouse;
GO

/*
====================================================================
Description:
    Format a GTFS time with an hourly offset higher than 23 into a 
    standard and casted TIME value within the 24-hour system.
Parameters:
    @gtfs_time: The original GTFS time value as a 'HH:mm:ss' string.
Returns:
    TIME: A value ranging from 00:00:00 to 23:59:59 included.
====================================================================
*/
CREATE OR ALTER FUNCTION gold.format_gtfs_time (
    @gtfs_time NVARCHAR(8)
) RETURNS TIME
AS
BEGIN
    DECLARE @hour INT = CAST(LEFT(@gtfs_time, 2) AS INT);
    DECLARE @rest NVARCHAR(6) = RIGHT(@gtfs_time, 6);
    DECLARE @adjusted_hour NVARCHAR(2);

    IF @hour > 23
    BEGIN
        SET @hour = @hour - 24;
    END

    -- Add a leading zero and take the first two resulting digits from the right
    SET @adjusted_hour = RIGHT('0' + CAST(@hour AS NVARCHAR), 2);

    RETURN CAST(@adjusted_hour + @rest AS TIME);
END;
GO

/*
====================================================================
Description:
    Get the difference between two GTFS time values in minutes.
Parameters:
    @gtfs_start_time: The start time in GTFS format and as a 
    'HH:mm:ss' string.
    @gtfs_end_time: The end time in GTFS format and as a 
    'HH:mm:ss' string.
Returns:
    INT: The difference between both times as minutes.
====================================================================
*/
CREATE OR ALTER FUNCTION gold.gtfs_time_gap (
    @gtfs_start_time NVARCHAR(8),
    @gtfs_end_time NVARCHAR(8)
) RETURNS INT
AS
BEGIN
    DECLARE @formated_start_time TIME = gold.format_gtfs_time(@gtfs_start_time);
    DECLARE @formated_end_time TIME = gold.format_gtfs_time(@gtfs_end_time);

    IF @gtfs_start_time < '24:00:00' AND @gtfs_end_time >= '24:00:00'
    BEGIN
        SET @formated_start_time = DATEADD(HOUR, -12, @formated_start_time);
        SET @formated_end_time = DATEADD(HOUR, -12, @formated_end_time);
    END

    RETURN DATEDIFF(MINUTE, @formated_start_time, @formated_end_time);
END;