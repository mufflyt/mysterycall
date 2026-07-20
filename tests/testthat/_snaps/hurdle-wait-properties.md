# Snapshot: the output schema is frozen

    Code
      cat("class:        ", paste(class(res), collapse = ", "), "\n")
    Output
      class:         mysterycall_hurdle_wait 
    Code
      cat("names:        ", paste(names(res), collapse = ", "), "\n")
    Output
      names:         hurdle, count, n_hurdle, n_count, count_family, truncated, hurdle_model, count_model 
    Code
      cat("hurdle cols:  ", paste(names(res$hurdle), collapse = ", "), "\n")
    Output
      hurdle cols:   term, estimate, conf_low, conf_high, p_value 
    Code
      cat("count cols:   ", paste(names(res$count), collapse = ", "), "\n")
    Output
      count cols:    term, estimate, conf_low, conf_high, p_value 
    Code
      cat("hurdle terms: ", paste(sort(res$hurdle$term), collapse = ", "), "\n")
    Output
      hurdle terms:  (Intercept), insuranceMedicaid 
    Code
      cat("count terms:  ", paste(sort(res$count$term), collapse = ", "), "\n")
    Output
      count terms:   (Intercept), insuranceMedicaid 
    Code
      cat("count_family: ", res$count_family, "\n")
    Output
      count_family:  nbinom2 
    Code
      cat("truncated:    ", res$truncated, "\n")
    Output
      truncated:     TRUE 
    Code
      cat("adf cols:     ", paste(names(df), collapse = ", "), "\n")
    Output
      adf cols:      part, term, estimate, conf_low, conf_high, p_value 
    Code
      cat("adf parts:    ", paste(unique(as.character(df$part)), collapse = ", "),
      "\n")
    Output
      adf parts:     hurdle, count 

