#' Dial phone numbers and flag lines that appear no longer in service
#'
#' Uses the Twilio Voice API to place short outbound calls with TwiML that hangs
#' up immediately if answered. The resulting Twilio call status and error code
#' can be used as an automated dialing validation layer for inactive numbers,
#' dead redirects, and Special Information Tone/no-longer-in-service outcomes.
#'
#' @param data Optional data frame containing phone-number columns. If `NULL`,
#'   `csv_path` is read with [utils::read.csv()].
#' @param csv_path Optional CSV path used when `data` is `NULL`.
#' @param account_sid Twilio Account SID.
#' @param auth_token Twilio Auth Token.
#' @param from_number Twilio outbound caller ID, in E.164 format.
#' @param phone_columns Character vector of phone columns to check in priority
#'   order. The first non-missing, non-empty value is dialed.
#' @param mc_cores Number of parallel workers. Defaults to at most 4 to limit
#'   Twilio queue/calls-per-second pressure.
#' @param poll_attempts Maximum number of polling attempts per call.
#' @param poll_interval Seconds to wait between polling attempts.
#'
#' @return A data frame containing the original rows plus:
#'   \describe{
#'     \item{`dialed_phone`}{Selected source phone number.}
#'     \item{`dialed_phone_e164`}{Cleaned E.164 phone number, or `NA`.}
#'     \item{`dial_status`}{Twilio call status, `"Invalid Format"`, or
#'       `"API Error"`.}
#'     \item{`dial_error`}{Twilio error code, HTTP status, or `NA`.}
#'     \item{`no_longer_in_service`}{Logical flag for failed dialing outcomes.}
#'   }
#'
#' @family phone_validation
#' @export
#'
#' @examples
#' # Requires active Twilio credentials in environment variables.
#' \dontrun{
#' checked <- mysterycall_no_longer_in_service(
#'   csv_path = "providers.csv",
#'   account_sid = Sys.getenv("TWILIO_ACCOUNT_SID"),
#'   auth_token = Sys.getenv("TWILIO_AUTH_TOKEN"),
#'   from_number = Sys.getenv("TWILIO_FROM_NUMBER")
#' )
#' }
mystercall_no_longer_in_service <- function(data = NULL,
                                            csv_path = NULL,
                                            account_sid,
                                            auth_token,
                                            from_number,
                                            phone_columns = c(
                                              "Scraped.Phone",
                                              "DAC.Phone",
                                              "NPPES.Phone"
                                            ),
                                            mc_cores = 4L,
                                            poll_attempts = 10L,
                                            poll_interval = 5) {
  if (missing(account_sid) || is.na(account_sid) || !nzchar(account_sid)) {
    stop("`account_sid` is required.", call. = FALSE)
  }
  if (missing(auth_token) || is.na(auth_token) || !nzchar(auth_token)) {
    stop("`auth_token` is required.", call. = FALSE)
  }
  if (missing(from_number) || is.na(from_number) || !nzchar(from_number)) {
    stop("`from_number` is required.", call. = FALSE)
  }
  if (is.null(data)) {
    if (is.null(csv_path) || is.na(csv_path) || !nzchar(csv_path)) {
      stop("Supply either `data` or `csv_path`.", call. = FALSE)
    }
    data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  missing_cols <- setdiff(phone_columns, names(data))
  if (length(missing_cols) > 0L) {
    stop("Phone columns not found: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  clean_phone <- function(phone) {
    trimmed_phone <- trimws(phone)
    if (is.na(phone) || !nzchar(trimmed_phone) || identical(trimmed_phone, "N/A")) {
      return(NA_character_)
    }
    digits <- gsub("[^0-9]", "", trimmed_phone)
    if (nchar(digits) == 10L) {
      return(paste0("+1", digits))
    }
    if (nchar(digits) == 11L && startsWith(digits, "1")) {
      return(paste0("+", digits))
    }
    NA_character_
  }

  choose_phone <- function(row) {
    values <- as.character(unlist(row[phone_columns], use.names = FALSE))
    values <- values[!is.na(values) & nzchar(trimws(values))]
    if (length(values) == 0L) {
      return(NA_character_)
    }
    values[[1L]]
  }

  dial_and_check <- function(row_idx) {
    phone <- choose_phone(data[row_idx, , drop = FALSE])
    cleaned <- clean_phone(phone)
    if (is.na(cleaned)) {
      return(list(
        idx = row_idx,
        dialed_phone = phone,
        dialed_phone_e164 = NA_character_,
        status = "Invalid Format",
        error = NA_character_
      ))
    }

    calls_url <- paste0(
      "https://api.twilio.com/2010-04-01/Accounts/",
      account_sid,
      "/Calls.json"
    )
    twiml <- "<Response><Hangup/></Response>"

    res <- httr::POST(
      calls_url,
      httr::authenticate(account_sid, auth_token),
      body = list(To = cleaned, From = from_number, Twiml = twiml),
      encode = "form"
    )

    if (httr::status_code(res) != 201L) {
      return(list(
        idx = row_idx,
        dialed_phone = phone,
        dialed_phone_e164 = cleaned,
        status = "API Error",
        error = as.character(httr::status_code(res))
      ))
    }

    call_info <- httr::content(res, as = "parsed", type = "application/json")
    call_sid <- call_info$sid
    status <- "queued"
    error_code <- NA_character_
    attempts <- 0L

    while (status %in% c("queued", "ringing", "in-progress") &&
           attempts < poll_attempts) {
      Sys.sleep(poll_interval)
      poll_res <- httr::GET(
        paste0(
          "https://api.twilio.com/2010-04-01/Accounts/",
          account_sid,
          "/Calls/",
          call_sid,
          ".json"
        ),
        httr::authenticate(account_sid, auth_token)
      )
      if (httr::status_code(poll_res) == 200L) {
        poll_info <- httr::content(poll_res, as = "parsed", type = "application/json")
        status <- poll_info$status
        if (!is.null(poll_info$error_code)) {
          error_code <- as.character(poll_info$error_code)
        }
      }
      attempts <- attempts + 1L
    }

    list(
      idx = row_idx,
      dialed_phone = phone,
      dialed_phone_e164 = cleaned,
      status = status,
      error = error_code
    )
  }

  if (nrow(data) == 0L) {
    return(data.frame(
      data,
      dialed_phone = character(0L),
      dialed_phone_e164 = character(0L),
      dial_status = character(0L),
      dial_error = character(0L),
      no_longer_in_service = logical(0L),
      stringsAsFactors = FALSE
    ))
  }

  mc_cores <- max(1L, as.integer(mc_cores))
  row_ids <- seq_len(nrow(data))
  results <- if (.Platform$OS.type == "windows" || mc_cores == 1L) {
    lapply(row_ids, dial_and_check)
  } else {
    parallel::mclapply(row_ids, dial_and_check, mc.cores = mc_cores)
  }

  ordered <- results[order(vapply(results, `[[`, integer(1L), "idx"))]
  dial_status <- vapply(ordered, `[[`, character(1L), "status")
  dial_error <- vapply(ordered, function(x) {
    error <- x$error
    if (is.null(error) || is.na(error)) NA_character_ else as.character(error)
  }, character(1L))

  no_longer_in_service <- dial_status %in% c("failed", "no-answer", "API Error")

  data.frame(
    data,
    dialed_phone = vapply(ordered, `[[`, character(1L), "dialed_phone"),
    dialed_phone_e164 = vapply(ordered, `[[`, character(1L), "dialed_phone_e164"),
    dial_status = dial_status,
    dial_error = dial_error,
    no_longer_in_service = no_longer_in_service,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' @rdname mystercall_no_longer_in_service
#' @export
mysterycall_no_longer_in_service <- mystercall_no_longer_in_service
