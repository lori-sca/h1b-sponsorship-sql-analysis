-- ============================================================
-- QUERY 7 | Durable sponsors present in all 4 years, 2020-2023
-- Tables   : lca_cases, employers, worksites
-- Technique: 3-CTE chain, HAVING COUNT(DISTINCT FISCAL_YEAR) = 4
--            to enforce continuity, ROW_NUMBER() window function
--            to find each employer's dominant worksite state
-- Note     : groups by EMPLOYER_ID (name + city + state + postal
--            code), so one company can appear as several entries
-- ============================================================
WITH role_filings AS (
    SELECT
        lc.EMPLOYER_ID,
        lc.WORKSITE_ID,
        CASE
            WHEN LEFT(lc.SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(lc.SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
            ELSE NULL
        END AS role_group,
        lc.CASE_STATUS,
        lc.annual_wage_from,
        lc.FISCAL_YEAR
    FROM lca_cases lc
    WHERE lc.FISCAL_YEAR BETWEEN 2020 AND 2023
      AND LEFT(lc.SOC_CODE, 2) IN ('11','13','15')
),
durable_employers AS (
    SELECT
        role_group,
        EMPLOYER_ID,
        COUNT(*)                                                    AS total_filings,
        SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END)  AS certified,
        COUNT(DISTINCT FISCAL_YEAR)                                 AS years_active,
        ROUND(
            SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0), 1
        )                                                           AS cert_rate_pct,
        ROUND(AVG(
            CASE WHEN CASE_STATUS = 'Certified' AND annual_wage_from > 0
                 THEN annual_wage_from ELSE NULL END
        ), 0)                                                       AS avg_wage
    FROM role_filings
    WHERE role_group IS NOT NULL
    GROUP BY role_group, EMPLOYER_ID
    HAVING COUNT(DISTINCT FISCAL_YEAR) = 4
       AND COUNT(*) >= 200
),
dominant_worksite AS (
    SELECT
        rf.EMPLOYER_ID,
        rf.role_group,
        ws.WORKSITE_STATE,
        ROW_NUMBER() OVER (
            PARTITION BY rf.EMPLOYER_ID, rf.role_group
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM role_filings rf
    JOIN worksites ws ON rf.WORKSITE_ID = ws.WORKSITE_ID
    WHERE rf.role_group IS NOT NULL
    GROUP BY rf.EMPLOYER_ID, rf.role_group, ws.WORKSITE_STATE
)
SELECT
    de.role_group,
    e.EMPLOYER_NAME,
    e.EMPLOYER_STATE,
    dw.WORKSITE_STATE AS top_worksite_state,
    de.total_filings,
    de.certified,
    de.cert_rate_pct,
    de.avg_wage,
    de.years_active
FROM durable_employers de
JOIN employers e ON de.EMPLOYER_ID = e.EMPLOYER_ID
LEFT JOIN dominant_worksite dw
       ON de.EMPLOYER_ID = dw.EMPLOYER_ID
      AND de.role_group  = dw.role_group
      AND dw.rn = 1
ORDER BY de.role_group, de.certified DESC;
