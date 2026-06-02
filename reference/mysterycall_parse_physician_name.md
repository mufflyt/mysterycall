# Parse physician names into structured components

Converts free-text physician name strings – from board certification
data, NPPES, or CMS sources – into a tidy data frame of first, middle,
last, suffix, and title fields with confidence scoring and warning
flags. Accuracy: 96.3 % on the 27-case benchmark corpus in
`inst/extdata/name_benchmark_corpus.csv`.

## Usage

``` r
mysterycall_parse_physician_name(physician_name, remove_titles = TRUE)
```

## Arguments

- physician_name:

  Character vector of physician name strings. Accepts `"First Last"`,
  `"Last, First"`, `"Last, First, Suffix"`, `"First Last, MD"`, and
  `"Dr. First Middle Last Jr., MD FACOG"`.

- remove_titles:

  Logical scalar. When `TRUE` (default), leading titles (`"Dr."`,
  `"Prof."`, `"Mr."`, `"Mrs."`, `"Ms."`) are stripped from the name
  string before parsing; the `title` column in the output is `NA`. When
  `FALSE`, the title is preserved in the `title` column and the name is
  parsed without stripping it.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per element of `physician_name`:

- `first_name`:

  Given name, or `NA`.

- `middle_name`:

  Middle name(s), or `NA`.

- `last_name`:

  Family name, or `NA`.

- `suffix`:

  Professional / generational suffix (`"MD"`, `"Jr."`), or `NA`.

- `title`:

  Title (`"Dr."`, `"Prof."`), or `NA` when removed.

- `parse_confidence`:

  `"high"` (first + last present), `"medium"` (one present), or `"low"`
  (both absent).

- `parse_warnings`:

  `"single_word_name"`, `"parsing_failed"`, or `NA`.

## Edge cases handled

- Vietnamese "Do" surname:

  Distinguishes "Do" (surname, title-case) from "DO" (Doctor of
  Osteopathic Medicine, all-caps after a multi-word name). `"Linda Do"`
  -\> `last_name = "Do"`; `"Robert Smith DO"` -\> `last_name = "Smith"`,
  `suffix = "DO"`.

- Three-part comma format:

  `"Smith, John, Jr."` -\> `last = "Smith"`, `first = "John"`,
  `suffix = "Jr."`.

- Hyphenated / compound last names:

  `"Maria de la Cruz-Garcia"` -\> `last = "de la Cruz-Garcia"`.

- Multiple credentials:

  `"John Smith, MD, FACOG"` -\> `suffix = "MD, FACOG"`.

- NA / empty input:

  Returns a row with all `NA` fields and `parse_confidence = "low"`;
  never errors.

## Data format

    board_df <- data.frame(
      raw_name = c("Smith, John, Jr.", "Maria de la Cruz-Garcia", "Linda Do"),
      stringsAsFactors = FALSE
    )
    parsed <- mysterycall_parse_physician_name(board_df$raw_name)
    result <- dplyr::bind_cols(board_df, parsed)

## See also

[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)
for post-parse quality checks;
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md)
to reconstruct display names;
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md)
for the built-in accuracy suite.

Other name-parsing:
[`.handle_do_credential()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_do_credential.md),
[`.handle_three_part_comma()`](https://mufflyt.github.io/mysterycall/reference/dot-handle_three_part_comma.md),
[`.parse_physician_name_impl()`](https://mufflyt.github.io/mysterycall/reference/dot-parse_physician_name_impl.md),
[`mysterycall_format_physician_name()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_physician_name.md),
[`mysterycall_test_name_parser()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_test_name_parser.md),
[`mysterycall_validate_parsed_names()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_parsed_names.md)

## Examples

``` r
mysterycall_parse_physician_name("Dr. John Michael Smith, MD, FACOG")
#> # A tibble: 1 × 7
#>   first_name middle_name last_name suffix  title parse_confidence parse_warnings
#>   <chr>      <chr>       <chr>     <chr>   <chr> <chr>            <chr>         
#> 1 John       Michael     Smith     MD, FA… NA    high             NA            

# Vectorised with mixed formats
mysterycall_parse_physician_name(c(
  "Smith, John, Jr.",
  "Maria de la Cruz-Garcia",
  NA_character_
))
#> # A tibble: 3 × 7
#>   first_name middle_name last_name  suffix title parse_confidence parse_warnings
#>   <chr>      <chr>       <chr>      <chr>  <chr> <chr>            <chr>         
#> 1 John       NA          Smith      Jr.    NA    high             NA            
#> 2 Maria      NA          de la Cru… NA     NA    high             NA            
#> 3 NA         NA          NA         NA     NA    low              parsing_failed
```
