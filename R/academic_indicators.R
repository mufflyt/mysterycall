#' Academic Practice Indicators for Institution Classification
#'
#' High-confidence indicators for distinguishing academic vs. non-academic
#' practice settings. Includes pattern-based name matching, known institution
#' lists, and a weighted scoring system across multiple evidence tiers.
#'
#' @details
#' Evidence-based indicators with calibrated confidence scores:
#' \itemize{
#'   \item ACGME residency/fellowship programs (0.98-0.99)
#'   \item COTH (Council of Teaching Hospitals) membership (0.95)
#'   \item Medical school affiliations (0.97)
#'   \item NIH CTSA awards (0.99)
#'   \item NCI cancer center designations (0.98)
#'   \item Medicare GME payments (0.95)
#' }
#'
#' @return No return value. Documentation topic grouping related indicator
#'   constants and helpers; see each function or data object's own help page.
#' @examples
#' # Topic group; see individual constant/function help pages for examples.
#' head(KNOWN_ACADEMIC_INSTITUTIONS)
#' @name academic_indicators
NULL

#' Known Academic Medical Centers
#'
#' High-confidence list of major academic institution name patterns for string
#' matching. Includes Tier 1 (major research universities), Tier 2 (university
#' hospitals), and Tier 3 (academic medical centers).
#'
#' @format Character vector of institution name patterns. Matches are performed
#'   case-insensitively using \code{grepl(fixed = TRUE)}.
#'
#' @return A character vector of institution name patterns used for academic
#'   affiliation classification.
#' @examples
#' head(KNOWN_ACADEMIC_INSTITUTIONS)
#' @seealso \code{\link{mysterycall_check_academic_name_patterns}},
#'   \code{\link{ACADEMIC_HOSPITAL_PATTERNS}}
#' @family academic-indicators
KNOWN_ACADEMIC_INSTITUTIONS <- c(
  "JOHNS HOPKINS", "MAYO CLINIC", "CLEVELAND CLINIC", "MASSACHUSETTS GENERAL",
  "BRIGHAM", "STANFORD", "UCLA", "UCSF", "M D ANDERSON", "MEMORIAL SLOAN",
  "MOUNT SINAI", "NEW YORK PRESBYTERIAN", "COLUMBIA UNIVERSITY",
  "UNIVERSITY OF", "UNIVERSITY HOSPITAL", "UNIVERSITY MEDICAL CENTER",
  "ACADEMIC MEDICAL CENTER", "TEACHING HOSPITAL", "CHILDREN'S HOSPITAL",
  "MEDICAL COLLEGE", "HEALTH SCIENCE CENTER"
)

#' Academic Hospital Name Patterns
#'
#' Tiered list of string patterns indicating academic hospital affiliation,
#' organized by confidence level: very_high (0.95-0.99), high (0.85-0.94),
#' and moderate (0.75-0.84).
#'
#' @format Named list with three character vector elements:
#'   \describe{
#'     \item{very_high}{Patterns at confidence 0.95 (e.g., "SCHOOL OF MEDICINE").}
#'     \item{high}{Patterns at confidence 0.90 (e.g., "UNIVERSITY HOSPITAL").}
#'     \item{moderate}{Patterns at confidence 0.80 (e.g., "MEDICAL CENTER").}
#'   }
#'
#' @return A named list of character vectors of hospital name patterns,
#'   grouped by confidence tier.
#' @examples
#' names(ACADEMIC_HOSPITAL_PATTERNS)
#' ACADEMIC_HOSPITAL_PATTERNS$very_high
#' @seealso \code{\link{mysterycall_check_academic_name_patterns}},
#'   \code{\link{KNOWN_ACADEMIC_INSTITUTIONS}}
#' @family academic-indicators
#' @export
ACADEMIC_HOSPITAL_PATTERNS <- list(
  very_high = c(
    "UNIVERSITY OF", "MEDICAL SCHOOL", "SCHOOL OF MEDICINE",
    "TEACHING HOSPITAL", "ACADEMIC MEDICAL CENTER", "ACADEMIC HEALTH CENTER"
  ),
  high = c(
    "UNIVERSITY HOSPITAL", "UNIVERSITY MEDICAL", "MEDICAL COLLEGE",
    "COLLEGE OF MEDICINE", "HEALTH SCIENCE CENTER", "CHILDREN'S HOSPITAL"
  ),
  moderate = c(
    "MEDICAL CENTER", "REGIONAL MEDICAL CENTER", "ACADEMIC"
  )
)

#' ACGME Program Indicators
#'
#' String patterns indicating ACGME-accredited residency or fellowship programs.
#' Confidence: 0.98-0.99.
#'
#' @format Character vector of ACGME-related text patterns.
#'
#' @return A character vector of ACGME-related patterns indicating accredited
#'   residency or fellowship programs.
#' @examples
#' ACGME_PROGRAM_INDICATORS
#' @seealso \code{\link{mysterycall_classify_academic_affiliation}}
#' @family academic-indicators
ACGME_PROGRAM_INDICATORS <- c(
  "RESIDENCY PROGRAM", "FELLOWSHIP PROGRAM", "GRADUATE MEDICAL EDUCATION",
  "GME PROGRAM", "TRAINING PROGRAM"
)

#' COTH (Council of Teaching Hospitals) Indicators
#'
#' String patterns indicating Council of Teaching Hospitals membership.
#' Confidence: 0.95.
#'
#' @format Character vector of COTH-related text patterns.
#'
#' @return A character vector of patterns indicating Council of Teaching
#'   Hospitals membership.
#' @examples
#' COTH_TEACHING_INDICATORS
#' @seealso \code{\link{mysterycall_classify_academic_affiliation}}
#' @family academic-indicators
COTH_TEACHING_INDICATORS <- c(
  "TEACHING HOSPITAL", "COUNCIL OF TEACHING HOSPITALS",
  "COTH MEMBER", "AAMC MEMBER"
)

#' Medical School Affiliation Patterns
#'
#' String patterns indicating medical school affiliation. Confidence: 0.97.
#'
#' @format Character vector of medical school text patterns.
#'
#' @return A character vector of patterns indicating medical school
#'   affiliation.
#' @examples
#' MEDICAL_SCHOOL_INDICATORS
#' @seealso \code{\link{mysterycall_classify_academic_affiliation}}
#' @family academic-indicators
MEDICAL_SCHOOL_INDICATORS <- c(
  "SCHOOL OF MEDICINE", "MEDICAL SCHOOL", "COLLEGE OF MEDICINE",
  "MEDICAL COLLEGE", "AFFILIATED WITH.*MEDICAL SCHOOL",
  "AFFILIATED WITH.*UNIVERSITY"
)

#' NIH CTSA Hub Patterns
#'
#' String patterns for NIH Clinical and Translational Science Award hub
#' institutions. All CTSA hubs are academic medical centers.
#' Confidence: 0.99.
#'
#' @format Character vector of CTSA-related text patterns.
#'
#' @return A character vector of patterns indicating NIH Clinical and
#'   Translational Science Award hub institutions.
#' @examples
#' NIH_CTSA_HUBS
#' @seealso \code{\link{mysterycall_classify_academic_affiliation}}
#' @family academic-indicators
NIH_CTSA_HUBS <- c(
  "CTSA HUB",
  "CLINICAL AND TRANSLATIONAL SCIENCE AWARD",
  "TRANSLATIONAL SCIENCE CENTER"
)

#' NCI-Designated Cancer Center Patterns
#'
#' String patterns for National Cancer Institute designated cancer centers.
#' Confidence: 0.98.
#'
#' @format Character vector of NCI cancer center text patterns.
#'
#' @return A character vector of patterns indicating NCI-designated cancer
#'   centers.
#' @examples
#' NCI_CANCER_CENTERS
#' @seealso \code{\link{mysterycall_classify_academic_affiliation}}
#' @family academic-indicators
NCI_CANCER_CENTERS <- c(
  "NCI-DESIGNATED", "COMPREHENSIVE CANCER CENTER",
  "CANCER CENTER", "CANCER INSTITUTE"
)

#' Medicare GME Payment Indicators
#'
#' String patterns for Graduate Medical Education payment indicators. Only
#' teaching hospitals receive GME payments. Confidence: 0.95.
#'
#' @format Character vector of Medicare GME text patterns.
#'
#' @return A character vector of patterns indicating Graduate Medical
#'   Education payments (only teaching hospitals receive these).
#' @examples
#' MEDICARE_GME_INDICATORS
#' @seealso \code{\link{mysterycall_classify_academic_affiliation}}
#' @family academic-indicators
#' @export
MEDICARE_GME_INDICATORS <- c(
  "GME PAYMENTS", "GRADUATE MEDICAL EDUCATION PAYMENTS",
  "DIRECT GME", "INDIRECT MEDICAL EDUCATION", "IME PAYMENTS"
)

#' Check if Organization Name Suggests Academic Affiliation
#'
#' Evaluates organization names against known academic institutions and tiered
#' pattern lists to determine academic affiliation probability. Returns the
#' highest confidence match found.
#'
#' @param org_name Character vector of organization names to evaluate.
#' @param confidence_threshold Numeric. Minimum confidence level to classify as
#'   academic. Scores below this threshold are zeroed out. Default: \code{0.85}.
#'
#' @return Data frame with one row per input name and columns:
#'   \describe{
#'     \item{academic_indicator}{Logical. TRUE if name matches an academic
#'       pattern at or above the confidence threshold.}
#'     \item{confidence_score}{Numeric. Highest confidence score (0.0-0.99).}
#'     \item{matched_pattern}{Character. Description of the matching pattern.
#'       NA if no match.}
#'   }
#'
#' @examples
#' mysterycall:::mysterycall_check_academic_name_patterns(c("Johns Hopkins Hospital",
#'                                "Community Hospital",
#'                                "University of Michigan Medical Center"))
#'
#' @seealso [mysterycall_classify_academic_affiliation()]
#' @family academic-indicators
#' @export
mysterycall_check_academic_name_patterns <- function(org_name, confidence_threshold = 0.85) {
  if (is.null(org_name) || length(org_name) == 0) {
    return(data.frame(
      academic_indicator = logical(0),
      confidence_score   = numeric(0),
      matched_pattern    = character(0)
    ))
  }

  org_upper <- trimws(toupper(org_name))
  n <- length(org_name)
  results <- data.frame(
    academic_indicator = rep(FALSE, n),
    confidence_score   = rep(0.0, n),
    matched_pattern    = rep(NA_character_, n),
    stringsAsFactors   = FALSE
  )

  for (institution in KNOWN_ACADEMIC_INSTITUTIONS) {
    matches <- grepl(institution, org_upper, fixed = TRUE)
    results$academic_indicator[matches] <- TRUE
    results$confidence_score[matches] <- pmax(results$confidence_score[matches], 0.99)
    results$matched_pattern[matches & is.na(results$matched_pattern)] <-
      sprintf("KNOWN_ACADEMIC: %s", institution)
  }

  for (pattern in ACADEMIC_HOSPITAL_PATTERNS$very_high) {
    matches <- grepl(pattern, org_upper, fixed = TRUE)
    if (any(matches)) {
      results$academic_indicator[matches] <- TRUE
      update_idx <- matches & (results$confidence_score < 0.95)
      results$confidence_score[update_idx] <- 0.95
      results$matched_pattern[matches & is.na(results$matched_pattern)] <-
        sprintf("VERY_HIGH: %s", pattern)
    }
  }

  for (pattern in ACADEMIC_HOSPITAL_PATTERNS$high) {
    matches <- grepl(pattern, org_upper, fixed = TRUE)
    if (any(matches)) {
      results$academic_indicator[matches] <- TRUE
      update_idx <- matches & (results$confidence_score < 0.90)
      results$confidence_score[update_idx] <- 0.90
      results$matched_pattern[matches & is.na(results$matched_pattern)] <-
        sprintf("HIGH: %s", pattern)
    }
  }

  if (confidence_threshold <= 0.80) {
    for (pattern in ACADEMIC_HOSPITAL_PATTERNS$moderate) {
      matches <- grepl(pattern, org_upper, fixed = TRUE)
      if (any(matches)) {
        update_idx <- matches & (results$confidence_score < 0.80)
        results$academic_indicator[update_idx] <- TRUE
        results$confidence_score[update_idx] <- 0.80
        results$matched_pattern[matches & is.na(results$matched_pattern)] <-
          sprintf("MODERATE: %s", pattern)
      }
    }
  }

  below_threshold <- results$confidence_score < confidence_threshold
  results$academic_indicator[below_threshold] <- FALSE
  results$confidence_score[below_threshold]   <- 0.0
  results$matched_pattern[below_threshold]    <- NA_character_

  results
}

#' Deprecated version of mysterycall_check_academic_name_patterns
#' @param ... Arguments passed to mysterycall_check_academic_name_patterns
#' @return See mysterycall_check_academic_name_patterns
#' @keywords internal
#' @name check_academic_name_patterns
check_academic_name_patterns <- function(...) { .Deprecated("mysterycall_check_academic_name_patterns"); mysterycall_check_academic_name_patterns(...) }

#' Classify Academic vs. Non-Academic Practice Setting
#'
#' Combines organization name patterns, optional hospital affiliation data,
#' and optional specialty-based adjustments to classify academic vs.
#' non-academic practice settings using a weighted scoring system.
#'
#' @param org_name Character vector of organization names to classify.
#' @param hospital_affiliation Character vector or NULL. Optional hospital
#'   affiliation names for additional pattern matching. Must be same length
#'   as \code{org_name} if provided. Default: \code{NULL}.
#' @param specialty Character vector or NULL. Optional physician specialties.
#'   Research-intensive specialties receive a 0.05 confidence boost. Must be
#'   same length as \code{org_name} if provided. Default: \code{NULL}.
#'
#' @return Data frame with one row per input and columns:
#'   \describe{
#'     \item{academic_classification}{Character. "Academic" or "Non-Academic".}
#'     \item{confidence_score}{Numeric. Confidence in the classification (0-1).}
#'     \item{matched_pattern}{Character. Highest-scoring pattern match, or NA.}
#'   }
#'
#' @examples
#' mysterycall:::mysterycall_classify_academic_affiliation("University of Michigan Medical Center")
#' mysterycall:::mysterycall_classify_academic_affiliation("Community Regional Hospital")
#'
#' @seealso \code{\link{mysterycall_check_academic_name_patterns}},
#'   \code{\link{mysterycall_get_academic_indicators_summary}}
#' @family academic-indicators
#' @export
mysterycall_classify_academic_affiliation <- function(org_name,
                                          hospital_affiliation = NULL,
                                          specialty = NULL) {
  name_results <- mysterycall_check_academic_name_patterns(org_name, confidence_threshold = 0.85)

  if (!is.null(hospital_affiliation) && length(hospital_affiliation) > 0) {
    hospital_results <- mysterycall_check_academic_name_patterns(hospital_affiliation,
                                                     confidence_threshold = 0.85)
    name_results$confidence_score <- pmax(name_results$confidence_score,
                                          hospital_results$confidence_score)
    name_results$academic_indicator <- name_results$academic_indicator |
      hospital_results$academic_indicator
    higher_hospital <- hospital_results$confidence_score > name_results$confidence_score
    name_results$matched_pattern[higher_hospital] <-
      paste0("HOSPITAL: ", hospital_results$matched_pattern[higher_hospital])
  }

  if (!is.null(specialty) && length(specialty) > 0) {
    research_intensive <- c(
      "SURGICAL ONCOLOGY", "MEDICAL ONCOLOGY", "HEMATOLOGY",
      "INTERVENTIONAL CARDIOLOGY", "NEUROSURGERY", "PATHOLOGY",
      "INFECTIOUS DISEASE", "ENDOCRINOLOGY", "RADIATION ONCOLOGY",
      "PEDIATRIC SUBSPECIALTIES"
    )
    is_research <- toupper(specialty) %in% research_intensive
    name_results$confidence_score[is_research] <-
      pmin(name_results$confidence_score[is_research] + 0.05, 1.0)
  }

  data.frame(
    academic_classification = ifelse(name_results$academic_indicator, "Academic", "Non-Academic"),
    confidence_score        = name_results$confidence_score,
    matched_pattern         = name_results$matched_pattern,
    stringsAsFactors        = FALSE
  )
}

#' Deprecated version of mysterycall_classify_academic_affiliation
#' @param ... Arguments passed to mysterycall_classify_academic_affiliation
#' @return See mysterycall_classify_academic_affiliation
#' @keywords internal
#' @name classify_academic_affiliation
classify_academic_affiliation <- function(...) { .Deprecated("mysterycall_classify_academic_affiliation"); mysterycall_classify_academic_affiliation(...) }

#' Export Academic Indicator Summary
#'
#' Creates a comprehensive summary report of all available academic indicators,
#' organized by evidence tier.
#'
#' @return A named list with elements:
#'   \describe{
#'     \item{`module_version`}{Character. Package version string.}
#'     \item{`created_date`}{Character. ISO date string (YYYY-MM-DD).}
#'     \item{`indicators`}{Named list with three sublists:
#'       `tier1_education_training`, `tier2_research_clinical`, and
#'       `tier3_name_patterns`, each containing confidence ranges and
#'       indicator scores.}
#'     \item{`total_known_institutions`}{Integer. Count of known academic
#'       institutions in the bundled lookup.}
#'     \item{`total_patterns`}{Integer. Count of name-pattern rules.}
#'     \item{`usage_notes`}{Character vector. Recommended usage guidelines.}
#'   }
#'
#' @examples
#' summary <- mysterycall:::mysterycall_get_academic_indicators_summary()
#' summary$total_known_institutions
#' names(summary$indicators)
#'
#' @seealso [mysterycall_classify_academic_affiliation()],
#'   [mysterycall_check_academic_name_patterns()]
#' @family academic-indicators
#' @export
mysterycall_get_academic_indicators_summary <- function() {
  list(
    module_version = "1.0.0",
    created_date   = "2025-10-06",
    indicators = list(
      tier1_education_training = list(
        confidence_range = "0.95-0.99",
        indicators = c(
          "ACGME Residency Programs"       = 0.98,
          "ACGME Fellowship Programs"      = 0.99,
          "Medical School Affiliations"    = 0.97,
          "COTH Teaching Hospital"         = 0.95
        )
      ),
      tier2_research_clinical = list(
        confidence_range = "0.85-0.99",
        indicators = c(
          "NIH CTSA Awards"                = 0.99,
          "NCI Cancer Center Designation"  = 0.98,
          "Medicare GME Payments"          = 0.95,
          "AAMC Membership"                = 0.95,
          "Clinical Trials Leadership"     = 0.90
        )
      ),
      tier3_name_patterns = list(
        confidence_range = "0.80-0.99",
        patterns = list(
          known_institutions    = 0.99,
          very_high_confidence  = 0.95,
          high_confidence       = 0.90,
          moderate_confidence   = 0.80
        )
      )
    ),
    total_known_institutions = length(KNOWN_ACADEMIC_INSTITUTIONS),
    total_patterns           = length(unlist(ACADEMIC_HOSPITAL_PATTERNS)),
    usage_notes = c(
      "Use mysterycall_classify_academic_affiliation() for comprehensive classification",
      "Use mysterycall_check_academic_name_patterns() for name-only matching",
      "Confidence scores range from 0.0 (non-academic) to 1.0 (definitive academic)",
      "Recommended threshold: 0.85 for high precision"
    )
  )
}

#' Deprecated version of mysterycall_get_academic_indicators_summary
#' @param ... Arguments passed to mysterycall_get_academic_indicators_summary
#' @return See mysterycall_get_academic_indicators_summary
#' @keywords internal
#' @name get_academic_indicators_summary
get_academic_indicators_summary <- function(...) { .Deprecated("mysterycall_get_academic_indicators_summary"); mysterycall_get_academic_indicators_summary(...) }
