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

    -- The three figures net_value is built from, carried through so the report
    -- can show the arithmetic rather than restate it. Without these the report
    -- would have to hold the R60 assumption itself, which would put a business
    -- rule in the reporting layer and break the rule this file exists to keep.
    e.value_at_risk,
    e.expected_value_saved,
    e.intervention_cost,

    -- The recorded outcome. Needed to measure the model in the report:
    -- predicted against actual. 1 = left, 0 = stayed.
    e.churn_value,

    -- Which group the customer was placed in when the data was split for
    -- training, recorded in 03_modelling.ipynb. The report measures the model
    -- on the 1,761 held-back customers alone. Measuring it across all 7,043
    -- would include customers the model was trained on and overstate it.
    s.data_split,

    -- The model's answer turned into a yes or no at the standard 0.5 cut-off,
    -- and the four-way classification the report's confusion matrix reads.
    -- Both are decided here rather than in the report for the same reason as
    -- above: the cut-off is a modelling choice, not a display choice, and a
    -- report author must not be able to move it.
    CASE WHEN e.churn_probability >= 0.5 THEN 1 ELSE 0 END AS predicted_churn,
    CASE
        WHEN e.churn_value = 1 AND e.churn_probability >= 0.5 THEN 'Caught'
        WHEN e.churn_value = 1 AND e.churn_probability <  0.5 THEN 'Missed'
        WHEN e.churn_value = 0 AND e.churn_probability >= 0.5 THEN 'False alarm'
        ELSE 'Correctly left alone'
    END AS outcome_class,

    -- Populated only for customers who have left. NULL otherwise, and that
    -- NULL is correct rather than missing.
    c.churn_reason,

    e.contract,
    e.tenure_band,
    f.spend_band,
    g.city,

    -- Carried through for the reporting map. Already loaded in 02_load.sql and
    -- verified there as one row per zip, so these add no new work and cannot
    -- introduce a conflict. Real coordinates are used rather than leaving Power
    -- BI to geocode city names, which is slower and resolves inconsistently.
    g.latitude,
    g.longitude

FROM vw_intervention_economics e
JOIN customer  c ON e.customer_id = c.customer_id
JOIN geography g ON c.zip_code    = g.zip_code
JOIN vw_customer_features f ON e.customer_id = f.customer_id
JOIN customer_scores s ON e.customer_id = s.customer_id;

SELECT COUNT(*) FROM vw_customer_export;

-- Flat file for the reporting layer. DuckDB has no native Power BI connector,
-- and this dataset is a fixed snapshot with nothing to refresh, so a file is
-- the simpler and more reproducible route. Regenerating it is a re-run of this
-- file, not a manual step.
COPY vw_customer_export TO '../data/customer_export.csv' (HEADER, DELIMITER ',');
