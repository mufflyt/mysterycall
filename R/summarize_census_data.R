#' Summarize Census Block Group Demographics
#'
#' These helpers aggregate American Community Survey (ACS) estimates returned by
#' [mysterycall_get_census_data()] to produce tidy summary tables and visualizations. They
#' focus on the sex-by-age table (B01001) so that analysts can quickly spot the
#' distribution of female populations across block groups or higher-level
#' geographies.
#'
#' @name census_summaries
NULL

#' Produce summary statistics from Census block group data
#'
#' @param census_df A data frame produced by [mysterycall_get_census_data()] (or another
#'   table containing equivalent columns).
#' @param group_vars Character vector of column names used to group the
#'   summaries. Defaults to `"statefp"`. Supply `character(0)` to receive a
#'   single summary row for the entire dataset.
#' @param reproductive_age_vars Character vector of female age estimate columns
#'   that should be treated as reproductive-age (defaults to
#'   `B01001_030E:B01001_038E`, representing 15 to 44 years).
#'
#' @return A tibble with one row per unique combination of `group_vars` and
#'   columns: `block_group_count` (integer), `total_population`,
#'   `female_population`, `male_population` (numerics), `reproductive_age_female`
#'   (numeric; sum of `reproductive_age_vars`), `female_share`, `male_share`,
#'   `reproductive_age_female_share` (proportions 0-1; `NA` when
#'   `total_population` is zero or all relevant estimates are missing). Returns
#'   an empty tibble when `census_df` has zero rows.
#' @export
#' @family census
#' @examples
#' census_example <- tibble::tibble(
#'   statefp = c("01", "01", "02"),
#'   countyfp = c("001", "001", "013"),
#'   geoid = c("010010201001", "010010201002", "020130001001"),
#'   B01001_001E = c(1200, 1300, 900),
#'   B01001_002E = c(560, 610, 420),
#'   B01001_026E = c(640, 690, 480),
#'   B01001_030E = c(45, 47, 32),
#'   B01001_031E = c(40, 41, 28),
#'   B01001_032E = c(35, 36, 22),
#'   B01001_033E = c(30, 32, 20),
#'   B01001_034E = c(55, 58, 38),
#'   B01001_035E = c(60, 63, 40),
#'   B01001_036E = c(62, 64, 42),
#'   B01001_037E = c(58, 60, 39),
#'   B01001_038E = c(56, 57, 37)
#' )
#'
#' mysterycall_summarize_census(census_example, group_vars = c("statefp"))
mysterycall_summarize_census <- function(census_df,
                                  group_vars = "statefp",
                                  reproductive_age_vars = sprintf("B01001_%03dE", 30:38)) {

  if (!is.data.frame(census_df)) {
    stop("`census_df` must be a data frame.", call. = FALSE)
  }

  census_tbl <- tibble::as_tibble(census_df)

  if (!nrow(census_tbl)) {
    return(tibble::tibble())
  }

  required_columns <- c("B01001_001E", "B01001_026E")
  missing_required <- setdiff(required_columns, names(census_tbl))

  if (length(missing_required)) {
    stop("Missing required columns: ", paste(missing_required, collapse = ", "), ".", call. = FALSE)
  }

  if (length(group_vars) && !all(group_vars %in% names(census_tbl))) {
    stop("Grouping variables not found in census data: ",
      paste(setdiff(group_vars, names(census_tbl)), collapse = ", "),
      call. = FALSE
    )
  }

  numeric_cols <- unique(c(required_columns, "B01001_002E", reproductive_age_vars))
  numeric_cols <- intersect(numeric_cols, names(census_tbl))

  if (length(numeric_cols)) {
    census_tbl <- dplyr::mutate(
      census_tbl,
      dplyr::across(
        dplyr::all_of(numeric_cols),
        ~ suppressWarnings(as.numeric(.x))
      )
    )
  }

  has_male_totals <- "B01001_002E" %in% names(census_tbl)
  has_reproductive_ages <- all(reproductive_age_vars %in% names(census_tbl))

  if (has_reproductive_ages) {
    census_tbl <- dplyr::mutate(
      census_tbl,
      reproductive_age_female = rowSums(
        dplyr::select(census_tbl, dplyr::all_of(reproductive_age_vars)),
        na.rm = TRUE
      )
    )
  } else {
    census_tbl$reproductive_age_female <- NA_real_
  }

  grouped_tbl <- if (length(group_vars)) {
    dplyr::group_by(census_tbl, !!!rlang::syms(group_vars))
  } else {
    census_tbl
  }

  summarized <- dplyr::summarize(
    grouped_tbl,
    block_group_count = dplyr::n(),
    total_population = sum(.data$B01001_001E, na.rm = TRUE),
    female_population = sum(.data$B01001_026E, na.rm = TRUE),
    male_population = if (has_male_totals) sum(.data$B01001_002E, na.rm = TRUE) else NA_real_,
    reproductive_age_female = if (has_reproductive_ages) sum(.data$reproductive_age_female, na.rm = TRUE) else NA_real_,
    .groups = "drop"
  )

  summarized <- dplyr::mutate(
    summarized,
    female_share = ifelse(total_population > 0, female_population / total_population, NA_real_),
    male_share = ifelse(total_population > 0 & !is.na(male_population), male_population / total_population, NA_real_),
    reproductive_age_female_share = ifelse(
      female_population > 0 & !is.na(reproductive_age_female),
      reproductive_age_female / female_population,
      NA_real_
    )
  )

  if (length(group_vars)) {
    summarized <- dplyr::ungroup(summarized)
  }

  summarized
}

#' Plot the distribution of female age groups
#'
#' @inheritParams mysterycall_summarize_census
#' @param group_var Optional single column name used to facet the distribution.
#'   When supplied, stacked bars are produced for each value of `group_var`. Set
#'   to `NULL` (the default) to visualize the aggregate distribution across all
#'   rows in `census_df`.
#' @param output_dir Directory where image files should be written. Defaults to a
#'   session-specific directory from [mysterycall_tempdir()].
#' @param file_prefix Prefix used when writing plot files. Defaults to
#'   "census_age_distribution".
#' @param dpi Resolution used when saving the plots (defaults to 600 DPI).
#' @param verbose When `TRUE`, prints the output file paths after saving.
#'
#' @return Invisibly returns the generated ggplot object.
#' @export
#' @family census
#' @examplesIf interactive()
#'   mysterycall_plot_census_age(census_example, group_var = "statefp", verbose = FALSE)
mysterycall_plot_census_age <- function(census_df,
                                          group_var = NULL,
                                          output_dir = NULL,
                                          file_prefix = "census_age_distribution",
                                          dpi = 600,
                                          verbose = TRUE) {
  if (!requireNamespace("tidyr", quietly = TRUE)) {
    stop("Package 'tidyr' is required for this function", call. = FALSE)
  }

  if (!is.data.frame(census_df)) {
    stop("`census_df` must be a data frame.", call. = FALSE)
  }

  census_tbl <- tibble::as_tibble(census_df)

  if (!nrow(census_tbl)) {
    stop("`census_df` must contain at least one row to create a plot.", call. = FALSE)
  }

  age_vars <- sprintf("B01001_%03dE", 27:49)
  available_age_vars <- intersect(age_vars, names(census_tbl))

  if (!length(available_age_vars)) {
    stop("Female age estimate columns (B01001_027E:B01001_049E) were not found.", call. = FALSE)
  }

  census_tbl <- dplyr::mutate(
    census_tbl,
    dplyr::across(
      dplyr::all_of(available_age_vars),
      ~ suppressWarnings(as.numeric(.x))
    )
  )

  age_labels <- c(
    B01001_027E = "Under 5",
    B01001_028E = "5 to 9",
    B01001_029E = "10 to 14",
    B01001_030E = "15 to 17",
    B01001_031E = "18 to 19",
    B01001_032E = "20",
    B01001_033E = "21",
    B01001_034E = "22 to 24",
    B01001_035E = "25 to 29",
    B01001_036E = "30 to 34",
    B01001_037E = "35 to 39",
    B01001_038E = "40 to 44",
    B01001_039E = "45 to 49",
    B01001_040E = "50 to 54",
    B01001_041E = "55 to 59",
    B01001_042E = "60 and 61",
    B01001_043E = "62 to 64",
    B01001_044E = "65 and 66",
    B01001_045E = "67 to 69",
    B01001_046E = "70 to 74",
    B01001_047E = "75 to 79",
    B01001_048E = "80 to 84",
    B01001_049E = "85 and over"
  )

  age_long <- tidyr::pivot_longer(
    census_tbl,
    cols = dplyr::all_of(available_age_vars),
    names_to = "age_variable",
    values_to = "estimate"
  )

  age_long <- dplyr::mutate(
    age_long,
    age_label = factor(age_labels[.data$age_variable], levels = age_labels),
    estimate = suppressWarnings(as.numeric(.data$estimate))
  )

  if (!is.null(group_var)) {
    if (length(group_var) != 1L) {
      stop("`group_var` must be a single column name or NULL.", call. = FALSE)
    }

    if (!group_var %in% names(census_tbl)) {
      stop("`group_var` not found in census data: ", group_var, call. = FALSE)
    }

    aggregated <- age_long |>
      dplyr::group_by(.data[[group_var]], .data$age_label) |>
      dplyr::summarize(population = sum(.data$estimate, na.rm = TRUE), .groups = "drop") |>
      dplyr::group_by(.data[[group_var]]) |>
      dplyr::mutate(share = ifelse(sum(population) > 0, population / sum(population), NA_real_)) |>
      dplyr::ungroup()

    plot <- ggplot2::ggplot(
      aggregated,
      ggplot2::aes(x = .data[[group_var]], y = share, fill = age_label)
    ) +
      ggplot2::geom_col(position = "stack") +
      ggplot2::coord_flip() +
      ggplot2::scale_y_continuous(labels = scales::percent_format()) +
      ggplot2::scale_fill_viridis_d(option = "plasma", direction = -1) +
      ggplot2::labs(
        x = group_var,
        y = "Female population share",
        fill = "Female age group",
        title = "Female age distribution by geography"
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        legend.position = "bottom",
        legend.title = ggplot2::element_text(face = "bold"),
        axis.title = ggplot2::element_text(face = "bold"),
        plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)
      )
  } else {
    aggregated <- age_long |>
      dplyr::group_by(.data$age_label) |>
      dplyr::summarize(population = sum(.data$estimate, na.rm = TRUE), .groups = "drop")

    total_population <- sum(aggregated$population, na.rm = TRUE)
    aggregated <- dplyr::mutate(
      aggregated,
      share = ifelse(total_population > 0, population / total_population, NA_real_)
    )

    plot <- ggplot2::ggplot(aggregated, ggplot2::aes(x = age_label, y = share, fill = age_label)) +
      ggplot2::geom_col() +
      ggplot2::coord_flip() +
      ggplot2::scale_y_continuous(labels = scales::percent_format()) +
      ggplot2::scale_fill_viridis_d(option = "plasma", direction = -1) +
      ggplot2::labs(
        x = "Female age group",
        y = "Female population share",
        fill = "Female age group",
        title = "Female age distribution"
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        legend.position = "none",
        axis.title = ggplot2::element_text(face = "bold"),
        plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)
      )
  }

  invisible(plot)

  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("census_age_plots", create = TRUE)
  } else if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  tiff_path <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".tiff"))
  png_path <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".png"))

  ggplot2::ggsave(tiff_path, plot = plot, dpi = dpi, height = 6, width = 8, units = "in", compression = "lzw")
  ggplot2::ggsave(png_path, plot = plot, dpi = dpi, height = 6, width = 8, units = "in")

  if (isTRUE(verbose)) {
    cat("Plots saved to:", tiff_path, "and", png_path, "\n")
  }

  invisible(plot)
}

