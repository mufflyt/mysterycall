# data-raw/benchmark_name_parser.R
#
# Evaluates mysterycall_parse_physician_name() against the curated ground-truth
# corpus in inst/extdata/name_benchmark_corpus.csv.
#
# Run from the package root:
#   source("data-raw/benchmark_name_parser.R")
#
# The accuracy figure cited in the package documentation is derived from this
# script on the corpus version bundled with the installed package.

library(mysterycall)
library(dplyr)

corpus_path <- system.file("extdata", "name_benchmark_corpus.csv",
                           package = "mysterycall")
corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)

# Run the parser on every input.
parsed <- mysterycall_parse_physician_name(corpus$input)

# Join expected vs. actual for evaluation.
eval_df <- bind_cols(
  corpus |> select(input, notes,
                   exp_first  = expected_first,
                   exp_last   = expected_last,
                   exp_suffix = expected_suffix),
  parsed  |> select(first_name, last_name, suffix, parse_confidence)
) |>
  mutate(
    # Treat NA == "" as a match (blank expected = don't-care).
    first_ok  = is.na(exp_first)  | exp_first  == "" |
                tolower(trimws(coalesce(first_name, ""))) ==
                  tolower(trimws(coalesce(exp_first, ""))),
    last_ok   = is.na(exp_last)   | exp_last   == "" |
                tolower(trimws(coalesce(last_name, ""))) ==
                  tolower(trimws(coalesce(exp_last, ""))),
    suffix_ok = is.na(exp_suffix) | exp_suffix == "" |
                tolower(trimws(coalesce(suffix, ""))) ==
                  tolower(trimws(coalesce(exp_suffix, ""))),
    # A row is "correct" when all three fields match.
    correct = first_ok & last_ok & suffix_ok
  )

# Exclude "don't-care" rows (all expected fields blank, e.g. single-word names
# where any parse is acceptable) by keeping only rows with a non-blank expected
# first or last name. (A prior `is.na(x) & x == ""` guard here was a
# contradiction that could never be TRUE, and was unused.)
evaluated <- eval_df |> filter(!is.na(exp_first) | !is.na(exp_last))

n_total   <- nrow(evaluated)
n_correct <- sum(evaluated$correct, na.rm = TRUE)
accuracy  <- n_correct / n_total

cat(sprintf(
  "\n=== mysterycall name-parser benchmark ===\n\nCorpus:   %d cases (%d evaluated, %d don't-care)\nCorrect:  %d / %d\nAccuracy: %.1f%%\n\n",
  nrow(corpus), n_total, nrow(corpus) - n_total,
  n_correct, n_total, accuracy * 100
))

# Per-confidence breakdown.
cat("Breakdown by parse_confidence:\n")
eval_df |>
  group_by(parse_confidence) |>
  summarise(n = n(), correct = sum(correct, na.rm = TRUE),
            pct = round(100 * correct / n, 1)) |>
  print()

# Show failures.
failures <- evaluated |> filter(!correct)
if (nrow(failures) > 0L) {
  cat(sprintf("\n%d failure(s):\n", nrow(failures)))
  failures |>
    select(input, exp_first, first_name, exp_last, last_name,
           exp_suffix, suffix, notes) |>
    print(n = Inf)
} else {
  cat("\nAll cases parsed correctly.\n")
}

invisible(eval_df)
