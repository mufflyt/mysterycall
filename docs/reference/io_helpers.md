# Internal helpers for reading and writing roster files

These helpers standardize how the package reads and writes tabular
datasets so that functions can transparently support both CSV and
Parquet storage without duplicating logic.
