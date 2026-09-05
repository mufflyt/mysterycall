# Generates man/figures/fig-reporting-checklists.png for the README.
# Run from the package root:  Rscript data-raw/make-readme-reporting-figure.R
devtools::load_all(quiet = TRUE)
library(ggplot2)

counts <- do.call(rbind, list(
  data.frame(checklist = "SAMPL\n(how numbers are reported)",
             section = names(table(mysterycall_sampl_checklist()$section)),
             n = as.integer(table(mysterycall_sampl_checklist()$section))),
  data.frame(checklist = "CRiSP\n(simulated-patient method)",
             section = names(table(mysterycall_crisp_checklist()$section)),
             n = as.integer(table(mysterycall_crisp_checklist()$section)))
))
counts$checklist <- factor(counts$checklist,
  levels = c("SAMPL\n(how numbers are reported)", "CRiSP\n(simulated-patient method)"))
counts <- counts[order(counts$checklist, counts$n), ]
# Facets need unique x levels per panel; join with a sentinel that is stripped
# back off at render time so each panel shows only the section name.
counts$lab <- factor(paste0(counts$checklist, "\u0001", counts$section),
                     levels = paste0(counts$checklist, "\u0001", counts$section))

p <- ggplot(counts, aes(x = lab, y = n)) +
  geom_col(width = 0.72, fill = "grey30") +
  geom_text(aes(label = n), hjust = -0.35, size = 3.1) +
  coord_flip() +
  facet_wrap(~ checklist, scales = "free_y", ncol = 1) +
  scale_x_discrete(labels = function(x) sub("^.*\u0001", "", x)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Reporting checklists shipped with mysterycall",
    subtitle = "Items per section. STROBE covers the design; these two cover what it omits.",
    x = NULL, y = "Checklist items"
  ) +
  mysterycall_bw_theme(base_size = 11) +
  theme(strip.text = element_text(face = "bold", hjust = 0, size = 9),
        panel.grid.major.y = element_blank())

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("man/figures/fig-reporting-checklists.png", p,
       width = 7.2, height = 6.4, dpi = 200, bg = "white")
message("wrote man/figures/fig-reporting-checklists.png")
