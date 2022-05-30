--
-- Schema
--
IF NOT EXISTS(
    SELECT schema_name FROM INFORMATION_SCHEMA.SCHEMATA WHERE schema_name = 'ao'
)
EXEC('CREATE SCHEMA [ao]') /* schema needs to be its own batch, so workaround is needed here */
GO


--
-- Tables
--
IF OBJECT_ID('[ao].[CatalogItems]', 'U') IS NOT NULL
DROP TABLE [ao].[CatalogItems]
GO

CREATE TABLE [ao].[CatalogItems]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY, -- this ID will not be used to query
    [CatalogItemId] UNIQUEIDENTIFIER NOT NULL,
    [Name] NVARCHAR(50) NOT NULL,
    [Description] NVARCHAR(500) NOT NULL,
    [ImageUrl] NVARCHAR(100) NOT NULL,
    [Price] DECIMAL(10,2) NOT NULL,
    [LastUpdated] DATETIME NOT NULL,
    [Rating] FLOAT,
    [CreationDate] DATETIME2(7) DEFAULT (SYSUTCDATETIME()) NOT NULL,
    [Deleted] BIT DEFAULT (0) NOT NULL
);
GO

IF OBJECT_ID('[ao].[Ratings]', 'U') IS NOT NULL
DROP TABLE [ao].[Ratings]
GO

CREATE TABLE [ao].[Ratings]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [RatingId] UNIQUEIDENTIFIER NOT NULL,
    [CatalogItemId] UNIQUEIDENTIFIER NOT NULL,
    [Rating] INT NOT NULL,
    [CreationDate] DATETIME2(7) DEFAULT (SYSUTCDATETIME()) NOT NULL,
    [Deleted] BIT DEFAULT (0) NOT NULL

    --CONSTRAINT [FK_Ratings_CatalogItems_CatalogItemId] FOREIGN KEY ([CatalogItemId]) REFERENCES [ao].[CatalogItems] ([Id]) ON DELETE CASCADE
);
GO

IF OBJECT_ID('[ao].[Comments]', 'U') IS NOT NULL
DROP TABLE [ao].[Comments]
GO

CREATE TABLE [ao].[Comments]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY,
    [CommentId] UNIQUEIDENTIFIER NOT NULL,
    [CatalogItemId] UNIQUEIDENTIFIER NOT NULL,
    [AuthorName] NVARCHAR(50) NOT NULL,
    [Text] NVARCHAR(500) NOT NULL,
    [CreationDate] DATETIME2(7) DEFAULT (SYSUTCDATETIME()) NOT NULL, -- datetime2 has larger date range, larger precision
    [Deleted] BIT DEFAULT (0) NOT NULL

    --CONSTRAINT [FK_Comments_CatalogItems_CatalogItemId] FOREIGN KEY ([CatalogItemId]) REFERENCES [ao].[CatalogItems] ([Id]) ON DELETE CASCADE
);
GO

---
--- Sample data
--- This is only for script development and should be removed. The ADO pipeline handles data provisioning during deployment.
---
INSERT INTO [ao].[CatalogItems]
(
 [CatalogItemId], [Name], [Description], [Price], [ImageUrl], [LastUpdated]
)
VALUES
('fbb6593a-9ce4-4f1a-89b4-e1f218a594ef', 'City Bike', 'A super cool, blue bicycle.', 999.95, 'https://c.pxhere.com/photos/d8/84/bike_bicycle_basket_street_blue-121797.jpg!d', CURRENT_TIMESTAMP),
('61be42a0-3e54-4561-8f49-28fd509badf4', 'French Flag', 'Big, great French flag', 48.49, 'https://c.pxhere.com/photos/20/e0/flag_french_flag_france_nation-848099.jpg!d', CURRENT_TIMESTAMP),
('6892b16b-91d7-4a1d-bb4a-c8f22f0efe20', 'Blue Jeans', 'Classical, blue jeans', 75.0, 'https://c.pxhere.com/photos/fd/86/jeans_pants_clothing_blue_blue_jeans-1087981.jpg!d', CURRENT_TIMESTAMP),
('25f05539-df72-4272-972a-16f32ffc5e68', 'Notebook', 'Paper. Notebook.', 9.29, 'https://c.pxhere.com/photos/68/65/notebook_paper_page_empty_blank_office_book_business-883478.jpg!d', CURRENT_TIMESTAMP)
GO

INSERT INTO [ao].[Comments]
(
 [CommentId], [CatalogItemId], [AuthorName], [Text]
)
VALUES
('aac69679-8c0c-470c-85e2-11f893c8a013', 'fbb6593a-9ce4-4f1a-89b4-e1f218a594ef', 'John', 'Awesome bike!'),
('6aef2adf-4e34-42ac-8b95-36afd697867a', 'fbb6593a-9ce4-4f1a-89b4-e1f218a594ef', 'Mary', 'Do not buy, broke immediately.'),
('344e4d4a-e500-4b8c-a038-5b5f628e9e0a', 'fbb6593a-9ce4-4f1a-89b4-e1f218a594ef', 'Tester Testovich', 'Just testing...')
GO

INSERT INTO [ao].[Ratings]
(
 [RatingId], [CatalogItemId], [Rating]
)
VALUES
('4fca39bd-f93e-4010-99ee-884393e3ffa4', 'fbb6593a-9ce4-4f1a-89b4-e1f218a594ef', 5),
('ceca2229-b086-406c-8d0b-2fc78a0d6f3b', 'fbb6593a-9ce4-4f1a-89b4-e1f218a594ef', 1),
('82f6d908-1fdc-4096-be00-8543e891d31b', 'fbb6593a-9ce4-4f1a-89b4-e1f218a594ef', 3)
GO

--- Final check
SELECT * FROM [ao].[CatalogItems]
GO

SELECT * FROM [ao].[Comments]
GO

SELECT * FROM [ao].[Ratings]
GO
