-- 06_sensitivity.sql
-- Sensitivity of the intervention decision to the retention success rate.
--
-- 05_economics.sql assumes 30% of customers who would otherwise leave are
-- retained when offered a deal. That figure is not in the data. It was chosen
-- from general industry experience, and every result in the economics layer
-- scales directly off it.
--
-- This file tests what happens when it is wrong. The cost of contact stays
-- fixed at R60. The model, the churn probabilities and the CLV figures are all
-- unchanged. Only the success rate moves.
--
-- The question being answered: at what success rate does the programme stop
-- paying for itself, and how far is that from the assumed 30%?

CREATE OR REPLACE VIEW vw_sensitivity AS
WITH rates(success_rate) AS (
    VALUES (0.10), (0.15), (0.20), (0.25), (0.30), (0.35), (0.40), (0.50)
),
scored AS (
    SELECT
        r.success_rate,
        s.customer_id,
        s.clv,
        s.churn_probability,
        (s.churn_probability * s.clv * r.success_rate) - 60.00 AS net_value
    FROM customer_scores s
    CROSS JOIN rates r
)
SELECT
    success_rate,
    COUNT(*) FILTER (WHERE net_value > 0)                      AS customers_contacted,
    ROUND(100.0 * COUNT(*) FILTER (WHERE net_value > 0)
          / COUNT(*), 1)                                       AS pct_of_base,
    ROUND(SUM(net_value) FILTER (WHERE net_value > 0), 2)      AS net_return_targeted,
    ROUND(SUM(net_value), 2)                                   AS net_return_contact_everyone,
    ROUND(60.00 * COUNT(*) FILTER (WHERE net_value > 0), 2)    AS total_cost,
    ROUND(
        SUM(net_value) FILTER (WHERE net_value > 0)
        / NULLIF(60.00 * COUNT(*) FILTER (WHERE net_value > 0), 0) * 100, 1
    )                                                          AS return_on_spend_pct
FROM scored
GROUP BY success_rate
ORDER BY success_rate;

SELECT * FROM vw_sensitivity;

-- Flat file for the reporting layer, on the same reasoning as 07_export.sql.
-- The sensitivity curve is shown on the executive page, and these eight rows
-- are the figures behind it. Exporting them rather than typing them into the
-- report keeps the rule the project has held throughout: every number on a
-- dashboard traces back to the SQL file that produced it.
--
-- This table is scenario-level, one row per success rate. The customer export
-- is customer-level. The two share no key and must not be related in the model.
COPY vw_sensitivity TO '../data/sensitivity_export.csv' (HEADER, DELIMITER ',');
