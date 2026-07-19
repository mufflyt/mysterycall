# Market concentration (HHI) covariates from KFF data

Adds a hospital/insurer **market-concentration** covariate to
mystery-caller office data, using the Kaiser Family Foundation (KFF)
published per-MSA Herfindahl-Hirschman Index (HHI). Market consolidation
is a plausible confounder of insurance-based access: in a highly
concentrated market a dominant system has more latitude to steer
scheduling by payer.

The HHI ranges 0-10000 (sum of squared percent market shares). The
Department of Justice / Federal Trade Commission Horizontal Merger
Guidelines classify markets as un-concentrated (\< 1000), moderately
concentrated (1000-1800), and highly concentrated (\> 1800); those
cut-points define `hhi_cat`. Modelling typically uses
`hhi_k = hhi / 1000` so a one-unit coefficient is "per 1000 HHI points,"
matching the `consolidation` study (`R/10_kff_exposure_sensitivity.R`).
