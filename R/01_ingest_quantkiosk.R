source("R/00_utils.R")
set.seed(42)

con <- connect_db()

tickers <- c("GLD","SLV","GDX","GDXJ","SIL","SILJ")
dates <- seq.Date(Sys.Date() - 60, Sys.Date(), by = "1 day")

# Simple random walk mock close + volume
mock_prices <- tidyr::expand_grid(date = dates, ticker = tickers) |>
  dplyr::arrange(ticker, date) |>
  dplyr::group_by(ticker) |>
  dplyr::mutate(
    close = 100 + cumsum(rnorm(dplyr::n(), 0, 0.6)),
    volume = sample(100000:500000, dplyr::n(), replace = TRUE)
  ) |>
  dplyr::ungroup()

write_table(con, mock_prices, "fact_prices")

DBI::dbDisconnect(con)
