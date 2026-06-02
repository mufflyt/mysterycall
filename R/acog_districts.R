#' ACOG Districts Data
#'
#' This dataset contains information about American College of Obstetricians and Gynecologists (ACOG) districts, including their two-letter state abbreviations and full state names.
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
#' print(acog_districts)
#'
#' # Get a summary of the dataset
#' summary(acog_districts)
#'
#' # Perform data analysis and exploration
#'
#' @keywords dataset
#' @family datasets
#' @name acog_districts
#' @docType data
#' @family datasets
NULL
