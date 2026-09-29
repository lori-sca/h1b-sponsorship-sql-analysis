-- ============================================================
-- QUERY 8 | Robustness checks on the wage premium
-- Tables   : lca_cases, soc_occupations
-- Requires : MySQL 8+ (window functions in 8A/8B)
--
-- The headline finding uses MEAN offered wages: business roles
-- pay ~$15k more on average. These checks test whether that
-- premium survives (1) medians instead of means and
-- (2) removing IT managers from the business group.
--
-- Run order: 8C first (confirms the SOC 11-3021 code format
-- and shows whether the IT-manager slice is material),
-- then 8A and 8B.
-- Swap annual_wage_from -> annual_prevailing_wage to rerun
-- any check on prevailing wages.
-- ============================================================

-- ============================================================
-- QUERY 8C | Diagnostic: the IT-manager slice inside the
--            business group (RUN THIS FIRST)
-- Tables   : lca_cases, soc_occupations
-- Technique: CASE WHEN slice tagging, GROUP BY
-- Why      : SOC 11-3021 (Computer and Information Systems
--            Managers) sits in major group 11, so it is counted
--            inside "General Business". This shows how many
--            certified cases it holds and what it earns vs the
--            rest of the business group -- i.e. whether
--            removing it (8B) is material. A non-trivial count
--            in the IT-manager slice also confirms the
--            '11-3021' code format used in 8B.
-- ============================================================
SELECT
    CASE
        WHEN lc.SOC_CODE LIKE '11-3021%'
             OR so.SOC_TITLE LIKE 'Computer and Information Systems Managers%'
            THEN 'IT managers (SOC 11-3021)'
        ELSE 'Rest of business group (11/13)'
    END                                            AS slice,
    COUNT(*)                                       AS certified_cases,
    ROUND(AVG(lc.annual_wage_from), 0)             AS mean_offered_wage
FROM lca_cases lc
LEFT JOIN soc_occupations so ON lc.SOC_CODE = so.SOC_CODE
WHERE lc.FISCAL_YEAR BETWEEN 2020 AND 2023
  AND lc.CASE_STATUS = 'Certified'
  AND LEFT(lc.SOC_CODE, 2) IN ('11','13')
  AND lc.annual_wage_from > 0
GROUP BY slice
ORDER BY slice;

-- ============================================================
-- QUERY 8A | Robustness check 1: median vs mean offered wage
--            by role group and year (certified, 2020-2023)
-- Tables   : lca_cases
-- Technique: window functions (ROW_NUMBER + COUNT OVER) for
--            exact medians; conditional aggregation for the
--            year-level premium
-- Why      : means are sensitive to outliers (see
--            docs/methodology.md). If the premium holds on
--            medians, it is not an outlier artifact.
-- ============================================================
WITH base AS (
    SELECT
        FISCAL_YEAR,
        CASE
            WHEN LEFT(SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
        END AS role_group,
        annual_wage_from
    FROM lca_cases
    WHERE FISCAL_YEAR BETWEEN 2020 AND 2023
      AND CASE_STATUS = 'Certified'
      AND LEFT(SOC_CODE, 2) IN ('11','13','15')
      AND annual_wage_from > 0
),
ranked AS (
    SELECT
        FISCAL_YEAR,
        role_group,
        annual_wage_from,
        ROW_NUMBER() OVER (
            PARTITION BY FISCAL_YEAR, role_group
            ORDER BY annual_wage_from
        ) AS rn,
        COUNT(*) OVER (PARTITION BY FISCAL_YEAR, role_group) AS n
    FROM base
),
medians AS (
    -- middle row (odd n) or mean of two middle rows (even n)
    SELECT
        FISCAL_YEAR,
        role_group,
        ROUND(AVG(annual_wage_from), 0) AS median_wage
    FROM ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY FISCAL_YEAR, role_group
),
group_stats AS (
    SELECT
        b.FISCAL_YEAR,
        b.role_group,
        COUNT(*)                          AS certified_cases,
        ROUND(AVG(b.annual_wage_from), 0) AS mean_wage,
        MAX(m.median_wage)                AS median_wage
    FROM base b
    JOIN medians m USING (FISCAL_YEAR, role_group)
    GROUP BY b.FISCAL_YEAR, b.role_group
)
SELECT
    FISCAL_YEAR AS year,
    MAX(CASE WHEN role_group = 'General Business' THEN certified_cases END) AS biz_cases,
    MAX(CASE WHEN role_group = 'Data & Analytics' THEN certified_cases END) AS data_cases,
    MAX(CASE WHEN role_group = 'General Business' THEN mean_wage END)   AS biz_mean,
    MAX(CASE WHEN role_group = 'Data & Analytics' THEN mean_wage END)   AS data_mean,
    MAX(CASE WHEN role_group = 'General Business' THEN mean_wage END)
      - MAX(CASE WHEN role_group = 'Data & Analytics' THEN mean_wage END) AS mean_premium,
    MAX(CASE WHEN role_group = 'General Business' THEN median_wage END) AS biz_median,
    MAX(CASE WHEN role_group = 'Data & Analytics' THEN median_wage END) AS data_median,
    MAX(CASE WHEN role_group = 'General Business' THEN median_wage END)
      - MAX(CASE WHEN role_group = 'Data & Analytics' THEN median_wage END) AS median_premium
FROM group_stats
GROUP BY FISCAL_YEAR
ORDER BY FISCAL_YEAR;

-- ============================================================
-- QUERY 8B | Robustness check 2: wage premium with IT managers
--            removed from the business group
-- Tables   : lca_cases, soc_occupations
-- Technique: same median/mean machinery as 8A, plus an
--            exclusion filter on SOC 11-3021
-- Why      : if the premium collapses without SOC 11-3021, it
--            is carried by tech managers, not true business
--            roles. If it holds, the finding is stronger.
-- Note     : code format assumed '11-3021' (hyphenated); the
--            SOC_TITLE match is a fallback for variants like
--            '113021'. 8C confirms which format the data uses.
-- ============================================================
WITH base AS (
    SELECT
        lc.FISCAL_YEAR,
        CASE
            WHEN LEFT(lc.SOC_CODE, 2) IN ('11','13') THEN 'General Business'
            WHEN LEFT(lc.SOC_CODE, 2) = '15'         THEN 'Data & Analytics'
        END AS role_group,
        lc.annual_wage_from
    FROM lca_cases lc
    LEFT JOIN soc_occupations so ON lc.SOC_CODE = so.SOC_CODE
    WHERE lc.FISCAL_YEAR BETWEEN 2020 AND 2023
      AND lc.CASE_STATUS = 'Certified'
      AND LEFT(lc.SOC_CODE, 2) IN ('11','13','15')
      AND lc.annual_wage_from > 0
      AND lc.SOC_CODE NOT LIKE '11-3021%'
      AND (so.SOC_TITLE IS NULL
           OR so.SOC_TITLE NOT LIKE 'Computer and Information Systems Managers%')
),
ranked AS (
    SELECT
        FISCAL_YEAR,
        role_group,
        annual_wage_from,
        ROW_NUMBER() OVER (
            PARTITION BY FISCAL_YEAR, role_group
            ORDER BY annual_wage_from
        ) AS rn,
        COUNT(*) OVER (PARTITION BY FISCAL_YEAR, role_group) AS n
    FROM base
),
medians AS (
    SELECT
        FISCAL_YEAR,
        role_group,
        ROUND(AVG(annual_wage_from), 0) AS median_wage
    FROM ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY FISCAL_YEAR, role_group
),
group_stats AS (
    SELECT
        b.FISCAL_YEAR,
        b.role_group,
        COUNT(*)                          AS certified_cases,
        ROUND(AVG(b.annual_wage_from), 0) AS mean_wage,
        MAX(m.median_wage)                AS median_wage
    FROM base b
    JOIN medians m USING (FISCAL_YEAR, role_group)
    GROUP BY b.FISCAL_YEAR, b.role_group
)
SELECT
    FISCAL_YEAR AS year,
    MAX(CASE WHEN role_group = 'General Business' THEN certified_cases END) AS biz_cases,
    MAX(CASE WHEN role_group = 'Data & Analytics' THEN certified_cases END) AS data_cases,
    MAX(CASE WHEN role_group = 'General Business' THEN mean_wage END)
      - MAX(CASE WHEN role_group = 'Data & Analytics' THEN mean_wage END) AS mean_premium_excl_it_mgrs,
    MAX(CASE WHEN role_group = 'General Business' THEN median_wage END)
      - MAX(CASE WHEN role_group = 'Data & Analytics' THEN median_wage END) AS median_premium_excl_it_mgrs
FROM group_stats
GROUP BY FISCAL_YEAR
ORDER BY FISCAL_YEAR;
