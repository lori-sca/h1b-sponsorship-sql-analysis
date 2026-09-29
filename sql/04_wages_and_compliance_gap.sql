-- ============================================================
-- QUERY 4A | Wage and compliance gap by role group, certified, 2020-2023
-- Tables   : lca_cases, soc_occupations
-- Technique: LEFT JOIN, CASE WHEN, AVG, conditional SUM
-- Note     : annual_wage_from, annual_prevailing_wage and
--            wage_compliance_gap are derived columns created
--            during import (see docs/methodology.md)
-- ============================================================
WITH role_wages AS (
    SELECT
        CASE
            WHEN LEFT(lc.SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(lc.SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
            ELSE NULL
        END AS role_group,
        lc.annual_wage_from,
        lc.annual_prevailing_wage,
        lc.wage_compliance_gap,
        lc.PW_WAGE_LEVEL,
        so.SOC_TITLE
    FROM lca_cases lc
    LEFT JOIN soc_occupations so ON lc.SOC_CODE = so.SOC_CODE
    WHERE lc.FISCAL_YEAR BETWEEN 2020 AND 2023
      AND lc.CASE_STATUS = 'Certified'
      AND LEFT(lc.SOC_CODE, 2) IN ('11','13','15')
      AND lc.annual_wage_from > 0
      AND lc.annual_prevailing_wage > 0
)
SELECT
    role_group,
    COUNT(*)                                        AS certified_cases,
    ROUND(AVG(annual_wage_from), 0)                 AS avg_offered_wage,
    ROUND(AVG(annual_prevailing_wage), 0)           AS avg_prevailing_wage,
    ROUND(AVG(wage_compliance_gap), 0)              AS avg_compliance_gap,
    ROUND(
        AVG(wage_compliance_gap) / NULLIF(AVG(annual_prevailing_wage), 0) * 100,
    1)                                              AS gap_pct_of_prevailing,
    SUM(CASE WHEN wage_compliance_gap < 0 THEN 1 ELSE 0 END) AS below_prevailing_count,
    ROUND(
        SUM(CASE WHEN wage_compliance_gap < 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0),
    3)                                              AS below_prevailing_pct
FROM role_wages
GROUP BY role_group
ORDER BY role_group;

-- ============================================================
-- QUERY 4B | Prevailing wage level distribution by role group, certified, 2020-2023
-- Tables   : lca_cases
-- Technique: CASE WHEN pivot on PW_WAGE_LEVEL
-- Note     : PW_WAGE_LEVEL values are bare Roman numerals
--            (I / II / III / IV), not "Level I" strings.
--            Confirmed with a diagnostic query first.
-- ============================================================
WITH role_levels AS (
    SELECT
        CASE
            WHEN LEFT(SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
            ELSE NULL
        END AS role_group,
        PW_WAGE_LEVEL
    FROM lca_cases
    WHERE FISCAL_YEAR BETWEEN 2020 AND 2023
      AND CASE_STATUS = 'Certified'
      AND LEFT(SOC_CODE, 2) IN ('11','13','15')
)
SELECT
    role_group,
    COUNT(*)                                                    AS total,
    SUM(CASE WHEN PW_WAGE_LEVEL = 'I'   THEN 1 ELSE 0 END)      AS level_I,
    SUM(CASE WHEN PW_WAGE_LEVEL = 'II'  THEN 1 ELSE 0 END)      AS level_II,
    SUM(CASE WHEN PW_WAGE_LEVEL = 'III' THEN 1 ELSE 0 END)      AS level_III,
    SUM(CASE WHEN PW_WAGE_LEVEL = 'IV'  THEN 1 ELSE 0 END)      AS level_IV,
    SUM(CASE WHEN PW_WAGE_LEVEL IS NULL THEN 1 ELSE 0 END)      AS level_null,
    ROUND(SUM(CASE WHEN PW_WAGE_LEVEL = 'I'   THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_I,
    ROUND(SUM(CASE WHEN PW_WAGE_LEVEL = 'II'  THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_II,
    ROUND(SUM(CASE WHEN PW_WAGE_LEVEL = 'III' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_III,
    ROUND(SUM(CASE WHEN PW_WAGE_LEVEL = 'IV'  THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_IV
FROM role_levels
GROUP BY role_group
ORDER BY role_group;
