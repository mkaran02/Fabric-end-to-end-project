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

-- # **Table : bronze_crm_customer_info**

-- MARKDOWN ********************

-- ####  **1. check for duplicates and null values**

-- CELL ********************

-- MAGIC %%sql
-- MAGIC --check nulls or duplicates in primary key column(cst_id)
-- MAGIC SELECT cst_id , count(*) as id_count from sales_lakehouse.dbo.bronze_crm_customer_info 
-- MAGIC group by cst_id 
-- MAGIC having count(*) > 1 or cst_id is null;


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **Observation : We found that primary key column have null values as well as have duplicates**

-- MARKDOWN ********************

-- #### **2. check for unwanted spaces in string columns**

-- MARKDOWN ********************

-- **1. for cst_firstname**

-- CELL ********************

-- MAGIC %%sql 
-- MAGIC select cst_firstname from sales_lakehouse.dbo.bronze_crm_customer_info 
-- MAGIC where cst_firstname != trim(cst_firstname)

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **observation : We found firstnames with leading /trailing spaces**

-- MARKDOWN ********************

-- **2. for cst_last_name**

-- CELL ********************

-- MAGIC %%sql
-- MAGIC select cst_lastname from sales_lakehouse.dbo.bronze_crm_customer_info 
-- MAGIC where cst_lastname != trim(cst_lastname)

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **observation : We found lastnames with leading /trailing spaces**

-- MARKDOWN ********************

-- #### **3.Quality issues in low cardinality columns (Data Standardization & Consistency)**

-- CELL ********************

-- MAGIC %%sql 
-- MAGIC select distinct cst_marital_status
-- MAGIC from sales_lakehouse.dbo.bronze_crm_customer_info

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **observation : We found cst_marital_status has NULL value**

-- CELL ********************

-- MAGIC %%sql 
-- MAGIC select distinct cst_gndr
-- MAGIC from sales_lakehouse.dbo.bronze_crm_customer_info

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **observation : We found cst_gndr has NULL value**

-- MARKDOWN ********************

-- #### **4. Verify schema**

-- CELL ********************

-- MAGIC %%sql 
-- MAGIC describe table sales_lakehouse.dbo.bronze_crm_customer_info 

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- # **Table : bronze_crm_product_info**

-- MARKDOWN ********************

-- ####  **1. check for duplicates and null values**

-- CELL ********************

-- MAGIC %%sql
-- MAGIC --check nulls or duplicates in primary key column(prd_id)
-- MAGIC SELECT prd_id , count(*) as id_count from sales_lakehouse.dbo.bronze_crm_product_info 
-- MAGIC group by prd_id 
-- MAGIC having count(*) > 1 or prd_id is null;


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **Observation : No duplicate and null found**

-- MARKDOWN ********************

-- #### **2. check for data quality**

-- CELL ********************

-- MAGIC %%sql
-- MAGIC -- check whether all the category ids exist in product category table after creating the cat_id in crm_product_info
-- MAGIC SELECT 
-- MAGIC     prd_id,
-- MAGIC     prd_key,
-- MAGIC     REPLACE(SUBSTRING(prd_key, 1, 5), "-", "_") AS cat_id, -- this one is used to merge with erp_product_category
-- MAGIC     prd_nm,
-- MAGIC     prd_cost,
-- MAGIC     prd_line,
-- MAGIC     prd_start_dt,
-- MAGIC     prd_end_dt
-- MAGIC FROM sales_lakehouse.dbo.bronze_crm_product_info
-- MAGIC WHERE REPLACE(SUBSTRING(prd_key, 1, 5), "-", "_") NOT IN
-- MAGIC (SELECT DISTINCT ID FROM sales_lakehouse.dbo.bronze_erp_product_category);
-- MAGIC 
-- MAGIC -- Observation: CO_PE cat_id is there in bronze_crm_product_info but NOT in erp_product_category, which is fine and possible

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

-- MAGIC %%sql
-- MAGIC -- check whether all the product ids exist in bronze_crm_sales_details table after creating the prd_id in crm_product_info
-- MAGIC SELECT 
-- MAGIC     prd_id,
-- MAGIC     prd_key,
-- MAGIC     REPLACE(SUBSTRING(prd_key, 1, 5), "-", "_") AS cat_id,      
-- MAGIC     SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,         -- this key will be used to join with crm_sales_details
-- MAGIC     prd_nm,
-- MAGIC     prd_cost,
-- MAGIC     prd_line,
-- MAGIC     prd_start_dt,
-- MAGIC     prd_end_dt
-- MAGIC FROM sales_lakehouse.dbo.bronze_crm_product_info
-- MAGIC WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN
-- MAGIC (SELECT sls_prd_key FROM sales_lakehouse.dbo.bronze_crm_sales_details);
-- MAGIC 
-- MAGIC -- Observation: Few prd_key found. They may not have sales in crm_sales_details table, which is fine

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **3. check for unwanted spaces in string columns**

-- CELL ********************

-- MAGIC %%sql 
-- MAGIC select prd_nm from sales_lakehouse.dbo.bronze_crm_product_info 
-- MAGIC where prd_nm != trim(prd_nm)

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **Observation : No unwanted space found**

-- MARKDOWN ********************

-- #### **4.check for Nulls and negative numbers**

-- CELL ********************

-- MAGIC %%sql
-- MAGIC select prd_cost from sales_lakehouse.dbo.bronze_crm_product_info 
-- MAGIC where prd_cost < 0 OR prd_cost is null

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **Observation : No NULLS and negative numbers found**

-- MARKDOWN ********************

-- #### **5.Quality issues in low cardinality columns (Data Standardization & Consistency)**

-- MARKDOWN ********************

-- ****

-- CELL ********************

-- MAGIC %%sql 
-- MAGIC select distinct prd_line from sales_lakehouse.dbo.bronze_crm_product_info 

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **Observation : found one empty value**

-- MARKDOWN ********************

-- #### **6.check for invalid date orders(End date must not be smaller than the start date)**

-- CELL ********************

-- MAGIC %%sql 
-- MAGIC select * from sales_lakehouse.dbo.bronze_crm_product_info 
-- MAGIC where prd_end_dt < prd_start_dt

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **-- Observation: Few End dates are smaller than the start date.
-- -- Solution: End Date = Start Date of the Next Record - 1 (there shouldn't be any overlapping dates)**

-- CELL ********************

-- MAGIC %%sql
-- MAGIC -- Checking few records where prd_end_dt < prd_start_dt
-- MAGIC SELECT
-- MAGIC *
-- MAGIC FROM sales_lakehouse.dbo.bronze_crm_product_info
-- MAGIC WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- # **Table : bronze_crm_sales_details**

-- MARKDOWN ********************

-- #### **1.Check for unwanted spaces in strings**

-- CELL ********************

-- MAGIC %%sql
-- MAGIC select sls_ord_num 
-- MAGIC FROM sales_lakehouse.dbo.bronze_crm_sales_details
-- MAGIC where sls_ord_num != trim(sls_ord_num) 

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ###### **observation:no unwanted spaces found**

-- MARKDOWN ********************

-- #### **2. check if all key values from sales table are there in product table**

-- CELL ********************

select * from sales_lakehouse.dbo.bronze_crm_sales_details
where sls_prd_key not in 
(select prd_key from  sales_lakehouse.dbo.bronze_crm_product_info)

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

-- check if all key values from sales table are there in customer table

SELECT
* 
FROM sales_lakehouse.dbo.bronze_crm_sales_details
WHERE sls_cust_id NOT IN 
(SELECT cst_id FROM sales_lakehouse.dbo.bronze_crm_customer_info);

-- observation: no result. all keys from sales table are there in customer table

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **3. check for invalid dates**

-- MARKDOWN ********************

-- #### check for invalid dates
-- * Negative numbes or zeros can't be cast to a date
-- * length of the date must be 8 here
-- * check for outliers by validating the boundaries of the date range

-- CELL ********************

select  sls_order_dt from  sales_lakehouse.dbo.bronze_crm_sales_details
where sls_order_dt<=0 or len(sls_order_dt) !=8 OR sls_order_dt > 20500101
OR sls_order_dt < 19000101;

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **-- observation: 
-- -- there are zeros in sls_order_dt -- this is to be converted as NULL
-- -- length is != 8 (these are not dates)
-- -- random date range (19000101 to 20500101) - no date is outside this range.**

-- CELL ********************

SELECT
sls_ship_dt             -- 
FROM sales_lakehouse.dbo.bronze_crm_sales_details
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101;

-- observation: no result (no issues found) 

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

SELECT
sls_due_dt             -- 
FROM sales_lakehouse.dbo.bronze_crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101;

-- observation: no result (no issues found) 

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

-- check for invalid date orders
-- Order Date must always be earlier than the Shipping Date or Due Date
SELECT
*             -- 
FROM sales_lakehouse.dbo.bronze_crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- observation: two sls_prd_key (TI-M823 and TT-M928). 
-- The sls_order_dt (32154 and 5489) will not considered as dates since the length is !=8 (will be replaced with NULL)

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **4.Check data inconsistency**

-- CELL ********************

--Business Rule:
--Sales = Quantity * Price
--Negative, zeros and NULLs are NOT Allowed in neither in Sales, Quantity and Price
select sls_sales,sls_quantity , sls_price from  sales_lakehouse.dbo.bronze_crm_sales_details
where sls_sales != sls_quantity*sls_price
 or sls_sales is null or sls_quantity is null or sls_price is null
 or sls_sales <=0 or sls_quantity<=0 or sls_price<=0  
 order by sls_sales , sls_quantity,sls_price


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **-- observation: we have NULLS, zeros and negative numbers.**
-- - -- We need to define the rule to fix these issues
-- - -- 1. If Sales is negative, zero or null, derive it using Quantity and Price
-- - -- 2. If Price is zero or null, calculate it using Sales and Quanity
-- - -- 3. If Price is negative, convert it to a positive value

-- CELL ********************

--check after applying the rules 
select 
sls_sales as sls_sales_old , sls_quantity as sls_quantity_old , sls_price as sls_price_old,
case when sls_sales<=0 or sls_sales is null or sls_sales != sls_quantity * ABS(sls_price)
    then cast(sls_quantity*ABS(sls_price) as INT)
    else sls_sales
end as sls_sales   ,

case when sls_price<=0 or sls_price is null 
    then cast(sls_sales/nullif(sls_quantity,0) as int)
    else sls_price
end as sls_price 
from  sales_lakehouse.dbo.bronze_crm_sales_details
where sls_sales != sls_quantity*sls_price
 or sls_sales is null or sls_quantity is null or sls_price is null
 or sls_sales <=0 or sls_quantity<=0 or sls_price<=0  
 order by sls_sales , sls_quantity,sls_price 



-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- # **Table : bronze_erp_customers**

-- MARKDOWN ********************

-- #### **1.Check duplicates**

-- CELL ********************

select cid , count(*) as cid_count from sales_lakehouse.dbo.bronze_erp_customers
group by cid 
having count(*) > 1

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **2.-- check if all cid is there in bronze_crm_customer_info**

-- CELL ********************

select cid from sales_lakehouse.dbo.bronze_erp_customers
where cid not in 
(select cst_id from sales_lakehouse.dbo.bronze_crm_customer_info )

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **Obsveration:all cids are in customer_info table**

-- MARKDOWN ********************

-- #### **3.check outliers in bdate column**

-- CELL ********************

SELECT
bdate
FROM sales_lakehouse.dbo.bronze_erp_customers
WHERE bdate < '1920-01-01' OR bdate > CURRENT_TIMESTAMP();


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- **-- observation:**
-- - -- there are birth dates which are less than the random 1920-01-01 (customers more than 100 years old)
-- - -- birth dates which is in future (not possible)

-- MARKDOWN ********************

-- #### **4.check low cardinality columns**

-- CELL ********************

select distinct gen from sales_lakehouse.dbo.bronze_erp_customers


-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ###### **observation: gender column don't have standard values**

-- MARKDOWN ********************

-- # **Table:bronze_erp_location**

-- MARKDOWN ********************

-- #### **1.Check duplicates**

-- CELL ********************

select cid , count(*) as cid_count from sales_lakehouse.dbo.bronze_erp_location
group by cid having count(*)>1

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **2.check all values of erp_location present in crm_customer_info**

-- CELL ********************

SELECT 
cid
FROM sales_lakehouse.dbo.bronze_erp_location
WHERE cid NOT IN
(SELECT cst_key FROM sales_lakehouse.dbo.bronze_crm_customer_info);

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

-- check if the transformation will fix the issue
SELECT 
REPLACE(cid, '-', '') AS cid
FROM sales_lakehouse.dbo.bronze_erp_location
WHERE REPLACE(cid, '-', '') NOT IN
(SELECT cst_key FROM sales_lakehouse.dbo.bronze_crm_customer_info);

-- observation: no result. Hence, transformation will fix the issue

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **3.Check low cardinality columns**

-- CELL ********************

select distinct cntry from sales_lakehouse.dbo.bronze_erp_location

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- ###### **observation: country column values are not standardized**

-- MARKDOWN ********************

-- # **Table:bronze_erp_product_category**

-- MARKDOWN ********************

-- #### **1.check if all ids/keys mathcing in bronze_crm_product_info**

-- CELL ********************

select id from sales_lakehouse.dbo.bronze_erp_product_category
where id not in 
(select prd_id )

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **2.check unwanted spaces**

-- CELL ********************

-- checking unwanted spaces
SELECT
cat
FROM sales_lakehouse.dbo.bronze_erp_product_category
WHERE cat != TRIM(cat);

-- observation: no spaces

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

-- checking unwanted spaces
SELECT
subcat
FROM sales_lakehouse.dbo.bronze_erp_product_category
WHERE subcat != TRIM(subcat);

-- observation: no spaces

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

-- checking unwanted spaces
SELECT
maintenance
FROM sales_lakehouse.dbo.bronze_erp_product_category
WHERE maintenance != TRIM(maintenance);

-- observation: no spaces

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- MARKDOWN ********************

-- #### **3.checking low cardinality columns**

-- CELL ********************

SELECT
DISTINCT cat
FROM sales_lakehouse.dbo.bronze_erp_product_category;

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

SELECT
DISTINCT subcat
FROM sales_lakehouse.dbo.bronze_erp_product_category;

-- METADATA ********************

-- META {
-- META   "language": "sparksql",
-- META   "language_group": "synapse_pyspark"
-- META }

-- CELL ********************

SELECT
DISTINCT maintenance
FROM sales_lakehouse.dbo.bronze_erp_product_category;

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
