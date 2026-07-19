# Dial phone numbers and flag lines that appear no longer in service

Uses the Twilio Voice API to place short outbound calls with TwiML that
hangs up immediately if answered. The resulting Twilio call status and
error code can be used as an automated dialing validation layer for
inactive numbers, dead redirects, and Special Information
Tone/no-longer-in-service outcomes.

## Usage

``` r
mystercall_no_longer_in_service(
  data = NULL,
  csv_path = NULL,
  account_sid,
  auth_token,
  from_number,
  phone_columns = c("Scraped.Phone", "DAC.Phone", "NPPES.Phone"),
  mc_cores = 4L,
  poll_attempts = 10L,
  poll_interval = 5
)

mysterycall_no_longer_in_service(
  data = NULL,
  csv_path = NULL,
  account_sid,
  auth_token,
  from_number,
  phone_columns = c("Scraped.Phone", "DAC.Phone", "NPPES.Phone"),
  mc_cores = 4L,
  poll_attempts = 10L,
  poll_interval = 5
)
```

## Arguments

- data:

  Optional data frame containing phone-number columns. If `NULL`,
  `csv_path` is read with
  [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html).

- csv_path:

  Optional CSV path used when `data` is `NULL`.

- account_sid:

  Twilio Account SID.

- auth_token:

  Twilio Auth Token.

- from_number:

  Twilio outbound caller ID, in E.164 format.

- phone_columns:

  Character vector of phone columns to check in priority order. The
  first non-missing, non-empty value is dialed.

- mc_cores:

  Number of parallel workers. Defaults to at most 4 to limit Twilio
  queue/calls-per-second pressure.

- poll_attempts:

  Maximum number of polling attempts per call.

- poll_interval:

  Seconds to wait between polling attempts.

## Value

A data frame containing the original rows plus:

- `dialed_phone`:

  Selected source phone number.

- `dialed_phone_e164`:

  Cleaned E.164 phone number, or `NA`.

- `dial_status`:

  Twilio call status, `"Invalid Format"`, or `"API Error"`.

- `dial_error`:

  Twilio error code, HTTP status, or `NA`.

- `no_longer_in_service`:

  Logical flag for failed dialing outcomes.

## See also

Other phone_validation:
[`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)

## Examples

``` r
if (FALSE) { # \dontrun{
checked <- mysterycall_no_longer_in_service(
  csv_path = "providers.csv",
  account_sid = Sys.getenv("TWILIO_ACCOUNT_SID"),
  auth_token = Sys.getenv("TWILIO_AUTH_TOKEN"),
  from_number = Sys.getenv("TWILIO_FROM_NUMBER")
)
} # }
```
