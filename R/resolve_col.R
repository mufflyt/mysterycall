# Resolve a column name against a set of known aliases.
#
# Returns `primary` when it is present in `data` (or when no alias matches);
# otherwise the first alias that is present. This lets output from
# mysterycall_run_workflow() -- which renames columns to short "standard" names
# such as `exclusion_reasons` -- flow into mysterycall_run_analysis(), whose
# documented defaults use the long names such as `reason_for_exclusions`,
# without silently dropping the steps that depend on those columns.
#
# Pure and side-effect free so it is straightforward to unit test; callers own
# any messaging about a substitution.
.mc_resolve_col <- function(data, primary, aliases = character(0)) {
  nms <- names(data)
  if (primary %in% nms) {
    return(primary)
  }
  hit <- aliases[aliases %in% nms]
  if (length(hit)) {
    return(hit[[1L]])
  }
  primary
}
