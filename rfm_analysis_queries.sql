-- step 1:Append all montly sales table together--

    CREATE OR REPLACE TABLE `rfmanalysis-489700.Sales.Sales_2025` AS 
    SELECT * FROM `rfmanalysis-489700.Sales.Sales202501`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202502`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202503`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202504`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202505`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202506`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202507`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202508`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202509`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202510`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202511`
    UNION ALL SELECT * FROM `rfmanalysis-489700.Sales.Sales202512`
    ;

-- step2:calculate recency,frequency,monetary r, f, m  ranks--

    CREATE OR REPLACE VIEW `rfmanalysis-489700.Sales.rfm_metrics` AS
    WITH current_date AS(
      SELECT DATE('2026-03-30') AS analysis_date   -- todays date


    ),
    rfm AS(
      SELECT 
      CustomerID,
      Max(OrderDate) AS last_order_date,
      date_diff((Select analysis_date from current_date ), Max(OrderDate),DAY) AS recency,
      COUNT(*) AS frequency,
      SUM(OrderValue) as monetary
      from `rfmanalysis-489700.Sales.Sales_2025`
      group by CustomerID
    )

    SELECT 
    rfm.*,
    ROW_NUMBER() OVER(ORDER BY recency ASC) as r_rank,
     ROW_NUMBER() OVER(ORDER BY frequency desc) as f_rank,
     ROW_NUMBER() OVER(ORDER BY monetary desc) as m_rank
     FROM rfm;

    -- Step 3:Assing declies(10=best,1=worst)

    CREATE OR REPLACE VIEW `rfmanalysis-489700.Sales.rfm_scores`
    AS 
    SELECT 
    *,
    NTILE(10) OVER(ORDER BY r_rank DESC) as r_score,
    NTILE(10) OVER(ORDER BY f_rank DESC) as f_score,
    NTILE(10) OVER(ORDER BY m_rank DESC) as m_score
    from `rfmanalysis-489700.Sales.rfm_metrics`;

-- step4:Total score

CREATE OR REPLACE VIEW `rfmanalysis-489700.Sales.rfm_total_scores`
as
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  (r_score+f_score+m_score)as rfm_total_score
  from `rfmanalysis-489700.Sales.rfm_scores`
  ORDER BY rfm_total_score DESC;
  
-- Step 5:BI Ready rfm segments table


CREATE OR REPLACE TABLE  `rfmanalysis-489700.Sales.rfm_segments_final`
AS
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  rfm_total_score,
  CASE
    WHEN rfm_total_score >=28 then 'Champions'
   WHEN rfm_total_score >=24 then 'Loyal VIPs'
   WHEN rfm_total_score >=20 then 'Potential Loyalists'
  WHEN rfm_total_score >=16 then 'Promising'
    WHEN rfm_total_score >=12 then 'Engaged'
    WHEN rfm_total_score >=8 then 'Requires Attention'
    WHEN rfm_total_score >=4 then 'At Risk'
     else 'Lost/Inactive'
    end as rfm_segment
    from `rfmanalysis-489700.Sales.rfm_total_scores`
    oRder by rfm_total_score DESC;


