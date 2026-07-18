-- 05_economics.sql
-- Intervention economics: which customers are commercially worth retaining.
--
-- Combines the churn probability produced by the model with the lifetime value
-- derived in 04_clv.sql. The two were deliberately kept apart until this point:
-- the model answers "who is likely to leave", the value layer answers "who is
-- worth keeping", and only here are they brought together into a decision.
--
-- =====================================================================
-- ASSUMPTIONS -- NOT DERIVED FROM THE DATA. STATED EXPLICITLY.
-- =====================================================================
-- 1. INTERVENTION COST = R60 per customer contacted
--    Made up of:
--      R20  contact and administration -- automated channel (email or SMS),
--           not an agent call
--      R40  retention offer -- R20 per month held for two months
--    Broken into components so each can be challenged separately. Neither
--    figure appears in this dataset; a real programme would use its own
--    campaign costs.
--
--    The figure is set against what customers in this book actually pay:
--    the average monthly charge is R64.76, so an offer of R20 per month is
--    roughly a 30% discount held for a short period. The cost is derived from
--    the customer base, not chosen to produce a favourable result.
--
--    WHY THIS FIGURE WAS REVISED -- and the finding it produced.
--    The layer was first built assuming R340 per customer, based on a
--    high-touch programme: agent contact plus a R40 monthly discount held for
--    six months. Applied to this customer base, it returned "do not intervene"
--    for all 7,043 customers.
--
--    That result is retained here as a finding rather than discarded. The most
--    valuable customer in this book justifies spending at most R163 to retain,
--    and the average justifies R40. A retention programme costing R340 per
--    contact therefore cannot pay for itself on any customer in this business,
--    regardless of how well the model performs.
--
--    The commercial conclusion is specific: retention here must be low-cost and
--    automated. Agent-led campaigns with substantial discounts are not viable
--    at these customer values. The revision reflects that conclusion; it is not
--    an adjustment made to obtain a preferred answer.
--
-- 2. INTERVENTION SUCCESS RATE = 30%
--    Of customers who would otherwise have left, approximately three in ten
--    are retained when offered a deal. This is the assumption the layer is
--    most sensitive to, and it should be the first figure replaced with real
--    campaign data. Sensitivity to it is tested separately.
--
-- 3. COST IS INCURRED ON EVERY CUSTOMER CONTACTED
--    Including those who were never going to leave. The model's precision of
--    50.5% is therefore priced into the calculation rather than argued around:
--    a customer with a low churn probability generates cost with little
--    prospect of return, and the arithmetic rejects them automatically.
-- =====================================================================

CREATE OR REPLACE VIEW vw_intervention_economics AS
SELECT
    s.customer_id,
    s.clv,
    s.value_decile,
    s.churn_probability,
    s.churn_value,
    f.contract,
    f.tenure_band,

    -- Value expected to be lost if nothing is done.
    ROUND(s.churn_probability * s.clv, 2) AS value_at_risk,

    -- Value expected to be recovered by intervening: the value at risk,
    -- multiplied by the proportion of interventions that succeed.
    ROUND(s.churn_probability * s.clv * 0.30, 2) AS expected_value_saved,

    -- Assumption 1, stated as a column so it is visible in every output.
    60.00 AS intervention_cost,

    -- The decision figure: recovered value less the cost of pursuing it.
    ROUND((s.churn_probability * s.clv * 0.30) - 60.00, 2) AS net_value,

    -- The rule. Intervene only where the expected return exceeds the cost.
    CASE
        WHEN (s.churn_probability * s.clv * 0.30) - 60.00 > 0 THEN 'Intervene'
        ELSE 'Do not intervene'
    END AS decision

FROM customer_scores s
JOIN vw_customer_features f ON s.customer_id = f.customer_id;

