# mysterycall_standard_labels() output is stable

    Code
      mysterycall_standard_labels()
    Output
      $npi
      [1] "National Provider Identifier"
      
      $state
      [1] "State"
      
      $city
      [1] "City"
      
      $call_outcome
      [1] "Call Outcome"
      
      $quality
      [1] "Quality Tier"
      
      $call_time
      [1] "Call Duration (minutes)"
      
      $hold_time
      [1] "Hold Duration (minutes)"
      
      $eta
      [1] "Estimated Completion"
      

# mysterycall_standard_palette() primary palette is stable

    Code
      mysterycall_standard_palette("primary")
    Output
      [1] "#0B3C5D" "#328CC1" "#D9B310" "#1D2731"

# mysterycall_standard_palette() sequential palette is stable

    Code
      mysterycall_standard_palette("sequential")
    Output
      [1] "#f7fbff" "#c6dbef" "#6baed6" "#2171b5"

# mysterycall_standard_palette() diverging palette is stable

    Code
      mysterycall_standard_palette("diverging")
    Output
      [1] "#b30000" "#fdbf6f" "#1b7837"

# mysterycall_quality_tier() tier boundaries are stable

    Code
      mysterycall_quality_tier(1)
    Output
      [1] "high"
    Code
      mysterycall_quality_tier(0.9)
    Output
      [1] "high"
    Code
      mysterycall_quality_tier(0.89)
    Output
      [1] "medium"
    Code
      mysterycall_quality_tier(0.75)
    Output
      [1] "medium"
    Code
      mysterycall_quality_tier(0.74)
    Output
      [1] "low"
    Code
      mysterycall_quality_tier(0)
    Output
      [1] "low"

