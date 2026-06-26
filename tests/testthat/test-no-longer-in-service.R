library(testthat)
library(mysterycall)

make_twilio_response <- function(payload, status = 200L) {
  body <- jsonlite::toJSON(payload, auto_unbox = TRUE, null = "null")
  structure(
    list(
      url = "https://api.twilio.com/",
      status_code = status,
      headers = list(`content-type` = "application/json"),
      all_headers = list(),
      cookies = structure(list(), class = "set_cookies"),
      content = charToRaw(body),
      times = numeric()
    ),
    class = "response"
  )
}

twilio_fixture <- function(...) {
  data.frame(
    Scraped.Phone = character(),
    DAC.Phone = character(),
    NPPES.Phone = character(),
    stringsAsFactors = FALSE
  )
}

test_that("mystercall_no_longer_in_service requires explicit Twilio credentials", {
  df <- data.frame(
    Scraped.Phone = "303-555-1212",
    DAC.Phone = "",
    NPPES.Phone = "",
    stringsAsFactors = FALSE
  )

  expect_error(
    mystercall_no_longer_in_service(
      df,
      auth_token = "token",
      from_number = "+17205551212"
    ),
    "`account_sid` is required",
    fixed = TRUE
  )
  expect_error(
    mystercall_no_longer_in_service(
      df,
      account_sid = "AC123",
      auth_token = NA_character_,
      from_number = "+17205551212"
    ),
    "`auth_token` is required",
    fixed = TRUE
  )
  expect_error(
    mystercall_no_longer_in_service(
      df,
      account_sid = "AC123",
      auth_token = "token",
      from_number = ""
    ),
    "`from_number` is required",
    fixed = TRUE
  )
})

test_that("mysterycall_no_longer_in_service alias matches requested function", {
  expect_identical(
    mysterycall_no_longer_in_service,
    mystercall_no_longer_in_service
  )
})

test_that("mystercall_no_longer_in_service validates input data shape", {
  expect_error(
    mystercall_no_longer_in_service(
      data = NULL,
      account_sid = "AC123",
      auth_token = "token",
      from_number = "+17205551212"
    ),
    "Supply either `data` or `csv_path`",
    fixed = TRUE
  )

  expect_error(
    mystercall_no_longer_in_service(
      data.frame(phone = "303-555-1212"),
      account_sid = "AC123",
      auth_token = "token",
      from_number = "+17205551212"
    ),
    "Phone columns not found"
  )
})

test_that("mystercall_no_longer_in_service returns expected columns for empty data", {
  result <- mystercall_no_longer_in_service(
    twilio_fixture(),
    account_sid = "AC123",
    auth_token = "token",
    from_number = "+17205551212",
    mc_cores = 1L
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_true(all(c(
    "dialed_phone",
    "dialed_phone_e164",
    "dial_status",
    "dial_error",
    "no_longer_in_service"
  ) %in% names(result)))
})

test_that("mystercall_no_longer_in_service rejects malformed numbers before Twilio", {
  post_called <- FALSE
  df <- data.frame(
    Scraped.Phone = c("N/A", "CALL-NOW"),
    DAC.Phone = c("", ""),
    NPPES.Phone = c("", ""),
    stringsAsFactors = FALSE
  )

  with_mocked_bindings(
    POST = function(...) {
      post_called <<- TRUE
      stop("POST should not be called for invalid formats")
    },
    .package = "httr",
    code = {
      result <- mystercall_no_longer_in_service(
        df,
        account_sid = "AC123",
        auth_token = "token",
        from_number = "+17205551212",
        mc_cores = 1L
      )
    }
  )

  expect_false(post_called)
  expect_equal(result$dial_status, c("Invalid Format", "Invalid Format"))
  expect_true(all(is.na(result$dialed_phone_e164)))
  expect_false(any(result$no_longer_in_service))
})

test_that("mystercall_no_longer_in_service chooses phone columns by semantic priority", {
  posted_body <- NULL
  polled <- FALSE
  df <- data.frame(
    Scraped.Phone = "",
    DAC.Phone = "(303) 555-1212",
    NPPES.Phone = "212-555-1212",
    stringsAsFactors = FALSE
  )

  with_mocked_bindings(
    POST = function(url, ..., body, encode) {
      posted_body <<- body
      expect_match(url, "/Accounts/AC123/Calls\\.json$")
      expect_equal(encode, "form")
      make_twilio_response(list(sid = "CA123"), status = 201L)
    },
    GET = function(url, ...) {
      polled <<- TRUE
      expect_match(url, "/Accounts/AC123/Calls/CA123\\.json$")
      make_twilio_response(list(status = "completed", error_code = NULL), status = 200L)
    },
    .package = "httr",
    code = {
      result <- mystercall_no_longer_in_service(
        df,
        account_sid = "AC123",
        auth_token = "token",
        from_number = "+17205551212",
        mc_cores = 1L,
        poll_interval = 0
      )
    }
  )

  expect_true(polled)
  expect_equal(posted_body$To, "+13035551212")
  expect_equal(posted_body$From, "+17205551212")
  expect_equal(posted_body$Twiml, "<Response><Hangup/></Response>")
  expect_equal(result$dialed_phone, "(303) 555-1212")
  expect_equal(result$dialed_phone_e164, "+13035551212")
  expect_equal(result$dial_status, "completed")
  expect_false(result$no_longer_in_service)
})

test_that("mystercall_no_longer_in_service flags failed and no-answer outcomes", {
  statuses <- c("failed", "no-answer")
  poll_index <- 0L
  df <- data.frame(
    Scraped.Phone = c("303-555-0001", "303-555-0002"),
    DAC.Phone = c("", ""),
    NPPES.Phone = c("", ""),
    stringsAsFactors = FALSE
  )

  with_mocked_bindings(
    POST = function(...) make_twilio_response(list(sid = "CA123"), status = 201L),
    GET = function(...) {
      poll_index <<- poll_index + 1L
      make_twilio_response(
        list(status = statuses[[poll_index]], error_code = 32017L),
        status = 200L
      )
    },
    .package = "httr",
    code = {
      result <- mystercall_no_longer_in_service(
        df,
        account_sid = "AC123",
        auth_token = "token",
        from_number = "+17205551212",
        mc_cores = 1L,
        poll_interval = 0
      )
    }
  )

  expect_equal(result$dial_status, statuses)
  expect_equal(result$dial_error, c("32017", "32017"))
  expect_true(all(result$no_longer_in_service))
})

test_that("mystercall_no_longer_in_service flags Twilio API errors without polling", {
  get_called <- FALSE
  df <- data.frame(
    Scraped.Phone = "303-555-1212",
    DAC.Phone = "",
    NPPES.Phone = "",
    stringsAsFactors = FALSE
  )

  with_mocked_bindings(
    POST = function(...) make_twilio_response(list(message = "Unauthorized"), status = 401L),
    GET = function(...) {
      get_called <<- TRUE
      make_twilio_response(list(status = "completed"), status = 200L)
    },
    .package = "httr",
    code = {
      result <- mystercall_no_longer_in_service(
        df,
        account_sid = "AC123",
        auth_token = "token",
        from_number = "+17205551212",
        mc_cores = 1L
      )
    }
  )

  expect_false(get_called)
  expect_equal(result$dial_status, "API Error")
  expect_equal(result$dial_error, "401")
  expect_true(result$no_longer_in_service)
})

test_that("mystercall_no_longer_in_service preserves queued status after polling limit", {
  poll_count <- 0L
  df <- data.frame(
    Scraped.Phone = "1 (303) 555-1212",
    DAC.Phone = "",
    NPPES.Phone = "",
    stringsAsFactors = FALSE
  )

  with_mocked_bindings(
    POST = function(...) make_twilio_response(list(sid = "CA123"), status = 201L),
    GET = function(...) {
      poll_count <<- poll_count + 1L
      make_twilio_response(list(status = "queued", error_code = NULL), status = 200L)
    },
    .package = "httr",
    code = {
      result <- mystercall_no_longer_in_service(
        df,
        account_sid = "AC123",
        auth_token = "token",
        from_number = "+17205551212",
        mc_cores = 1L,
        poll_attempts = 2L,
        poll_interval = 0
      )
    }
  )

  expect_equal(poll_count, 2L)
  expect_equal(result$dial_status, "queued")
  expect_false(result$no_longer_in_service)
})

test_that("Twilio credentials can be checked without placing a call", {
  skip_if(Sys.getenv("MYSTERYCALL_TWILIO_LIVE_TEST") != "true")

  account_sid <- Sys.getenv("TWILIO_ACCOUNT_SID")
  auth_token <- Sys.getenv("TWILIO_AUTH_TOKEN")
  skip_if(!nzchar(account_sid), "TWILIO_ACCOUNT_SID is not set")
  skip_if(!nzchar(auth_token), "TWILIO_AUTH_TOKEN is not set")

  res <- httr::GET(
    paste0("https://api.twilio.com/2010-04-01/Accounts/", account_sid, ".json"),
    httr::authenticate(account_sid, auth_token)
  )

  expect_equal(httr::status_code(res), 200L)
})

test_that("live Twilio dialing is opt-in only", {
  skip_if(Sys.getenv("MYSTERYCALL_TWILIO_DIAL_TEST") != "true")

  account_sid <- Sys.getenv("TWILIO_ACCOUNT_SID")
  auth_token <- Sys.getenv("TWILIO_AUTH_TOKEN")
  from_number <- Sys.getenv("TWILIO_FROM_NUMBER")
  to_number <- Sys.getenv("TWILIO_TEST_TO_NUMBER")
  skip_if(!nzchar(account_sid), "TWILIO_ACCOUNT_SID is not set")
  skip_if(!nzchar(auth_token), "TWILIO_AUTH_TOKEN is not set")
  skip_if(!nzchar(from_number), "TWILIO_FROM_NUMBER is not set")
  skip_if(!nzchar(to_number), "TWILIO_TEST_TO_NUMBER is not set")

  df <- data.frame(
    Scraped.Phone = to_number,
    DAC.Phone = "",
    NPPES.Phone = "",
    stringsAsFactors = FALSE
  )

  result <- mysterycall_no_longer_in_service(
    df,
    account_sid = account_sid,
    auth_token = auth_token,
    from_number = from_number,
    mc_cores = 1L,
    poll_attempts = 1L,
    poll_interval = 1
  )

  expect_equal(nrow(result), 1L)
  expect_true(result$dial_status %in% c(
    "queued",
    "ringing",
    "in-progress",
    "completed",
    "failed",
    "no-answer",
    "busy",
    "canceled",
    "API Error"
  ))
})
