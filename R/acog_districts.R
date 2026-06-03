#' ACOG Districts Data
#'
#' This dataset contains information about American College of Obstetricians and
#' Gynecologists (ACOG) districts, including their two-letter state abbreviations
#' and full state names. It is useful for grouping states into regional districts
#' for subgroup analysis in mystery caller studies.
#'
#' @return A tibble where each row represents an ACOG district with its
#'   corresponding two-letter abbreviation and full state name.
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{State}{Full name of the US state.}
#'   \item{ACOG_District}{ACOG district designation (Roman numeral or letter code).}
#'   \item{Subregion}{Geographic subregion within the ACOG district.}
#'   \item{State_Abbreviations}{Two-letter US state abbreviation.}
#' }
#'
#' @source Data was obtained from the official ACOG website: <https://www.acog.org/community/districts-and-sections>
#'
#' @examples
#' # Load the ACOG Districts Data
#' data(acog_districts)
#'
#' # Inspect the dataset
#' head(acog_districts)
#'
#' # Group by district
#' table(acog_districts$ACOG_District)
#'
#' @keywords dataset
#' @family datasets
#' @name acog_districts
#' @docType data
NULL
