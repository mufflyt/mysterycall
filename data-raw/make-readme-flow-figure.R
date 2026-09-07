# Generates man/figures/fig-strobe-flow-validated.png for the README.
# Run from the package root:  Rscript data-raw/make-readme-flow-figure.R
#
# Uses the AAGL abstract-publication cohort, the same example carried in
# mysterycall_flow_spec()'s docs, so the figure and the reference agree.
devtools::load_all(quiet = TRUE)

spec <- mysterycall_flow_spec(
  spine = c(
    "Abstracts parsed from congress supplements" = 1154,
    "Oral presentation cohort"                   = 1106,
    "Evaluated for publication status"           = 1051
  ),
  exclusions = list(
    "Abstracts parsed from congress supplements" = c("Video presentations" = 48),
    "Oral presentation cohort"                   = c("Adjudication unresolved" = 55)
  ),
  splits = list(
    "Evaluated for publication status" = c("Published" = 170, "Not published" = 881),
    "Not published" = c("No qualifying publication" = 839,
                        "Publication predates the congress" = 42)
  )
)
stopifnot(isTRUE(spec$closed))

p <- mysterycall_strobe_diagram(
  spec,
  title = "Participant flow, validated before it is drawn"
)

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
ggplot2::ggsave("man/figures/fig-strobe-flow-validated.png", p,
                width = 9, height = 7, dpi = 150, bg = "white")
message("wrote man/figures/fig-strobe-flow-validated.png")
