-- =========================================================================
-- File Name: logging_sp.sql
-- Description: Creates the ADF audit log table and database logging framework.
-- =========================================================================

-- 1. Drop old objects if they exist
DROP PROCEDURE IF EXISTS dbo.sp_InsertPipelineLog;
DROP TABLE IF EXISTS dbo.ADFPipelineLogs;
GO

-- 2. Create the Audit/Log Table (All tracking fields are NULLable)
CREATE TABLE dbo.ADFPipelineLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    PipelineName VARCHAR(100) NULL,
    RunID VARCHAR(50) NULL,
    StartTime DATETIME NULL,
    EndTime DATETIME NULL,
    DurationInSec INT NULL,
    RowsRead INT NULL,
    RowsWritten INT NULL,
    Status VARCHAR(20) NULL,
    ErrorMessage VARCHAR(MAX) NULL
);
GO

-- 3. Create the Stored Procedure with DECIMAL handling for ADF compatibility
CREATE PROCEDURE dbo.sp_InsertPipelineLog
    @PipelineName VARCHAR(100) = NULL, 
    @RunID VARCHAR(50) = NULL, 
    @StartTime DATETIME = NULL, 
    @EndTime DATETIME = NULL, 
    @DurationInSec DECIMAL(18,4) = NULL, -- Changed to DECIMAL to accept raw ADF metrics cleanly
    @RowsRead INT = NULL, 
    @RowsWritten INT = NULL, 
    @Status VARCHAR(20) = NULL, 
    @ErrorMessage VARCHAR(MAX) = NULL    
AS
BEGIN
    SET NOCOUNT ON; -- Prevents internal SQL messages from interfering with ADF parsers

    INSERT INTO dbo.ADFPipelineLogs (
        PipelineName, RunID, StartTime, EndTime, 
        DurationInSec, RowsRead, RowsWritten, Status, ErrorMessage
    )
    VALUES (
        ISNULL(@PipelineName, 'Unknown Pipeline'), 
        ISNULL(@RunID, 'Unknown Run ID'), 
        @StartTime, 
        ISNULL(@EndTime, GETUTCDATE()), 
        ISNULL(CEILING(@DurationInSec), 0), -- Rounds fractions up to the nearest whole second
        ISNULL(@RowsRead, 0), 
        ISNULL(@RowsWritten, 0), 
        ISNULL(@Status, 'Unknown'), 
        ISNULL(@ErrorMessage, 'No error message provided.')
    );
END;
GO
