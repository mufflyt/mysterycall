# mysterycall_descriptive_stats sentence snapshot

    Code
      result$sentence
    Output
      [1] "Median business_days: 12.00 (IQR: 10--16)."

# mysterycall_distribution_summary sentence snapshot

    Code
      result$sentence
    Output
      [1] "The most common insurance was Blue Cross/Blue Shield (n = 30/N = 60, 50.0%)."

# mysterycall_distribution_summary scenario column sentence snapshot

    Code
      result$sentence
    Output
      [1] "The most common scenario was HIP scenario (n = 21/N = 60, 35.0%)."

# mysterycall_demographics_sentence sentence snapshot

    Code
      result
    Output
      [1] "In our dataset, the most common physician gender was Male (n = 31/N = 60, 51.7%)."
      attr(,"stats")
      attr(,"stats")$gender
      attr(,"stats")$gender$level
      [1] "Male"
      
      attr(,"stats")$gender$count
      [1] 31
      
      attr(,"stats")$gender$total
      [1] 60
      
      attr(,"stats")$gender$pct
      [1] 51.66667
      
      
      attr(,"stats")$subspecialty
      NULL
      
      attr(,"stats")$credential
      NULL
      

# mysterycall_wait_time_sentence sentence snapshot

    Code
      result$sentence
    Output
      [1] "The median wait time across all insurance was 12 business days (IQR: 10–16). Specifically, the median wait time was 12 days (IQR: 10–15) for Blue Cross/Blue Shield, 12 days (IQR: 10–16) for Medicaid. The p-value for Medicaid vs Blue Cross/Blue Shield was 0.746."

# mysterycall_insurance_wait_sentence sentence snapshot

    Code
      result$sentence
    Output
      [1] "Medicaid patients experienced a 2% longer wait compared to patients with Blue Cross/Blue Shield (Incidence Rate Ratio: 1.02; 95% CI: 0.89–1.18; p 0.746) with median wait times of 12 business days (IQR: 10–16) and 12 business days (IQR: 10–15) respectively."

# mysterycall_scenario_summary sentence snapshot (generic levels)

    Code
      result$sentence
    Output
      [1] "There were 60 calls across 3 scenarios: HIP scenario (n=21), KNEE scenario (n=20), SHOULDER scenario (n=19)."

# mysterycall_scenario_summary sentence snapshot (named levels)

    Code
      result$sentence
    Output
      [1] "There were 60 calls, with sports medicine orthopedists specializing in 21 hip, 19 shoulder, and 20 knee."

# mysterycall_sensitivity_both_insurance sentence snapshot

    Code
      result$sentence
    Output
      [1] "Of 30 physicians called, 30 (100.0%) were called under both Medicaid and Blue Cross/Blue Shield. Among these physicians, mean wait times were 13.1 days (SD 4.1) for Medicaid vs 12.8 days (SD 3.9) for BCBS (t-test p = 0.747)."

# mysterycall_overdispersion_sentence sentence snapshot

    Code
      result$sentence
    Output
      [1] "The Pearson dispersion ratio is 1.25 (chi-square = 72.68, df = 58, p = 0.093). Mild overdispersion detected (ratio = 1.25), below the negative-binomial switch threshold; the Poisson model may still be adequate."

# mysterycall_r2_sentence sentence snapshot

    Code
      result$sentence
    Output
      [1] "The marginal R² value of the model is 0.001 and the conditional R² value is 0.217. The marginal R² represents the proportion of variance explained by the fixed effects ((Intercept), insuranceMedicaid) alone (0.1%). The conditional R² represents the proportion of variance explained by both the fixed effects and the random effects (id_number) combined (21.7%)."

# mysterycall_random_effect_variance sentence snapshot

    Code
      result$sentence
    Output
      [1] "The intraclass correlation (ICC) of the model for the random effect group 'id_number' is 0.216. An ICC of 0.216 is considered low, suggesting that most variance is at the individual level rather than between groups of 'id_number'."

# mysterycall_sample_demographics summary_sentence snapshot

    Code
      result$summary_sentence
    Output
      [1] "Our sample included 60 calls to physician offices from 10 states, excluding Alabama, Alaska, Arizona, Arkansas, Connecticut, Delaware, Hawaii, Idaho, Indiana, Iowa, Kansas, Kentucky, Louisiana, Maine, Maryland, Massachusetts, Minnesota, Mississippi, Missouri, Montana, Nebraska, Nevada, New Hampshire, New Jersey, New Mexico, North Carolina, North Dakota, Oklahoma, Oregon, Pennsylvania, Rhode Island, South Carolina, South Dakota, Tennessee, Utah, Vermont, Washington, West Virginia, Wisconsin, Wyoming and District of Columbia."

