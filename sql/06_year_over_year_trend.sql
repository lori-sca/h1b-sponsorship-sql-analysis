-- ============================================================
-- QUERY 6 | Year-over-year sponsorship trend, 2020-2023
-- Tables   : lca_cases
-- Technique: CTE aggregation + LAG() window function
--            2020 rows show NULL for LAG columns (no prior year)
-- ============================================================
WITH annual_summary AS (
    SELECT
        CASE
            WHEN LEFT(SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
            ELSE NULL
        END                                                         AS role_group,
        FISCAL_YEAR,
        COUNT(*)                                                    AS total_filings,
        SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END)  AS certified,
        ROUND(
            SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0), 1
        )                                                           AS cert_rate_pct,
        ROUND(AVG(
            CASE WHEN CASE_STATUS = 'Certified' AND annual_wage_from > 0
                 THEN annual_wage_from ELSE NULL END
        ), 0)                                                       AS avg_wage_certified
    FROM lca_cases
    WHERE FISCAL_YEAR BETWEEN 2020 AND 2023
      AND LEFT(SOC_CODE, 2) IN ('11','13','15')
    GROUP BY role_group, FISCAL_YEAR
),
with_lag AS (
    SELECT
        role_group,
        FISCAL_YEAR,
        total_filings,
        certified,
        cert_rate_pct,
        avg_wage_certified,
        LAG(total_filings)      OVER (PARTITION BY role_group ORDER BY FISCAL_YEAR) AS prev_total,
        LAG(certified)          OVER (PARTITION BY role_group ORDER BY FISCAL_YEAR) AS prev_certified,
        LAG(avg_wage_certified) OVER (PARTITION BY role_group ORDER BY FISCAL_YEAR) AS prev_avg_wage
    FROM annual_summary
    WHERE role_group IS NOT NULL
)
SELECT
    role_group,
    FISCAL_YEAR,
    total_filings,
    certified,
    cert_rate_pct,
    avg_wage_certified,
    prev_total,
    total_filings - prev_total                                       AS filing_change_abs,
    ROUND((total_filings - prev_total) * 100.0 / NULLIF(prev_total, 0), 1) AS filing_change_pct,
    avg_wage_certified - prev_avg_wage                               AS wage_change_abs,
    ROUND((avg_wage_certified - prev_avg_wage) * 100.0
          / NULLIF(prev_avg_wage, 0), 1)                             AS wage_change_pct
FROM with_lag
ORDER BY role_group, FISCAL_YEAR;
