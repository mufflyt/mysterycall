# Confirm all traffic is routed through Tor

Stops with an error if the Tor proxy is unreachable or the visible IP is
not a Tor exit node – ensuring no requests are sent over your real IP.

## Usage

``` r
verify_tor(torPort = 9150L)
```

## Arguments

- torPort:

  Integer SOCKS5 proxy port (default 9150).

## Value

Invisibly returns the detected Tor exit-node IP.
