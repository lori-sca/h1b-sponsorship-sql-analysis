-- ============================================================
-- QUERY 5 | Industry sector analysis via NAICS join, 2020-2023
-- Tables   : lca_cases, employers, naics_industries
-- Technique: INNER JOIN + LEFT JOIN, CASE WHEN sector mapping
-- Note     : LEFT JOIN on naics_industries keeps employers whose
--            4- or 5-digit NAICS codes are not in the 6-digit
--            Census lookup (28.7% coverage gap). The
--            naics_unmatched column reports this openly.
-- ============================================================
WITH industry_tagged AS (
    SELECT
        CASE
            WHEN LEFT(lc.SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(lc.SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
            ELSE NULL
        END AS role_group,
        CASE
            WHEN LEFT(CAST(e.NAICS_CODE AS CHAR), 4) IN ('5415','5411') THEN 'IT & Computer Services'
            WHEN LEFT(CAST(e.NAICS_CODE AS CHAR), 4) = '5416'           THEN 'Management Consulting'
            WHEN LEFT(CAST(e.NAICS_CODE AS CHAR), 4) IN ('5112','5113') THEN 'Software Publishing'
            WHEN LEFT(CAST(e.NAICS_CODE AS CHAR), 2) = '52'             THEN 'Finance & Banking'
            WHEN LEFT(CAST(e.NAICS_CODE AS CHAR), 4) = '6113'           THEN 'Universities'
            WHEN LEFT(CAST(e.NAICS_CODE AS CHAR), 2) = '62'             THEN 'Healthcare'
            WHEN LEFT(CAST(e.NAICS_CODE AS CHAR), 2) = '54'             THEN 'Other Professional Services'
            ELSE 'Other / Unknown'
        END AS industry_sector,
        ni.INDUSTRY_NAME,
        lc.CASE_STATUS,
        lc.annual_wage_from
    FROM lca_cases lc
    JOIN employers e              ON lc.EMPLOYER_ID = e.EMPLOYER_ID
    LEFT JOIN naics_industries ni ON e.NAICS_CODE  = ni.NAICS_CODE
    WHERE lc.FISCAL_YEAR BETWEEN 2020 AND 2023
      AND LEFT(lc.SOC_CODE, 2) IN ('11','13','15')
)
SELECT
    role_group,
    industry_sector,
    COUNT(*)                                                    AS total_filings,
    SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END)  AS certified,
    ROUND(
        SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                           AS cert_rate_pct,
    ROUND(AVG(
        CASE WHEN CASE_STATUS = 'Certified' AND annual_wage_from > 0
             THEN annual_wage_from ELSE NULL END
    ), 0)                                                       AS avg_wage_certified,
    SUM(CASE WHEN INDUSTRY_NAME IS NULL THEN 1 ELSE 0 END)      AS naics_unmatched
FROM industry_tagged
WHERE role_group IS NOT NULL
GROUP BY role_group, industry_sector
ORDER BY role_group, total_filings DESC;
