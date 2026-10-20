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

-- # Silver Layer: Full Load
-- **Source:** `bronze` | **Target:** `silver`
-- 
-- **Method:** CTAS (Create Table As Select)

-- MARKDOWN ********************

-- ## Table: silver_crm_customer_info

-- CELL ********************

create or replace table sales_lakehouse.dbo.silver_crm_customer_info
AS
    select 
        cast(cst_id as int ) as cst_id,
        cast(cst_key as string) as cst_key,
        --removing spaces
        trim(cst_firstname) as cst_firstname,
        trim(cst_lastname) as cst_lastname,
        --data standardization and consistency
        case upper(trim(cst_marital_status))
            when 'M' then 'Married'
            when 'S' then 'Single'
            else 'Unknown'
        end as cst_marital_status,
        case upper(trim(cst_gndr))
            when 'M' then 'Male'
            when 'F' then 'Female'
            else 'Unknown'
        end as cst_gndr,
        --casting to date
        cast(cst_create_date as date) as cst_create_date,
        --adding metadata columns
        current_timestamp() as meta_load_timestamp,
        'CRM' as meta_source_system,
        'crm_customer_info' as meta_table_name
    from
    --subquery to filter only latest cst_id(one cusotmer have multiple versions,ex;karan or karan m)
    (
        select * , row_number() over( partition by cst_id order by cst_create_date desc) as flag_last
        from sales_lakehouse.dbo.bronze_crm_customer_info
        where cst_id is not null

    )t
    where flag_last=1 --consider only latest one record for each cst_id



        

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ## Table: silver_crm_product_info

-- CELL ********************

create or replace table sales_lakehouse.dbo.silver_crm_product_info
as 
select 
    prd_id,
    --exctacts 1st 5 characters and replace - with _  to join with erp_product_category
    replace(substring(prd_key,1,5),"-","_") as cat_id,
    --starts at character 7 and extracts up to the original string's length.
    substring(prd_key,7,len(prd_key)) as prd_key,
    prd_nm,
    --replace null with 0
    cast(coalesce(prd_cost ,0) as int) as prd_cost,
    --data standardization 
    case upper(trim(prd_line))
        when 'M' then 'Mountain'
        when 'S' then 'Other Sales'
        when 'R' then 'Road'
        when 'T' then 'Touring'
        else 'Unknown'
    end as prd_line,

    -- End Date = Start Date of the Next Record - 1
    cast(prd_start_dt as date) as prd_start_dt,
    CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) AS DATE) - 1 AS prd_end_dt, -- adding -1 to avoid date overlapping
    -- adding metadata columns
    CURRENT_TIMESTAMP() AS meta_load_timestamp,
    'CRM' AS meta_source_system,
    'crm_product_info' AS meta_table_name
FROM sales_lakehouse.dbo.bronze_crm_product_info;
    


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ## Table: silver_crm_sales_details

-- CELL ********************

-- Creating silver_crm_sales_details table
CREATE OR REPLACE TABLE sales_lakehouse.dbo.silver_crm_sales_details
AS
SELECT 
    sls_ord_num,
    sls_prd_key,
    CAST(sls_cust_id AS INT) AS sls_cust_id,
    --date issue handling as we see in bronze quality check
    case when sls_order_dt = 0 or len(sls_order_dt)!=8 then null
        else to_date(cast(sls_order_dt as string),'yyyyMMdd')
    end as sls_order_dt,

    --apply same condition for this also 
    CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
         ELSE TO_DATE(CAST(sls_ship_dt AS STRING), 'yyyyMMdd')
    END AS sls_ship_dt,

    -- applying same conditions for future proof
    CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
         ELSE TO_DATE(TRIM(CAST(sls_due_dt AS STRING)), 'yyyyMMdd')
    END AS sls_due_dt,  

    --apply bussiness rule for quantity , sales , price
    cast(
        case when sls_sales < 0 or sls_sales is null or sls_sales!= sls_quantity*abs(sls_price)
             then sls_quantity*abs(sls_price)
            else sls_sales
            end 
    as int ) as sls_sales,
    cast(sls_quantity as int) as sls_quantity,
    CAST(
        CASE WHEN sls_price <= 0 OR sls_price IS NULL
            THEN sls_sales / NULLIF(sls_quantity,0)       -- handling divide by 0 error
            ELSE sls_price
        END
    AS INT) AS sls_price,
    
    -- adding metadata columns
    CURRENT_TIMESTAMP() AS meta_load_timestamp,
    'CRM' AS meta_source_system,
    'crm_sales_details' AS meta_table_name

FROM sales_lakehouse.dbo.bronze_crm_sales_details;




-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ## Table: silver_erp_customers

-- CELL ********************

create or replace table sales_lakehouse.dbo.silver_erp_customers
as 
select 
    --removing 'NAS' from cid if there present
    case when cid like 'NAS%' then substring(cid,4,len(cid))
        else cid
    end as cid,

    --replacing future birth dates with null
    cast(
        case when bdate>current_timestamp() then null 
            else bdate
        end     
    as date ) as bdate,

    --data standardization
    case when upper(trim(gen)) in ('M',"MALE") THEN 'Male'
         when upper(trim(gen)) in ('F',"FEMALE") THEN 'Female'
         else 'Unknown'
    end as gen,

    -- adding metadata columns
    CURRENT_TIMESTAMP() AS meta_load_timestamp,
    'ERP' AS meta_source_system,
    'erp_customers' AS meta_table_name

FROM sales_lakehouse.dbo.bronze_erp_customers;     
        

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ## Table: silver_erp_location

-- CELL ********************

CREATE OR REPLACE TABLE sales_lakehouse.dbo.silver_erp_location
SELECT
-- fixing cid column (key column)
    REPLACE(cid, '-', '') AS cid,

-- Data Standardization
    CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'Unknown'
        ELSE cntry
    END AS cntry,

    -- adding metadata columns
        CURRENT_TIMESTAMP() AS meta_load_timestamp,
        'ERP' AS meta_source_system,
        'erp_location' AS meta_table_name

FROM sales_lakehouse.dbo.bronze_erp_location;

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ## Table: silver_erp_product_category

-- CELL ********************

CREATE OR REPLACE TABLE sales_lakehouse.dbo.silver_erp_product_category
AS
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM sales_lakehouse.dbo.bronze_erp_product_category;

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ### Updating the watermark / Incremental Load Control table with the maximum order_dt from sales_details


-- CELL ********************

--update the watermark after the initial Silver full load.
--it records the latest sales order date successfully available 
--in the Silver table, so the incremental-load notebook knows where to continue from.

update sales_lakehouse.dbo.incremental_load_control
set last_loaded_value = coalesce(
    (select max(sls_order_dt)
    from sales_lakehouse.dbo.silver_crm_sales_details),last_loaded_value
)
where table_name='crm_sales_details'

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }
