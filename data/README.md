# Data

The raw data is too large for GitHub (about 3.5 million rows), so it is not stored here. Both sources are public.

| File | Source | Notes |
|---|---|---|
| H-1B LCA disclosure data, 2020-2024 | [Kaggle: zongaobian/h1b-lca-disclosure-data-2020-2024](https://www.kaggle.com/datasets/zongaobian/h1b-lca-disclosure-data-2020-2024) | Compiled from the [DOL OFLC quarterly disclosure files](https://www.dol.gov/agencies/eta/foreign-labor/performance), which are the authoritative source |
| 2022 NAICS six-digit codes | [U.S. Census Bureau](https://www.census.gov/naics/2022NAICS/6-digit_2022_Codes.xlsx) | Used as the `naics_industries` lookup table |

After import, `lca_cases` holds 3,471,247 H-1B filings. See [docs/methodology.md](../docs/methodology.md) for the filters and derived columns.
