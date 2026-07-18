-- Populates the four tables from the raw spreadsheet, registered as "raw".
-- Load order matters: geography first, because customer points at it.

-- 1. geography
-- The spreadsheet has 7,043 rows but only 1,652 zip codes -- each zip repeats
-- once per customer living there. SELECT DISTINCT collapses that down to one
-- row per zip. Verified: every zip maps to exactly one city/latitude/longitude,
-- so no zip can produce two conflicting rows.
INSERT INTO geography (zip_code, city, latitude, longitude)
SELECT DISTINCT
    "Zip Code",
    "City",
    "Latitude",
    "Longitude"
FROM raw;

-- 2. customer
-- One row per customer, all 7,043 loaded. No DISTINCT -- CustomerID is already unique.
-- churn_reason arrives NULL for the 5,174 retained customers. That is correct and
-- is left as-is: a customer who has not left has no reason for leaving.
-- churn_score and cltv are loaded but excluded from the feature set (see 01_schema.sql).
INSERT INTO customer (
    customer_id,
    zip_code,
    gender,
    senior_citizen,
    partner,
    dependents,
    tenure_months,
    churn_label,
    churn_value,
    churn_reason,
    churn_score,
    cltv
)
SELECT
    "CustomerID",
    "Zip Code",
    "Gender",
    "Senior Citizen",
    "Partner",
    "Dependents",
    "Tenure Months",
    "Churn Label",
    "Churn Value",
    "Churn Reason",
    "Churn Score",
    "CLTV"
FROM raw;

-- 3. subscription
-- One row per customer, one-to-one with customer.
-- All ten service fields loaded verbatim -- no encoding, no collapsing.
-- The three-value problem ('Yes' / 'No' / 'No internet service') is handled
-- explicitly in 03_features.sql so the decision stays visible.
INSERT INTO subscription (
    customer_id,
    phone_service,
    multiple_lines,
    internet_service,
    online_security,
    online_backup,
    device_protection,
    tech_support,
    streaming_tv,
    streaming_movies,
    contract
)
SELECT
    "CustomerID",
    "Phone Service",
    "Multiple Lines",
    "Internet Service",
    "Online Security",
    "Online Backup",
    "Device Protection",
    "Tech Support",
    "Streaming TV",
    "Streaming Movies",
    "Contract"
FROM raw;

-- 4. billing
-- total_charges arrives as TEXT because 11 records hold a blank.
-- TRY_CAST returns NULL instead of erroring when a value cannot be read as a number.
-- COALESCE then turns that NULL into 0.00.
-- Those 11 are new customers with tenure 0, not yet billed -- zero is the true
-- value, not a missing one. All 11 records are retained.
INSERT INTO billing (
    customer_id,
    paperless_billing,
    payment_method,
    monthly_charges,
    total_charges
)
SELECT
    "CustomerID",
    "Paperless Billing",
    "Payment Method",
    CAST("Monthly Charges" AS DECIMAL(10,2)),
    COALESCE(TRY_CAST("Total Charges" AS DECIMAL(10,2)), 0.00)
FROM raw;

