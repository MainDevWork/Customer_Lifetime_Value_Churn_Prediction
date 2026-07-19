-- 07_export.sql
-- Reporting layer: one row per customer, for Power BI.
--
-- This is the last SQL in the project and it does no new work. Every figure in
-- it was calculated upstream: value in 04_clv.sql, probabilities by the model
-- in 03_modelling.ipynb, the decision in 05_economics.sql. This file only
-- gathers them into a single flat row per customer.
--
-- The reason it does no new work is the reason it exists. Power BI receives a
-- finished answer and aggregates it. No business rule lives in the report
-- layer, so no rule can be changed by a report author, and every number on a
-- dashboard can be traced back to the SQL file that produced it.
--
-- churn_reason is included for drill-down only. It is recorded after a customer
-- has left, so it was excluded from the model as leakage. It must never be used
-- as an input to anything predictive.

CREATE OR REPLACE VIEW vw_customer_export AS
SELECT
    e.customer_id,
    e.clv,
    e.value_decile,
    ROUND(e.churn_probability, 4)      AS churn_probability,
    e.decision,
    e.net_value,

    -- The recorded outcome. Needed to measure the model in the report:
    -- predicted against actual. 1 = left, 0 = stayed.
    e.churn_value,

    -- Populated only for customers who have left. NULL otherwise, and that
    -- NULL is correct rather than missing.
    c.churn_reason,

    e.contract,
    e.tenure_band,
    f.spend_band,
    g.city

FROM vw_intervention_economics e
JOIN customer  c ON e.customer_id = c.customer_id
JOIN geography g ON c.zip_code    = g.zip_code
JOIN vw_customer_features f ON e.customer_id = f.customer_id;

SELECT COUNT(*) FROM vw_customer_export;
