# Find the highest valid ABOG diplomate ID

Scans upward from `seed_id` through the ABOG API (via Tor), tracking the
highest ID that returns a physician record. Stops after
`max_consecutive_misses` consecutive IDs return nothing, which reliably
signals the end of the registry even when IDs are not perfectly
contiguous.

## Usage

``` r
find_max_abog_id(
  seed_id,
  torPort = 9150L,
  max_consecutive_misses = 100L,
  sleep_between = 0.3,
  verbose = TRUE
)
```

## Arguments

- seed_id:

  Integer. A known valid ID to start scanning from (e.g. the highest ID
  in your existing dataset).

- torPort:

  Integer. Tor SOCKS5 proxy port (default 9150).

- max_consecutive_misses:

  Integer. Stop scanning after this many back-to-back empty/404
  responses (default 100). Increase if the registry has long gaps
  between recent additions.

- sleep_between:

  Numeric. Seconds to sleep between probes (default 0.3).

- verbose:

  Logical. Print progress (default TRUE).

## Value

The highest integer diplomate ID that returned physician data.

## Details

A binary search is NOT used here because ABOG IDs have gaps – an empty
response at ID N does not imply N+1 is also empty.

## Examples

``` r
if (FALSE) { # interactive()
max_id <- find_max_abog_id(seed_id = 9046331, torPort = 9150)
}
```
