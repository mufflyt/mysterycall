# Snapshot: normalized audit structure is stable

    Code
      names(normalized)
    Output
       [1] "artifact_id"            "cohort_hash"            "empty_names_count"     
       [4] "function_name"          "generated_ids_count"    "input_colnames"        
       [7] "input_cols"             "input_npi_count"        "input_rows"            
      [10] "no_last_name_count"     "original_npi_preserved" "output_cols"           
      [13] "output_rows"            "quality_metrics"        "rows_duplicated"       
      [16] "rows_retained_pct"      "schema_version"        

# Snapshot: quality_metrics keys are stable

    Code
      sort(names(audit$quality_metrics))
    Output
      [1] "completeness_names"   "completeness_npi"     "completeness_phone"  
      [4] "has_processing_flags"

# Snapshot: schema_version value is locked

    {
      "type": "character",
      "attributes": {},
      "value": ["1.2.0"]
    }

