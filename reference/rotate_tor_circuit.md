# Rotate the Tor circuit so the next request uses a new exit node

Sends `SIGNAL NEWNYM` to the Tor control port. Silently skips if the
control port is unreachable (common with Tor Browser's default
settings).

## Usage

``` r
rotate_tor_circuit(control_port = 9051L, password = "")
```

## Arguments

- control_port:

  Integer control port (default 9051).

- password:

  Character control-port password (default `""`).
