# Methodology

## Dataset

The primary source is the H-1B Labor Condition Application (LCA) disclosure data published by the U.S. Department of Labor, Office of Foreign Labor Certification. Every employer that wants to sponsor an H-1B worker has to file an LCA, and DOL publishes them so workers, researchers and regulators can check that employers pay at least the prevailing wage. That makes it a full population record, not a sample.

I used the 2020-2024 version compiled on [Kaggle by Zongao Bian](https://www.kaggle.com/datasets/zongaobian/h1b-lca-disclosure-data-2020-2024): about 3.5 million rows and 96 columns covering the employer, worksite, occupation code and title, offered wage, prevailing wage, visa subclass and final outcome.

A second source, the [U.S. Census Bureau 2022 NAICS six-digit code file](https://www.census.gov/naics/2022NAICS/6-digit_2022_Codes.xlsx) (about 1,000 rows), gives the official industry name for each employer's industry code.

**Role groups** are defined by Standard Occupational Classification (SOC) major group:

- General Business: SOC 11 (management) and 13 (business and financial operations)
- Data & Analytics: SOC 15 (computer and mathematical)

**Analysis window:** 2020-2023. 2024 covers only about nine months, so 2023 is the latest complete year. The result also contained a few leftover rows dated 2016-2018 (old cases that appeared in the newer files with no final outcome), which I excluded.

## Normalization

The raw file is one flat table. An employer with 10,000 filings stores its name, city, state, postal code and industry code 10,000 times. City depends on the employer, not on the case, which breaks third normal form. The same problem applies to worksites and occupation titles.

I split it into five tables:

| Table | Role | Key | Why it is separate |
|---|---|---|---|
| `lca_cases` | Fact table, one row per filing | `CASE_NUMBER` | Case-level facts: status, wages, flags, derived columns |
| `employers` | Employer dimension | `EMPLOYER_ID` (surrogate) | Built by de-duplicating name + city + state + postal code. Holds `NAICS_CODE` as a foreign key |
| `worksites` | Worksite dimension | `WORKSITE_ID` (surrogate) | Built by de-duplicating city + county + state + postal code |
| `soc_occupations` | Occupation lookup | `SOC_CODE` | Title depends only on the code |
| `naics_industries` | Industry lookup | `NAICS_CODE` | Loaded from the Census file, so every code has its official name |

What this makes possible: employer analysis groups on an ID instead of string matching (which breaks on spacing, capitalization and encoding differences across years), geography filters without string operations, and industry comparisons through one join.

![Entity relationship diagram](../visuals/erd.png)

## Cleaning decisions

I fixed all six decisions before processing so results could not shape the rules.

1. **Keep H-1B only.** The raw file also includes E-3 (Australia) and H-1B1 (Chile, Singapore) filings, which follow different legal standards and would blur H-1B employer behavior.
2. **Keep every case status.** Certified, Denied, Withdrawn and Certified-Withdrawn all stay, because denial and withdrawal patterns are part of the question. Filtering to Certified would overstate employer success.
3. **Keep identical rows.** Each row is a real filing, and filing volume is the measure of sponsorship activity. De-duplicating would undercount high-volume sponsors.
4. **Annualize wages.** Wages come in hourly, weekly, bi-weekly, monthly or annual units. Derived columns `annual_wage_from` and `annual_prevailing_wage` convert them using 2,080 (40 hours x 52 weeks), 52, 26, 12 and 1.
5. **Wage compliance gap.** `wage_compliance_gap = annual_wage_from - annual_prevailing_wage`. A negative value on a certified case means the offered wage is below the legal floor: a filing error, a later correction, or a missed compliance failure.
6. **Year.** `FISCAL_YEAR` holds the calendar year of `RECEIVED_DATE`, not the October-September government fiscal year. The source files are split by calendar year, and matching them avoids false jumps in the year-over-year trend. (The column name is kept from the original build.)

## Excluded columns (47)

| Group | Count | Why excluded |
|---|---|---|
| Employer point of contact | 14 | Describes who receives DOL mail, not the employer's behavior |
| Attorney and agent, plus related legal fields | 17 + 3 | Describes the filer's counsel, not the petition |
| Form preparer | 5 | Describes form completion, not the job |
| Attestation checkboxes | 3 | Same value on every compliant filing, so no variation |
| Prevailing wage source metadata | 5 | Where the floor came from, not the floor itself (kept) |
| Street addresses | varies | All geography in this analysis is at city and state level |

## Known limitations

- Averages rather than medians throughout.
- Legal entities are not consolidated to parent companies in the data (Deloitte, PwC, HCL appear several times).
- 28.7% of employers have 4- or 5-digit NAICS codes with no six-digit match. Kept with a `LEFT JOIN` and reported per sector.
- SOC coding is inconsistent for business roles, so the business-role market is likely undercounted.
- A few data and analytics employers show average wages above $500,000 caused by extreme outliers in small counts. These were left out of wage comparisons.
