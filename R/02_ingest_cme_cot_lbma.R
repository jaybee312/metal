source("R/00_utils.R")

con <- connect_db()
dates <- seq.Date(Sys.Date() - 60, Sys.Date(), by = "1 day")

# Mock COMEX inventory (registered trending lower)
comex_inventory <- data.frame(
  date = dates,
  metal = "SILVER",
  registered_oz = seq(80, 55, length.out = length(dates)) * 1e6,
  eligible_oz   = seq(180, 165, length.out = length(dates)) * 1e6
)

# Mock futures for silver (SI) with front/second month
fact_futures_daily <- data.frame(
  date = dates,
  symbol = "SI",
  contract = "DEC25",
  settle = 27 + sin(seq_along(dates)/6),
  volume = sample(12000:22000, length(dates), replace = TRUE),
  open_interest = sample(55000:75000, length(dates), replace = TRUE),
  f1 = 27 + sin(seq_along(dates)/6),
  f2 = 27.10 + sin(seq_along(dates)/6)/2
)

write_table(con, comex_inventory, "fact_comex_inventory")
write_table(con, fact_futures_daily, "fact_futures_daily")

DBI::dbDisconnect(con)
