#' Taxonomy Codes for Obstetricians and Gynecologists
#'
#' This dataset contains taxonomy codes for Obstetricians and Gynecologists among other healthcare providers.
#'
#' @format A data frame with three columns:
#'   \describe{
#'     \item{Code}{NUCC (National Uniform Claim Committee) taxonomy code (character).}
#'     \item{Classification}{Provider classification (e.g., "Allopathic & Osteopathic Physicians").}
#'     \item{Specialization}{Specialty within the classification (e.g., "Obstetrics & Gynecology").}
#'   }
#' @source <https://www.nucc.org/images/stories/PDF/taxonomy_23_0.pdf>
#'
#' @seealso [mysterycall_get_clinician_data()] to look up provider taxonomy
#'   codes from the NPI registry; [acgme] for ACGME residency program data.
#' @examples
#' data(taxonomy)
#' print(taxonomy[1:3, ])
#'
#' @family datasets
#' @name taxonomy
#' @docType data
NULL
