--- preview of customer churn
SELECT * 
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
LIMIT 1000;

--- row count of customer churn
SELECT COUNT(*) AS churn_row_count
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`;

--- Churn distinct values for key categorical columns
SELECT DISTINCT `Customer Status`
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`;

SELECT DISTINCT `Churn Category`, `Churn Reason`
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
ORDER BY `Churn Category`, `Churn Reason`;

SELECT DISTINCT Contract
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
ORDER BY Contract;

SELECT DISTINCT `Payment Method`
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
ORDER BY `Payment Method`;

--- uniqness of Customer ID, total rows vs distinct
-- total rows vs distinct customer IDs
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT `Customer ID`) AS distinct_customer_ids
FROM  `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`;

--- Check for missing status in customer
SELECT COUNT(*) AS missing_status
FROM  `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
WHERE SAFE.TRIM(`Customer Status`) IS NULL
  OR SAFE.TRIM(`Customer Status`) = ' ';

--- Churned customers missing category or reason
SELECT COUNT(*) AS churned_missing_reason
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
WHERE SAFE.TRIM(`Customer Status`) = 'Churned'
  AND (SAFE.TRIM(`Churn Category`) IS NULL OR SAFE.TRIM(`Churn Category`) = ''
       OR SAFE.TRIM(`Churn Reason`) IS NULL OR SAFE.TRIM(`Churn Reason`) = '');

-- Negative or zero ages
SELECT `Customer ID`, Age
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
WHERE SAFE_CAST(Age AS INT64) IS NULL
   OR SAFE_CAST(Age AS INT64) <= 0;

-- Negative or suspicious Monthly Charge
SELECT `Customer ID`, `Monthly Charge`
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
WHERE SAFE_CAST(`Monthly Charge` AS NUMERIC) < 0
   OR SAFE_CAST(`Monthly Charge` AS NUMERIC) IS NULL;

-- Check Total Charges and Total Revenue
SELECT
  `Customer ID`,
  `Total Charges`,
  `Total Revenue`
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`
WHERE SAFE_CAST(`Total Charges` AS NUMERIC) < 0
   OR SAFE_CAST(`Total Revenue` AS NUMERIC) < 0
   OR SAFE_CAST(`Total Charges` AS NUMERIC) IS NULL
   OR SAFE_CAST(`Total Revenue` AS NUMERIC) IS NULL;

--- checks for data dictionary
SELECT *
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_data_dictionary`
LIMIT 20;
-- row count
SELECT COUNT(*) AS row_count
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_data_dictionary`;
-- see all columns defined for the churn table
SELECT
  string_field_0 AS table_name,
  string_field_1 AS field,
  string_field_2 AS description
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_data_dictionary`
WHERE string_field_0 = 'Customer Churn'
ORDER BY field;

--- check for zipcode population data
SELECT *
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_zipcode_population`
LIMIT 20;

-- row count zipcode
SELECT COUNT(*) AS row_count
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_zipcode_population`;

--missing zipcodes
SELECT COUNT(*) AS missing_zip
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_zipcode_population`
WHERE `Zip Code` IS NULL;

-- duplicates
SELECT `Zip Code`, COUNT(*) AS cnt
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_zipcode_population`
GROUP BY `Zip Code`
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

--- check for population values
SELECT `Zip Code`, Population
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_zipcode_population`
WHERE SAFE_CAST(Population AS INT64) IS NULL
   OR SAFE_CAST(Population AS INT64) < 0;

--- overlap between customer table and population table
-- Zip codes that appear in customer table but not in population table
SELECT DISTINCT c.`Zip Code` AS customer_zip
FROM `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn` AS c
LEFT JOIN `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_zipcode_population` AS z
  ON c.`Zip Code` = z.`Zip Code`
WHERE z.`Zip Code` IS NULL
ORDER BY customer_zip;

--- creation of clean_customer_churn table
CREATE OR REPLACE TABLE
  `telecom-customer-churn-498313.telecom_churn_db.clean_customer_churn` AS
SELECT
  -- Keys & demographics
  `Customer ID`                         AS customer_id,
  Gender                                AS gender,
  SAFE_CAST(Age AS INT64)              AS age,
  Married                               AS married,
  SAFE_CAST(`Number of Dependents` AS INT64) AS number_of_dependents,

  -- Location
  City                                  AS city,
  `Zip Code`                            AS zip_code,
  SAFE_CAST(Latitude AS FLOAT64)       AS latitude,
  SAFE_CAST(Longitude AS FLOAT64)      AS longitude,

  -- Referrals & tenure
  SAFE_CAST(`Number of Referrals` AS INT64) AS number_of_referrals,
  SAFE_CAST(`Tenure in Months` AS INT64)    AS tenure_months,

  -- Offers & services
  Offer                                 AS offer,
  `Phone Service`                       AS phone_service,
  SAFE_CAST(`Avg Monthly Long Distance Charges` AS NUMERIC)
                                        AS avg_long_distance_charges,
  `Multiple Lines`                      AS multiple_lines,
  `Internet Service`                    AS internet_service,
  `Internet Type`                       AS internet_type,
  SAFE_CAST(`Avg Monthly GB Download` AS NUMERIC)
                                        AS avg_monthly_gb_download,
  `Online Security`                     AS online_security,
  `Online Backup`                       AS online_backup,
  `Device Protection Plan`              AS device_protection_plan,
  `Premium Tech Support`                AS premium_tech_support,
  `Streaming TV`                        AS streaming_tv,
  `Streaming Movies`                    AS streaming_movies,
  `Streaming Music`                     AS streaming_music,
  `Unlimited Data`                      AS unlimited_data,

  -- Contract & billing
  Contract                              AS contract,
  `Paperless Billing`                   AS paperless_billing,
  `Payment Method`                      AS payment_method,

  -- Charges & revenue (raw)
  SAFE_CAST(`Monthly Charge` AS NUMERIC)       AS monthly_charge_raw,
  SAFE_CAST(`Total Charges` AS NUMERIC)        AS total_charges,
  SAFE_CAST(`Total Refunds` AS NUMERIC)        AS total_refunds,
  SAFE_CAST(`Total Extra Data Charges` AS NUMERIC)
                                             AS total_extra_data_charges,
  SAFE_CAST(`Total Long Distance Charges` AS NUMERIC)
                                             AS total_long_distance_charges,
  SAFE_CAST(`Total Revenue` AS NUMERIC)       AS total_revenue,

  -- Cleaned monthly charge (negatives set to 0)
  CASE
    WHEN SAFE_CAST(`Monthly Charge` AS NUMERIC) < 0
      THEN 0
    ELSE SAFE_CAST(`Monthly Charge` AS NUMERIC)
  END AS monthly_charge_clean,

  -- Churn status
  `Customer Status`                      AS customer_status,
  `Churn Category`                       AS churn_category,
  `Churn Reason`                         AS churn_reason,

  -- Binary flags
  CASE WHEN `Customer Status` = 'Churned' THEN 1 ELSE 0 END AS is_churned,
  CASE WHEN `Customer Status` = 'Stayed'  THEN 1 ELSE 0 END AS is_stayed,
  CASE WHEN `Customer Status` = 'Joined'  THEN 1 ELSE 0 END AS is_joined

FROM
  `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_customer_churn`;

SELECT COUNT(*) AS row_count
FROM `telecom-customer-churn-498313.telecom_churn_db.clean_customer_churn`;

--Create clean_zipcode_population
CREATE OR REPLACE TABLE
  `telecom-customer-churn-498313.telecom_churn_db.clean_zipcode_population` AS
SELECT
  CAST(`Zip Code` AS STRING) AS zip_code,
  CAST(Population AS INT64)  AS population
FROM
  `telecom-customer-churn-498313.telecom_churn_db.raw_telecom_zipcode_population`;

-- validate
SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT zip_code) AS distinct_zipcodes
FROM `telecom-customer-churn-498313.telecom_churn_db.clean_zipcode_population`;


--- join check on the clean tables
SELECT
  COUNT(*) AS total_customers,
  COUNTIF(z.zip_code IS NOT NULL) AS customers_with_population,
  COUNTIF(z.zip_code IS NULL)     AS customers_without_population
FROM `telecom-customer-churn-498313.telecom_churn_db.clean_customer_churn` c
LEFT JOIN `telecom-customer-churn-498313.telecom_churn_db.clean_zipcode_population` z
  ON CAST(c.zip_code AS STRING) = z.zip_code;
