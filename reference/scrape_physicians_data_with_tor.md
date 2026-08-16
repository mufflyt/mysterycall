# Scrape ABOG Physicians via Tor (privacy-first)

Queries `https://api.abog.org/diplomate/{id}/verify` for each ID in
`[startID, endID]`. Every request is routed through a local Tor SOCKS5
proxy – your real IP address is never sent to the ABOG server.

## Usage

``` r
scrape_physicians_data_with_tor(
  startID,
  endID,
  tor_ports = 9050L,
  tor_control_port = 9051L,
  tor_control_password = "",
  skip_ids_paths = NULL,
  output_format = c("csv", "parquet"),
  output_dir = tempdir(),
  checkpoint_every = 100L,
  max_retries = 3L,
  sleep_min = 0.3,
  sleep_max = 0.8,
  sleep_min_notfound = 0.1,
  sleep_max_notfound = 0.3,
  rotate_tor_every = 50L,
  descending = FALSE,
  max_skip_age_days = 180L,
  verbose = TRUE
)
```

## Arguments

- startID:

  Integer. First diplomate ID to query.

- endID:

  Integer. Last diplomate ID to query (inclusive).

- tor_ports:

  Integer vector of Tor SOCKS5 proxy ports (default `9050`). Supply
  multiple ports – e.g. `c(9050, 9052, 9054, 9056)` – to enable parallel
  scraping: the ID range is split into `length(tor_ports)` chunks and
  each chunk is scraped in its own forked process through a different
  Tor circuit. Requires the `tor` daemon configured with one `SocksPort`
  per entry (see `/opt/homebrew/etc/tor/torrc`). Use `9150` for Tor
  Browser (single port only).

- tor_control_port:

  Integer. Tor control port for circuit rotation (default 9051). Pass
  `NULL` to disable rotation entirely.

- tor_control_password:

  Character. Control-port password (default `""`, i.e. no password –
  typical for localhost-only setups).

- skip_ids_paths:

  Optional character vector of paths to CSV or Parquet files containing
  IDs to skip. Each file may have a column named `WrongIDs`,
  `UnknownIDs`, or `FailedIDs` – all are recognised automatically. Pass
  the `UnknownIDs_*.csv` and/or `FailedIDs_*.csv` files from a previous
  run to avoid re-querying IDs that were already confirmed empty or that
  persistently failed.

- output_format:

  `"csv"` (default) or `"parquet"`.

- output_dir:

  Directory for output files. Created if absent. Defaults to
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- checkpoint_every:

  Save partial results after every N successful records (default 100).
  Set to `Inf` to disable.

- max_retries:

  Maximum retry attempts per ID for transient errors (default 3).

- sleep_min:

  Minimum seconds between requests (default 2). Increase to be more
  conservative.

- sleep_max:

  Maximum seconds between requests (default 5).

- rotate_tor_every:

  Request a new Tor circuit every N requests (default 25). Lower values
  mean more exit-node diversity at the cost of slightly more delay (2 s
  per rotation). Set to `Inf` to disable.

- descending:

  Logical. If `TRUE`, iterate from `endID` down to `startID` so the most
  recently issued (highest-numbered) IDs are scraped first (default
  `FALSE`). Combine with
  [`find_max_abog_id`](https://mufflyt.github.io/mysterycall/reference/find_max_abog_id.md)
  to always start from the current top of the registry.

- max_skip_age_days:

  Integer. Maximum age (in days) of a "confirmed empty" record before
  the ID is re-queried (default 180 – six months). Files with a
  `ConfirmedEmptyAt` column use per-row timestamps; older files without
  that column are judged by their file modification date. Set to `Inf`
  to trust skip files forever (not recommended – newly certified
  physicians can fill previously empty IDs).

- verbose:

  Logical. Print per-ID progress (default `TRUE`).

- torPort:

  Integer. Tor SOCKS5 proxy port. Use `9150` (default) for Tor Browser
  or `9050` for the `tor` daemon.

## Value

A data frame of scraped physician records with columns from the ABOG
JSON response plus `ID` and `ScrapedAt`.

## Details

Privacy protections (in order of importance):

1.  **Tor verification** – confirms a Tor exit node is in use *before*
    any scraping begins; aborts if the check fails.

2.  **Circuit rotation** – requests a new Tor exit node every
    `rotate_tor_every` requests, limiting how much traffic any single
    exit node sees.

3.  **Randomised timing** – each request waits a random interval in
    `[sleep_min, sleep_max]` seconds, so traffic cannot be fingerprinted
    by a fixed inter-request cadence.

4.  **Randomised User-Agent** – each request picks a different browser
    string so repeated requests look like different clients.

5.  **Transient-error retry** – 429 / 5xx and network errors are retried
    with exponential back-off; only confirmed 404 / empty responses are
    logged as genuinely not found. This prevents valid records from
    being silently lost.

6.  **Checkpoint saves** – results are written to disk every
    `checkpoint_every` records so no data is lost if the session is
    interrupted.

## Examples

``` r
if (FALSE) { # interactive()
result <- scrape_physicians_data_with_tor(
  startID    = 9045999,
  endID      = 9046010,
  torPort    = 9150,
  output_dir = "~/Desktop/abog_scrape"
)
}
```
