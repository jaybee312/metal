source("R/00_utils.R")

con <- connect_db()
cov <- DBI::dbReadTable(con, "features_coverage")

# Indicators: backwardation + normalized z-scores
safe_scale <- function(x) {
  if (length(na.omit(x)) < 3) return(rep(NA_real_, length(x)))
  as.numeric(scale(x))
}

features_indicators <- cov |>
  dplyr::mutate(
    backwardation_index = (f1 - f2) / ifelse(f1 == 0, NA_real_, f1),
    coverage_z = safe_scale(coverage_ratio),
    backwardation_z = safe_scale(backwardation_index)
  )

write_table(con, features_indicators, "features_indicators")

DBI::dbDisconnect(con)
