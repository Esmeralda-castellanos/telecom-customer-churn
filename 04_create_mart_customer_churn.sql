CREATE OR REPLACE TABLE
  `telecom-customer-churn-498313.telecom_churn_db.mart_customer_churn` AS
SELECT
  -- Keys
  c.customer_id,

  -- Demographics
  c.gender,
  c.age,
  CASE
    WHEN c.age < 30 THEN 'Under 30'
    WHEN c.age BETWEEN 30 AND 44 THEN '30-44'
    WHEN c.age BETWEEN 45 AND 59 THEN '45-59'
    WHEN c.age >= 60 THEN '60+'
    ELSE 'Unknown'
  END AS age_group,
  c.married,
  c.number_of_dependents,

  -- Location
  c.city,
  CAST(c.zip_code AS STRING) AS zip_code,
  c.latitude,
  c.longitude,
  z.population AS zipcode_population,

  -- Referrals & tenure
  c.number_of_referrals,
  c.tenure_months,
  CASE
    WHEN c.tenure_months < 6 THEN '0-5 months'
    WHEN c.tenure_months BETWEEN 6 AND 11 THEN '6-11 months'
    WHEN c.tenure_months BETWEEN 12 AND 23 THEN '12-23 months'
    WHEN c.tenure_months BETWEEN 24 AND 47 THEN '24-47 months'
    WHEN c.tenure_months >= 48 THEN '48+ months'
    ELSE 'Unknown'
  END AS tenure_band,

  -- Offers & services
  c.offer,
  c.phone_service,
  c.avg_long_distance_charges,
  c.multiple_lines,
  c.internet_service,
  c.internet_type,
  c.avg_monthly_gb_download,
  c.online_security,
  c.online_backup,
  c.device_protection_plan,
  c.premium_tech_support,
  c.streaming_tv,
  c.streaming_movies,
  c.streaming_music,
  c.unlimited_data,

  -- Simple count of subscribed extras (for profiling)
  (
    CAST(c.phone_service           AS INT64) +
    CAST(c.internet_service        AS INT64) +
    CAST(c.online_security         AS INT64) +
    CAST(c.online_backup           AS INT64) +
    CAST(c.device_protection_plan  AS INT64) +
    CAST(c.premium_tech_support    AS INT64) +
    CAST(c.streaming_tv            AS INT64) +
    CAST(c.streaming_movies        AS INT64) +
    CAST(c.streaming_music         AS INT64) +
    CAST(c.unlimited_data          AS INT64)
  ) AS number_of_services,

  -- Contract & billing
  c.contract,
  c.paperless_billing,
  c.payment_method,

  -- Charges & revenue
  c.monthly_charge_raw,
  c.monthly_charge_clean,
  c.total_charges,
  c.total_refunds,
  c.total_extra_data_charges,
  c.total_long_distance_charges,
  c.total_revenue,

  -- Basic value segment on total_revenue
  CASE
    WHEN c.total_revenue >= 3000 THEN 'High value'
    WHEN c.total_revenue BETWEEN 1000 AND 2999.99 THEN 'Medium value'
    WHEN c.total_revenue < 1000 THEN 'Low value'
    ELSE 'Unknown'
  END AS value_segment,

  -- Churn status fields
  c.customer_status,
  c.churn_category,
  c.churn_reason,
  c.is_churned,
  c.is_stayed,
  c.is_joined

FROM
  `telecom-customer-churn-498313.telecom_churn_db.clean_customer_churn` AS c
LEFT JOIN
  `telecom-customer-churn-498313.telecom_churn_db.clean_zipcode_population` AS z
ON CAST(c.zip_code AS STRING) = z.zip_code;

SELECT COUNT(*) AS mart_row_count,
       COUNT(DISTINCT customer_id) AS distinct_customer_ids
FROM `telecom-customer-churn-498313.telecom_churn_db.mart_customer_churn`;

-- Age groups
SELECT age_group, COUNT(*) AS customers
FROM `telecom-customer-churn-498313.telecom_churn_db.mart_customer_churn`
GROUP BY age_group
ORDER BY customers DESC;

-- Tenure bands
SELECT tenure_band, COUNT(*) AS customers
FROM `telecom-customer-churn-498313.telecom_churn_db.mart_customer_churn`
GROUP BY tenure_band
ORDER BY customers DESC;

-- Value segments
SELECT value_segment, COUNT(*) AS customers
FROM `telecom-customer-churn-498313.telecom_churn_db.mart_customer_churn`
GROUP BY value_segment
ORDER BY customers DESC;