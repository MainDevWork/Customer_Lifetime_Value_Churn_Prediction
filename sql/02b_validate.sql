-- 02b_validate.sql
-- Validation checks run after 02_load.sql.
--
-- Row counts alone do not prove a correct load. Each check below returns a
-- figure whose expected value was already established during profiling in
-- 01_data_inventory.ipynb. A check returning anything else indicates a fault
-- in the load rather than a finding in the data.
--
-- Expected results:
--   churned customers        1869   -- matches the profiling figure
--   churn_reason populated   1869   -- populated for churned customers only
--   zero total_charges         11   -- the unbilled new accounts
--   zero tenure                11   -- must be the same eleven customers
--   full four-table join     7043   -- every customer joins to all three tables
--
-- The final check is the most important one. The source arrived as a single
-- flat extract and was separated into four tables; a join returning fewer than
-- 7,043 rows would mean customers were lost in that separation.

SELECT 'churned customers'      AS check, COUNT(*)            AS value FROM customer WHERE churn_value = 1
UNION ALL
SELECT 'churn_reason populated',        COUNT(churn_reason)         FROM customer
UNION ALL
SELECT 'zero total_charges',            COUNT(*)                    FROM billing  WHERE total_charges = 0
UNION ALL
SELECT 'zero tenure',                   COUNT(*)                    FROM customer WHERE tenure_months = 0
UNION ALL
SELECT 'full four-table join',          COUNT(*)
    FROM customer c
    JOIN geography    g ON c.zip_code    = g.zip_code
    JOIN subscription s ON c.customer_id = s.customer_id
    JOIN billing      b ON c.customer_id = b.customer_id;
