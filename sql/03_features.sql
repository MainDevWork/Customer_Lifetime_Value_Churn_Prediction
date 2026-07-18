-- Feature engineering layer, built as views rather than tables.
-- 7,043 rows is small enough that speed is irrelevant, and a view means the
-- logic behind every feature is readable rather than baked into stored data.

CREATE OR REPLACE VIEW vw_customer_features AS
SELECT
    c.customer_id,

    -- ---------- raw fields carried through ----------
    c.tenure_months,
    b.monthly_charges,
    b.total_charges,
    s.contract,
    s.internet_service,
    c.churn_value,

    -- ---------- 1. tenure_band ----------
    -- Months are hard to act on; bands are how a retention team segments.
    -- Cut points chosen deliberately:
    --   0-12  New          -- first year, highest churn exposure
    --   13-36 Established  -- past the danger period, not yet entrenched
    --   37+   Loyal        -- beyond a full two-year contract cycle
    CASE
        WHEN c.tenure_months <= 12 THEN 'New'
        WHEN c.tenure_months <= 36 THEN 'Established'
        ELSE 'Loyal'
    END AS tenure_band,

    -- ---------- 2. has_internet ----------
    -- The key to the three-value problem. A customer with no internet cannot
    -- hold any of the six add-ons -- their zero means "never offered", not
    -- "declined". This flag is what separates those two cases.
    CASE WHEN s.internet_service = 'No' THEN 0 ELSE 1 END AS has_internet,

    -- ---------- 3. has_phone ----------
    CASE WHEN s.phone_service = 'Yes' THEN 1 ELSE 0 END AS has_phone,

    -- ---------- 4. addon_count ----------
    -- How many of the six optional services the customer holds, 0-6.
    -- Only 'Yes' counts. 'No internet service' scores 0, same as 'No' --
    -- which is why has_internet must be read alongside this. A customer
    -- with no internet scores 0 because nothing was ever available to them;
    -- a customer with internet scoring 0 declined all six. Different people.
    -- More products held usually means a harder relationship to walk away from.
    (CASE WHEN s.online_security   = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN s.online_backup     = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN s.device_protection = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN s.tech_support      = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN s.streaming_tv      = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN s.streaming_movies  = 'Yes' THEN 1 ELSE 0 END
    ) AS addon_count,

    -- ---------- 5. contract_risk ----------
    -- Ordered by how easily the customer can leave. Month-to-month can walk
    -- at any time; a two-year customer is contractually held.
    CASE s.contract
        WHEN 'Month-to-month' THEN 3
        WHEN 'One year'       THEN 2
        WHEN 'Two year'       THEN 1
    END AS contract_risk,

    -- ---------- 6. automatic_payment ----------
    -- Manual payers churn more: every payment is a fresh decision to keep
    -- paying. An automatic payer has to actively cancel.
    CASE WHEN b.payment_method LIKE '%automatic%' THEN 1 ELSE 0 END AS automatic_payment,

    -- ---------- 7. spend_band ----------
    -- Monthly charges grouped into three levels for segmentation and for the
    -- CLV work in 04_clv.sql.
    CASE
        WHEN b.monthly_charges <  35 THEN 'Low'
        WHEN b.monthly_charges <  70 THEN 'Medium'
        ELSE 'High'
    END AS spend_band

FROM customer c
JOIN billing b      ON c.customer_id = b.customer_id
JOIN subscription s ON c.customer_id = s.customer_id;
