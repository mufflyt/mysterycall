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
```

## Arguments

- input_data:

  A data frame or CSV path containing `first` and `last` columns.
