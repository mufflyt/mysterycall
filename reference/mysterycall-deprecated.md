# Deprecated functions in mysterycall

These names were used before `mysterycall` adopted a consistent
`mysterycall_` prefix. They emit deprecation warnings and forward all
arguments to the current equivalent.

## Usage

``` r
arsenal_tables_write2word(...)

calculate_intersection_overlap_and_save(...)

check_normality(...)

clean_phase_1_results(...)

clean_phase_2_data(...)

create_and_plot_interaction(...)

create_density_plot(...)

create_formula(...)

create_individual_isochrone_plots(...)

create_isochrones(...)

create_isochrones_for_dataframe(...)

create_line_plot(...)

create_scatter_plot(...)

download_large_file(...)

format_pct(...)

genderize_physicians(...)

geocode_unique_addresses(...)

get_census_data(...)

hrr(...)

hrr_generate_maps(...)

map_create_acog_districts_sf(...)

map_create_base(...)

map_create_block_group_overlap(...)

map_create_leaflet_base(...)

map_create_physician_dot(...)

max_table(...)

min_table(...)

most_common_gender_training_academic(...)

physician_age(...)

plot_and_save_emmeans(...)

plot_census_age_distribution(...)

remove_constant_vars(...)

remove_near_zero_var(...)

rename_columns_by_substring(...)

retrieve_clinician_data(...)

run_mystery_caller_workflow(...)

run_mystery_caller_workflow_with_logging(...)

save_quality_check_table(...)

search_and_process_npi(...)

search_by_taxonomy(...)

split_and_save(...)

states_where_physicians_were_NOT_contacted(...)

summarize_census_data(...)

table_calculate_percentages(...)

table_calculate_proportion(...)

table_generate_overall(...)

table_write_pdf(...)

validate_and_remove_invalid_npi(...)

search_npi(input_data, ...)

test_and_process_isochrones(input_file, ...)

tyler_log_cache_hit(...)

tyler_log_error(...)

tyler_log_info(...)

tyler_log_progress(...)

tyler_log_save(...)

tyler_log_step(...)

tyler_log_step_complete(...)

tyler_log_success(...)

tyler_log_warning(...)

tyler_map_acog_districts(...)

tyler_map_base(...)

tyler_map_block_group(...)

tyler_map_leaflet(...)

tyler_map_physicians(...)

tyler_max_table(...)

tyler_min_table(...)

tyler_most_common_gender(...)

tyler_multi_complete(...)

tyler_multi_done(...)

tyler_multi_progress(...)

tyler_multi_step(...)

tyler_multi_update(...)

tyler_not_contacted_states(...)

tyler_physician_age(...)

tyler_plot_census_age(...)

tyler_plot_density(...)

tyler_plot_emmeans(...)

tyler_plot_interaction(...)

tyler_plot_isochrones(...)

tyler_plot_line(...)

tyler_plot_scatter(...)

tyler_preflight_check(...)

tyler_print_dashboard(...)

tyler_progress_bar(...)

tyler_progress_callback(...)

tyler_progress_done(...)

tyler_progress_fail(...)

tyler_progress_finish(...)

tyler_progress_map(...)

tyler_progress_start(...)

tyler_progress_summary(...)

tyler_progress_tracker(...)

tyler_progress_update(...)

tyler_quality_tier(...)

tyler_format_pct(...)

tyler_check_normality(...)

tyler_remove_constants(...)

tyler_remove_near_zero(...)

tyler_rename_columns(...)

tyler_resolve_path(...)

tyler_run_workflow(...)

tyler_run_workflow_logged(...)

tyler_save_quality_table(...)

tyler_scan_for_limits(...)

tyler_search_and_process_npi(...)

tyler_search_taxonomy(...)

tyler_spinner_start(...)

tyler_spinner_stop(...)

tyler_split_and_save(...)

tyler_standard_labels(...)

tyler_standard_palette(...)

tyler_summarize_census(...)

tyler_table_overall(...)

tyler_table_percentages(...)

tyler_table_proportion(...)

tyler_use_quiet_logging(...)

tyler_validate_npi(...)

tyler_workflow_end(...)

tyler_workflow_start(...)

tyler_write_arsenal_table(...)

tyler_write_table_pdf(...)
```

## Arguments

- input_data:

  A data frame or CSV path containing `first` and `last` columns.
