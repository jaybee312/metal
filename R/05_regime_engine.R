source("R/00_utils.R")

con <- connect_db()
ind <- DBI::dbReadTable(con, "features_indicators")

# Minimal rules for demo:
# Squeeze: coverage < 0.25 and backwardation > 0
# Tightening: coverage < 0.4
# Neutral: otherwise
features_regime_daily <- ind |>
  dplyr::mutate(
    regime = dplyr::case_when(
      coverage_ratio < 0.25 & backwardation_index > 0 ~ "Squeeze",
      coverage_ratio < 0.40                            ~ "Tightening",
      TRUE                                             ~ "Neutral"
    ),
    confidence = dplyr::case_when(
      regime == "Squeeze"    ~ 0.75,
      regime == "Tightening" ~ 0.65,
      TRUE                   ~ 0.55
    )
  )

write_table(con, features_regime_daily, "features_regime_daily")

DBI::dbDisconnect(con)
