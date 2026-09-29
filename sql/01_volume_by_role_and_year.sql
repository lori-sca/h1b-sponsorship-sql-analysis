-- ============================================================
-- QUERY 1 | Sponsorship volume by role group and year
-- Tables   : lca_cases
-- Technique: CTE, CASE WHEN role tagging, conditional SUM,
--            GROUP BY, NULLIF division guard
-- Role groups are defined by SOC major group:
--   11, 13 = General Business | 15 = Data & Analytics
-- ============================================================
WITH role_tagged AS (
    SELECT
        FISCAL_YEAR,
        CASE
            WHEN LEFT(SOC_CODE, 2) IN ('11', '13') THEN 'General Business'
            WHEN LEFT(SOC_CODE, 2) = '15'          THEN 'Data & Analytics'
            ELSE 'Other'
        END AS role_group,
        CASE_STATUS
    FROM lca_cases
)
SELECT
    role_group,
    FISCAL_YEAR,
    COUNT(*)                                                    AS total_filings,
    SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END)  AS certified,
    SUM(CASE WHEN CASE_STATUS = 'Denied'    THEN 1 ELSE 0 END)  AS denied,
    ROUND(
        SUM(CASE WHEN CASE_STATUS = 'Certified' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0),
    1)                                                          AS cert_rate_pct
FROM role_tagged
GROUP BY role_group, FISCAL_YEAR
ORDER BY role_group, FISCAL_YEAR;
