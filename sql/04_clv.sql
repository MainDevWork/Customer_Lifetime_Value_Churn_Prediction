-- 04_clv.sql
-- Customer lifetime value.
--
-- The CLTV field supplied with the dataset was rejected during profiling: it is
-- bounded 2,003-6,500 while total charges reach 8,684 (a lifetime value below
-- revenue already collected is impossible for a currency measure), and it shows
-- almost no correlation with its own inputs -- monthly charges 0.11, tenure 0.37.
-- It is a synthetic score, not money. CLV is therefore derived here from first
-- principles and is NOT validated against that field.
--
-- =====================================================================
-- ASSUMPTIONS -- NOT DERIVED FROM THE DATA. STATED EXPLICITLY.
-- =====================================================================
-- 1. GROSS MARGIN = 30%
--    Revenue is not profit. Network, support, billing and hardware costs are
--    not in this dataset, so a margin is assumed. 30% is within the normal
--    range for telecommunications operators. Any figure used here would be an
--    assumption; this one is at least a defensible one.
--
-- 2. EXPECTED REMAINING TENURE, BY CONTRACT TYPE
--    Month-to-month  12 months
--    One year        24 months
--    Two year        36 months
--    The dataset is a single snapshot with no dates, so true expected tenure
--    cannot be calculated -- survival analysis requires a time dimension that
--    does not exist here. Contract type is used as the proxy because it is the
--    strongest available signal of commitment, supported by the observed churn
--    rates in 03_features.sql.
--
-- 3. NO DISCOUNTING APPLIED
--    Future money is worth less than money today. Over horizons of 36 months
--    or less, at these amounts, discounting does not change any intervention
--    decision. Omitted deliberately.
--
-- 4. Amounts are treated as rands for presentation purposes.
-- =====================================================================

CREATE OR REPLACE VIEW vw_customer_clv AS
SELECT
    f.*,

    -- Assumption 2 above, made explicit as a column so it can be inspected.
    CASE f.contract
        WHEN 'Month-to-month' THEN 12
        WHEN 'One year'       THEN 24
        WHEN 'Two year'       THEN 36
    END AS expected_remaining_months,

    -- Profit already earned from this customer to date.
    ROUND(f.total_charges * 0.30, 2) AS historic_margin,

    -- Forward-looking value: monthly revenue x margin x expected months remaining.
    ROUND(
        f.monthly_charges * 0.30 *
        CASE f.contract
            WHEN 'Month-to-month' THEN 12
            WHEN 'One year'       THEN 24
            WHEN 'Two year'       THEN 36
        END
    , 2) AS clv

FROM vw_customer_features f;

----------------------------------------------------------------------------------------

-- Value decile: customers split into ten equal-sized groups by CLV.
-- 1 = highest value, 10 = lowest.
-- Deciles rather than raw amounts because intervention decisions are made on
-- rank ("who are our top customers"), not on absolute figures.
CREATE OR REPLACE VIEW vw_customer_value_segments AS
SELECT
    v.*,
    NTILE(10) OVER (ORDER BY v.clv DESC) AS value_decile
FROM vw_customer_clv v;
