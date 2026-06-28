# Extract one exposure-term row from a fitted mysterycall model

Returns a list with elements `cell` (formatted character string), `n`
(integer), `aic` (numeric), and `type` (label such as "OR", "IRR", or
"beta").

## Usage

``` r
.extract_st_row(model, exposure_term, digits)
```

## Arguments

- model:

  A `mysterycall_logistic_model`, `mysterycall_poisson_model`,
  `mysterycall_nb_model`, or `mysterycall_lmm` object.

- exposure_term:

  Character scalar. Term name to look up.

- digits:

  Integer. Decimal places for estimates and CIs.
