# Articles

### Getting Started

- [Getting Started with
  mysterycall](https://mufflyt.github.io/mysterycall/articles/getting_started.md):

- [Searching the NPI Database Starting with Taxonomy
  Codes](https://mufflyt.github.io/mysterycall/articles/my-vignette.md):

  A comprehensive guide with examples on searching the NPI Database
  using taxonomy codes.

- [Mystery Caller Workflow: From Raw Data to
  Manuscript](https://mufflyt.github.io/mysterycall/articles/mystery-caller-workflow.md):

- [Aggregating Provider Data for
  Analysis](https://mufflyt.github.io/mysterycall/articles/aggregating_provider_data.md):

  Build an analysis-ready provider table by combining roster,
  enrichment, geography, and call-outcome data.

- [Pipeline
  Guarantees](https://mufflyt.github.io/mysterycall/articles/pipeline-guarantees.md):

- [End-to-End Mystery-Caller Workflow
  Orchestration](https://mufflyt.github.io/mysterycall/articles/workflow-orchestration.md):

  Run the complete mystery-caller pipeline in one call with
  mysterycall_run_workflow(), or step through Phase 1 cleaning,
  caller-list splitting, Phase 2 cleaning, quality-check export, and
  coverage monitoring individually.

### Data Collection

- [Search and Process NPI
  Numbers](https://mufflyt.github.io/mysterycall/articles/search_and_process_npi.md):

  Search the NPI registry from clinician first and last names using the
  current mysterycall interface.

### Data Quality

- [Data Quality: Phone Validation, Name Parsing, and Safe
  Joins](https://mufflyt.github.io/mysterycall/articles/data-quality.md):

  How to validate NANP phone numbers, parse physician names into
  structured components, and perform audited joins that guard against
  row duplication and coverage loss.

- [Data Cleaning: A Complete Workflow for Mystery Caller
  Studies](https://mufflyt.github.io/mysterycall/articles/data-cleaning.md):

  End-to-end data cleaning for mystery caller studies: NPI validation,
  phone validation, address normalization, Phase 1 and Phase 2 log
  cleaning, duplicate detection, and clinician data retrieval.

### Demographics

- [Getting Data from the US Census Bureau for
  Isochrones](https://mufflyt.github.io/mysterycall/articles/get_census_data.md):

  A wrapper on the amazing censusapi package to get US Census Bureau
  data for women only.

- [Provider Classification and Demographic
  Enrichment](https://mufflyt.github.io/mysterycall/articles/provider-classification.md):

  Classify providers by practice setting, urban/rural geography, census
  region, and specialty. Impute physician age from graduation year.
  Backfill gender from the Genderize.io API. Prepare a Table 1-ready
  data frame.

### Analysis and Reporting

- [A matched-pair mystery-caller
  analysis](https://mufflyt.github.io/mysterycall/articles/matched-pair-analysis.md):

- [Designing a matched-control mystery-caller
  audit](https://mufflyt.github.io/mysterycall/articles/matched-control-design.md):

- [Design, power, and cleaning tools from three audit
  studies](https://mufflyt.github.io/mysterycall/articles/audit-study-tools.md):

- [Statistical Analysis of Mystery-Caller
  Data](https://mufflyt.github.io/mysterycall/articles/statistical-analysis.md):

  Poisson mixed-effects regression for wait-time analysis, disparity
  metrics across insurance types, bootstrap confidence intervals, and
  multiple- comparison adjustment for mystery-caller studies.

- [Linear Mixed Models for Wait-Time
  Analysis](https://mufflyt.github.io/mysterycall/articles/linear-mixed-models.md):

  When and how to use mysterycall_lmm() for appointment wait-time
  outcomes, including auto-log transforms, geometric mean ratios,
  Poisson sensitivity analysis, and the calendar vs. business-day
  comparison.

- [Logistic Model: Appointment Offered
  (Yes/No)](https://mufflyt.github.io/mysterycall/articles/logistic-model.md):

- [Adding Physician Covariates to the Wait-Time
  Model](https://mufflyt.github.io/mysterycall/articles/adding-covariates.md):

- [Power Analysis and Sample Size for Mystery Caller
  Studies](https://mufflyt.github.io/mysterycall/articles/power-analysis.md):

- [Generating Publication
  Tables](https://mufflyt.github.io/mysterycall/articles/table-generation.md):

  Build Table 1 (baseline characteristics), percentage tables, disparity
  summaries, and export-ready PDFs from mystery-caller study data.

- [Writing the Results
  Section](https://mufflyt.github.io/mysterycall/articles/writing-results-section.md):

  Assemble a ready-to-paste manuscript Results section from
  mysterycall’s prose builders, with every direction word tied to the
  sign of the data so the narrative can never contradict the tables.

- [Assembling supplementary digital
  content](https://mufflyt.github.io/mysterycall/articles/supplementary-digital-content.md):

- [Subspecialist density per 100,000
  women](https://mufflyt.github.io/mysterycall/articles/subspecialist-density.md):
