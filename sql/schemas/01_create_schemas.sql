-- Medallion layers
-- bronze: raw data exactly as loaded
-- silver: cleaned and standardized data
-- gold: star schema for analytics and modeling
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
