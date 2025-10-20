source("R/00_utils.R")

con <- connect_db()

regime <- DBI::dbReadTable(con, "features_regime_daily")
if (!nrow(regime)) stop("features_regime_daily is empty — run previous steps first")

today  <- as.character(max(as.Date(regime$date)))
latest <- subset(regime, date == today)

summary <- list(
  date = today,
  regime = latest$regime[1],
  confidence = latest$confidence[1],
  coverage_ratio = latest$coverage_ratio[1],
  backwardation_index = latest$backwardation_index[1],
  note = "Mock data demo — replace with live pulls."
)

# Ensure output dir
dir.create("report/daily", recursive = TRUE, showWarnings = FALSE)

# Write JSON
path_json <- glue::glue("report/daily/{today}-summary.json")
write_json_pretty(summary, path_json)

# Write Markdown
path_md <- glue::glue("report/daily/{today}-summary.md")
md <- paste0(
  "# Daily Metals Report — ", today, "\n\n",
  "Regime: **", summary$regime, "** (confidence ", summary$confidence, ")\n\n",
  "Coverage: ", round(summary$coverage_ratio, 3), "  \n",
  "Backwardation: ", round(summary$backwardation_index, 3), "\n"
)
writeLines(md, path_md)

DBI::dbDisconnect(con)
