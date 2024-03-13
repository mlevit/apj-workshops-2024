-- Set your catalog and database.
USE catalog.database;

-- Select all billing data
SELECT * FROM system.billing.usage limit 10;


-- Select all access audit
SELECT * FROM system.access.audit limit 10;


-- Select all table lineage data
SELECT * FROM system.access.table_lineage limit 10;


-- Select spend over time per month for each account, workspace, and SKU
SELECT
  u.account_id,
  u.workspace_id,
  u.sku_name,
  u.cloud,
  u.usage_start_time,
  u.usage_end_time,
  u.usage_date,
  date_format(u.usage_date, 'yyyy-MM') as YearMonth,
  u.usage_unit,
  u.usage_quantity,
  lp.pricing.default as list_price,
  lp.pricing.default * u.usage_quantity as list_cost,
  u.usage_metadata.*
FROM
  system.billing.usage u
  JOIN system.billing.list_prices lp on u.cloud = lp.cloud
  AND u.sku_name = lp.sku_name
  AND u.usage_start_time >= lp.price_start_time
  AND (
    u.usage_end_time <= lp.price_end_time
    OR lp.price_end_time is null
  )
WHERE
  usage_metadata.job_id is not null;


-- Review all entities accessing your table (workflows, notebook, DLT, DBSQL...)
SELECT DISTINCT(entity_type) FROM system.access.table_lineage;


-- Display all column lineage
SELECT * FROM system.access.column_lineage;


-- Display all grants
SELECT
  grantee,
  table_name,
  privilege_type
FROM
  system.information_schema.table_privileges
WHERE
  table_name = "dim_customer";


-- Display who's accessed a particuluar table the most.
SELECT
  user_identity.email,
  count(*)
FROM
  system.operational_data.audit_logs
WHERE
  request_params.table_full_name = "<<catalog>>.<<schema>>.<<table>>"
  AND service_name = "unityCatalog"
  AND action_name = "generateTemporaryTableCredential"
GROUP BY
  1
ORDER BY
  2 DESC
LIMIT
  1;


-- Display what tables a particuluar user has access within the last 24 hours.
SELECT
  request_params.table_full_name
FROM
  system.access.audit
WHERE
  user_identity.email = "<<email>>"
  AND service_name = "unityCatalog"
  AND action_name = "generateTemporaryTableCredential"
  AND datediff(now(), event_time) < 1;