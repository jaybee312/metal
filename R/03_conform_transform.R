source("R/00_utils.R")

con <- connect_db()

futures   <- DBI::dbReadTable(con, "fact_futures_daily")
inventory <- DBI::dbReadTable(con, "fact_comex_inventory")

# Compute physical coverage ratio: registered oz / (OI * contract_size)
features_coverage <- futures |>
  dplyr::mutate(contract_size_oz = 5000) |>
  dplyr::left_join(inventory, by = c("date" = "date")) |>
  dplyr::mutate(
    coverage_ratio = ifelse(open_interest > 0,
                            registered_oz / (open_interest * contract_size_oz),
                            NA_real_)
  )

write_table(con, features_coverage, "features_coverage")

DBI::dbDisconnect(con)
