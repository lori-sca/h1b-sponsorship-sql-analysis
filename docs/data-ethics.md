# Responsible use of H-1B disclosure data

DOL publishes certified labor condition applications because the Immigration and Nationality Act (Section 212(n)) requires it, so that wage compliance can be checked. That purpose sets the line. Uses that support accountability are defensible. Uses that turn the data into commercial surveillance, competitive intelligence or targeting of individuals are not. The workers in this data never agreed to commercial use of their occupation and wage details.

## Where the data helps

- **Wage compliance monitoring.** This is what the data exists for. The analysis found 74 data and analytics cases and 9 business cases certified with an offered wage below the prevailing wage floor. That is a very low rate, and a useful signal in itself.
- **Closing the information gap for visa-dependent workers.** International candidates struggle to tell which employers reliably sponsor. Making public employer filings readable for the workers those employers want to hire fits the program's protective intent.
- **Fraud research.** Query 3 surfaced a cluster of generic-named LLCs with hundreds of filings, near-total withdrawal and no tech employment base. Surfacing patterns like this and referring them to enforcement is a legitimate protective use.

## Where it can cause harm

- **Employer surveillance.** Wage and worksite fields add up to a map of each employer's hiring by role, place and pay band. A competitor could use it to poach talent or undercut wages. Anyone monetizing LCA data should disclose that purpose and give employers a way to correct errors in their records.
- **Re-identification without names.** At a small employer, employer + occupation code + worksite state + wage level can narrow down to one or two people. DOL does not minimize the public file, so secondary products need to check this risk.
- **Misleading rankings.** A tool that ranks Cognizant first by volume would mislead a candidate who doesn't know that volume reflects IT staffing placements, not direct hiring. The score would be accurate and misleading at the same time. Any scoring tool needs to disclose how it works and what it cannot predict.
- **Bias from the occupation codes.** SOC codes don't cleanly separate business roles from technical ones, and 28.7% of industry codes don't match the Census lookup. A recruiting model trained on this data would undercount the business-role market and steer candidates away from it.

## Five practices for any team using this data

1. **Publish a plain-language methodology** for any score or ranking: years covered, how roles were classified, what it measures and what it does not.
2. **Minimize small-employer records.** For employers with fewer than 50 filings in a year, suppress worksite city and county in anything published.
3. **Resolve entities before ranking.** The HCL case shows how a naive name match hides a 20-point difference in denial rates. Document and version the matching logic, and audit it.
4. **Review retention yearly.** Archive records older than seven years and keep them out of active scoring. Pre-pandemic denial rates don't predict post-pandemic outcomes.
5. **Name a data ethics owner** with authority to review new uses before launch, together with legal and risk.

## Sources

- Edquist, A., Grennan, L., Griffiths, S., & Rowshankish, K. (2022). *Data ethics: What it means and what it takes.* McKinsey & Company.
- Immigration and Nationality Act, 8 U.S.C. § 1182(n).
- U.S. Department of Labor, Office of Foreign Labor Certification, LCA disclosure data FY2020-FY2024.
