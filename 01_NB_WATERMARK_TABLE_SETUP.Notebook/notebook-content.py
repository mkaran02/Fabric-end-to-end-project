# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "f39affc5-442d-4473-b984-acbb05579dfb",
# META       "default_lakehouse_name": "sales_lakehouse",
# META       "default_lakehouse_workspace_id": "0d0308db-899d-442e-8ecc-6bb95f0ffb64",
# META       "known_lakehouses": [
# META         {
# META           "id": "f39affc5-442d-4473-b984-acbb05579dfb"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

# MAGIC %%sql
# MAGIC CREATE OR REPLACE TABLE incremental_load_control
# MAGIC (
# MAGIC     table_name STRING,
# MAGIC     watermark_column STRING,
# MAGIC     last_loaded_value DATE
# MAGIC )

# METADATA ********************

# META {
# META   "language": "sparksql",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# MAGIC %%sql
# MAGIC --insert initial value
# MAGIC INSERT INTO sales_lakehouse.dbo.incremental_load_control VALUES 
# MAGIC (
# MAGIC     'crm_sales_details','order_date',DATE('1900-01-01')
# MAGIC );

# METADATA ********************

# META {
# META   "language": "sparksql",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# MAGIC %%sql
# MAGIC -- Read Watermark BEFORE updating the max order_dt
# MAGIC SELECT last_loaded_value
# MAGIC FROM sales_lakehouse.dbo.incremental_load_control
# MAGIC WHERE table_name = 'crm_sales_details';

# METADATA ********************

# META {
# META   "language": "sparksql",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
