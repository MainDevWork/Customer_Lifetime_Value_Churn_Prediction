-- Source is a flat 33-column extract, 7,043 rows, one row per customer
-- The four-table split is a deliberate modelling choice, not inherited from the source
-- Engine is DuckDB

DROP TABLE IF EXISTS billing;
DROP TABLE IF EXISTS subscription;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS geography;

-- 1. Createing the geography table 
CREATE TABLE geography (
    zip_code   INTEGER  NOT NULL,
    city       VARCHAR  NOT NULL,
    latitude   DOUBLE   NOT NULL,
    longitude  DOUBLE   NOT NULL,
    PRIMARY KEY (zip_code)
);

-- 2. Creating the customer table
CREATE TABLE customer (
    customer_id     VARCHAR  NOT NULL,
    zip_code        INTEGER  NOT NULL,

    gender          VARCHAR  NOT NULL,
    senior_citizen  VARCHAR  NOT NULL,
    partner         VARCHAR  NOT NULL,
    dependents      VARCHAR  NOT NULL,

    tenure_months   INTEGER  NOT NULL,

    churn_label     VARCHAR  NOT NULL,
    churn_value     INTEGER  NOT NULL,

    -- Populated only for the 1,869 churned customers, NULL otherwise.
    -- Excluded from model features: post-outcome information, would leak the target.
    -- Retained for Power BI drill-down.
    churn_reason    VARCHAR,

    -- EXCLUDED FROM FEATURES -- <your reasoning here>
    churn_score     INTEGER,

    -- REJECTED AS A VALUE MEASURE -- <your reasoning here>
    cltv            INTEGER,

    PRIMARY KEY (customer_id),
    FOREIGN KEY (zip_code) REFERENCES geography (zip_code)
);

-- 3. Creating the subscription table
CREATE TABLE subscription (
    customer_id        VARCHAR  NOT NULL,

    phone_service      VARCHAR  NOT NULL,
    multiple_lines     VARCHAR  NOT NULL,
    internet_service   VARCHAR  NOT NULL,

    online_security    VARCHAR  NOT NULL,
    online_backup      VARCHAR  NOT NULL,
    device_protection  VARCHAR  NOT NULL,
    tech_support       VARCHAR  NOT NULL,
    streaming_tv       VARCHAR  NOT NULL,
    streaming_movies   VARCHAR  NOT NULL,

    contract           VARCHAR  NOT NULL,

    PRIMARY KEY (customer_id),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);

-- 4. Creating the billing table
CREATE TABLE billing (
    customer_id        VARCHAR         NOT NULL,

    paperless_billing  VARCHAR         NOT NULL,
    payment_method     VARCHAR         NOT NULL,

    monthly_charges    DECIMAL(10, 2)  NOT NULL,
    total_charges      DECIMAL(10, 2)  NOT NULL,

    PRIMARY KEY (customer_id),
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
);
