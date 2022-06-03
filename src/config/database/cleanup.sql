--
-- This is just a helper to cleanup databases during development.
-- Commands are meant to be executed manually against the correct server/database.
--

DROP USER CrossDb;
GO

DROP LOGIN CrossDb;
GO

-- On stamp1
DROP EXTERNAL TABLE ao.CatalogItemsStamp2;
DROP EXTERNAL TABLE ao.RatingsStamp2;
DROP EXTERNAL TABLE ao.CommentsStamp2;
DROP EXTERNAL DATA SOURCE stamp2db;
GO

DROP EXTERNAL TABLE ao.CatalogItemsStamp3;
DROP EXTERNAL TABLE ao.RatingsStamp3;
DROP EXTERNAL TABLE ao.CommentsStamp3;
DROP EXTERNAL DATA SOURCE stamp3db;
GO

-- On stamp2
DROP EXTERNAL TABLE ao.CatalogItemsStamp1;
DROP EXTERNAL TABLE ao.RatingsStamp1;
DROP EXTERNAL TABLE ao.CommentsStamp1;
DROP EXTERNAL DATA SOURCE stamp1db;
GO

DROP EXTERNAL TABLE ao.CatalogItemsStamp3;
DROP EXTERNAL TABLE ao.RatingsStamp3;
DROP EXTERNAL TABLE ao.CommentsStamp3;
DROP EXTERNAL DATA SOURCE stamp3db;
GO

-- On stamp3
DROP EXTERNAL TABLE ao.CatalogItemsStamp1;
DROP EXTERNAL TABLE ao.RatingsStamp1;
DROP EXTERNAL TABLE ao.CommentsStamp1;
DROP EXTERNAL DATA SOURCE stamp1db;
GO

DROP EXTERNAL TABLE ao.CatalogItemsStamp2;
DROP EXTERNAL TABLE ao.RatingsStamp2;
DROP EXTERNAL TABLE ao.CommentsStamp2;
DROP EXTERNAL DATA SOURCE stamp2db;
GO

-- On all
DROP VIEW ao.AllCatalogItems;
DROP VIEW ao.AllActiveRatings;
DROP VIEW ao.AllActiveComments;

DROP VIEW ao.LatestActiveCatalogItems;
DROP VIEW ao.LatestActiveComments;
DROP VIEW ao.LatestActiveRatings;
GO

DROP MASTER KEY;
GO

DROP DATABASE SCOPED CREDENTIAL CrossDbCred;
GO

DELETE FROM ao.Comments WHERE Deleted = 1
GO
