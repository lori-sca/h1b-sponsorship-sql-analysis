-- ============================================================
-- QUERY 3 | Denial rate among high-volume sponsors, 2020-2023
-- Tables   : lca_cases, employers
-- Technique: JOIN, conditional aggregation,
--            HAVING minimum volume threshold (>= 200 filings)
-- ============================================================
WITH role_filings AS (
    SELECT
        lc.EMPLOYER_ID,
        CASE
            WHEN LEFT(lc.SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(lc.SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
            ELSE NULL
        END AS role_group,
        lc.CASE_STATUS,
        lc.FISCAL_YEAR
    FROM lca_cases lc
    WHERE lc.FISCAL_YEAR BETWEEN 2020 AND 2023
      AND LEFT(lc.SOC_CODE, 2) IN ('11','13','15')
),
employer_rates AS (
    SELECT
        rf.role_group,
        e.EMPLOYER_NAME,
        e.EMPLOYER_STATE,
        COUNT(*)                                                        AS total_filings,
        SUM(CASE WHEN rf.CASE_STATUS = 'Certified' THEN 1 ELSE 0 END)   AS certified,
        SUM(CASE WHEN rf.CASE_STATUS = 'Denied'    THEN 1 ELSE 0 END)   AS denied,
        ROUND(
            SUM(CASE WHEN rf.CASE_STATUS = 'Denied' THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0), 1
        )                                                               AS denial_rate_pct,
        ROUND(
            SUM(CASE WHEN rf.CASE_STATUS = 'Certified' THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0), 1
        )                                                               AS cert_rate_pct,
        COUNT(DISTINCT rf.FISCAL_YEAR)                                  AS years_active
    FROM role_filings rf
    JOIN employers e ON rf.EMPLOYER_ID = e.EMPLOYER_ID
    GROUP BY rf.role_group, e.EMPLOYER_NAME, e.EMPLOYER_STATE
    HAVING COUNT(*) >= 200
)
SELECT
    role_group,
    EMPLOYER_NAME,
    EMPLOYER_STATE,
    total_filings,
    certified,
    denied,
    denial_rate_pct,
    cert_rate_pct,
    years_active
FROM employer_rates
ORDER BY role_group, denial_rate_pct DESC;
