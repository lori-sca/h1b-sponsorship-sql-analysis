-- ============================================================
-- QUERY 2 | Top 20 employers by role group, certified cases, 2020-2023
-- Tables   : lca_cases, employers
-- Technique: JOIN, CASE WHEN, RANK() window function, 3-CTE chain
-- Note     : groups by employer name + state, so several
--            EMPLOYER_IDs with the same name and state are combined
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
employer_summary AS (
    SELECT
        rf.role_group,
        e.EMPLOYER_NAME,
        e.EMPLOYER_STATE,
        COUNT(*)                                                        AS total_filings,
        SUM(CASE WHEN rf.CASE_STATUS = 'Certified' THEN 1 ELSE 0 END)   AS certified,
        COUNT(DISTINCT rf.FISCAL_YEAR)                                  AS years_active,
        ROUND(
            SUM(CASE WHEN rf.CASE_STATUS = 'Certified' THEN 1 ELSE 0 END)
            * 100.0 / NULLIF(COUNT(*), 0), 1
        )                                                               AS cert_rate_pct
    FROM role_filings rf
    JOIN employers e ON rf.EMPLOYER_ID = e.EMPLOYER_ID
    GROUP BY rf.role_group, e.EMPLOYER_NAME, e.EMPLOYER_STATE
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY role_group ORDER BY certified DESC) AS employer_rank
    FROM employer_summary
)
SELECT
    role_group,
    employer_rank,
    EMPLOYER_NAME,
    EMPLOYER_STATE,
    total_filings,
    certified,
    years_active,
    cert_rate_pct
FROM ranked
WHERE employer_rank <= 20
ORDER BY role_group, employer_rank;
