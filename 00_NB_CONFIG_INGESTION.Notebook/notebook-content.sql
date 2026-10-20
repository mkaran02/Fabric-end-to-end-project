-- Fabric notebook source

-- METADATA ********************

-- META {
-- META   "kernel_info": {
-- META     "name": "synapse_pyspark"
-- META   },
-- META   "dependencies": {
-- META     "lakehouse": {
-- META       "default_lakehouse": "f39affc5-442d-4473-b984-acbb05579dfb",
-- META       "default_lakehouse_name": "sales_lakehouse",
-- META       "default_lakehouse_workspace_id": "0d0308db-899d-442e-8ecc-6bb95f0ffb64",
-- META       "known_lakehouses": [
-- META         {
-- META           "id": "f39affc5-442d-4473-b984-acbb05579dfb"
-- META         }
-- META       ]
-- META     }
-- META   }
-- META }

-- MARKDOWN ********************

-- ## Creating config table

-- CELL ********************

CREATE OR REPLACE TABLE config_ingestion (
    source STRING,
    source_type STRING,
    source_path STRING,
    format STRING,
    table_name STRING,
    load_type STRING
);

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

UPDATE config_ingestion 
SET source_path = 'SenthamilVM/fabric-medallion-analytics/refs/heads/main/data_source/crm/cust_info.csv'
WHERE source_type = 'github';


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

-- inserting the config values
-- NOTE: replace github raw data relative path
INSERT INTO config_ingestion
(source, source_type, source_path, format, table_name, load_type)
VALUES
('CRM','github','SenthamilVM/fabric-medallion-analytics/refs/heads/main/data_source/crm/cust_info.csv','csv','crm_customer_info','full'),
('CRM','local','crm/prd_info.json','json','crm_product_info','full'),
('CRM','local','crm/sales_details.csv','csv','crm_sales_details','full'),
('ERP','local','erp/CUST_AZ12.csv','csv','erp_customers','full'),
('ERP','local','erp/LOC_A101.csv','csv','erp_location','full'),
('ERP','local','erp/PX_CAT_G1V2.csv','csv','erp_product_category','full');

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

SELECT * FROM sales_lakehouse.dbo.config_ingestion;

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }
