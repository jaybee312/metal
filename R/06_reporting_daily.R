# Enhanced daily report: narrative + 7-day history with trend arrows
source("R/00_utils.R")
suppressPackageStartupMessages({
  library(dplyr)
  library(glue)
  library(lubridate)
})

con <- connect_db()

regime <- DBI::dbReadTable(con, "features_regime_daily")
if (!nrow(regime)) stop("features_regime_daily is empty — run previous steps first")

# Ensure date typed properly
regime$date <- as.Date(regime$date)

# --- Helpers ---
trend_arrow <- function(delta, zero_tol = 0) {
  ifelse(is.na(delta), "·",
         ifelse(delta > zero_tol, "↑",
                ifelse(delta < -zero_tol, "↓", "→")))
}

fmt_num <- function(x, digits = 3) {
  ifelse(is.na(x), "NA", format(round(x, digits), nsmall = digits, trim = TRUE))
}

# --- Latest + previous for narrative ---
today_date <- max(regime$date, na.rm = TRUE)
latest <- regime %>% filter(date == today_date)
prev   <- regime %>% filter(date == today_date - 1)

summary <- list(
  date = as.character(today_date),
  regime = latest$regime[1],
  confidence = latest$confidence[1],
  coverage_ratio = latest$coverage_ratio[1],
  backwardation_index = latest$backwardation_index[1],
  note = "Live data integration pending — values simulated for structure testing."
)

# Trends (vs. prior day)
trend <- if (nrow(prev)) {
  list(
    cov = ifelse(summary$coverage_ratio < prev$coverage_ratio[1], "falling", "rising"),
    back = ifelse(summary$backwardation_index > prev$backwardation_index[1], "steepening", "flattening")
  )
} else {
  list(cov = "n/a", back = "n/a")
}

# --- Narrative text ---
coverage <- summary$coverage_ratio
back <- summary$backwardation_index
reg <- summary$regime

summary$text <- switch(
  reg,
  "Squeeze" = glue(
    "Silver market remains under **squeeze conditions** with coverage ratio at {fmt_num(coverage)} and backwardation {fmt_num(back)} ({trend$back}). ",
    "Physical tightness is evident — monitor COMEX registered ounces and retail premium spreads. ",
    "Expect heightened volatility and potential delivery stress if this persists 2–3 more sessions."
  ),
  "Tightening" = glue(
    "Coverage ratio ({fmt_num(coverage)}) is below long-term averages, indicating **tightening supply** ({trend$cov}). ",
    "Backwardation is {trend$back}, suggesting modest near-term pressure. ",
    "Monitor ETF outflows and COT positioning for confirmation of a sustained squeeze."
  ),
  "Neutral" = glue(
    "Market appears **balanced** with coverage ratio {fmt_num(coverage)} and term structure near flat ({fmt_num(back)}). ",
    "No immediate stress signals; await a decisive shift in coverage/backwardation."
  ),
  glue("Current regime: {reg}.")
)

summary$actions <- switch(
  reg,
  "Squeeze" = c(
    "✅ Favor long exposure or hedged call structures.",
    "⚠️ Watch COMEX registered stock; rapid depletion is unsustainable.",
    "📈 Monitor retail premium spikes (signal of retail panic)."
  ),
  "Tightening" = c(
    "📊 Maintain core positions; add selectively on dips.",
    "🔍 Track futures OI vs. inventory — divergence can precede squeezes.",
    "⏳ Be patient; sustained tightening often leads to breakouts."
  ),
  "Neutral" = c(
    "🧭 Stay flat or delta-neutral until clear direction.",
    "📉 Avoid over-leverage; low signal-to-noise.",
    "👀 Watch coverage ratio < 0.35 for early stress signs."
  ),
  c("No actionable signals today.")
)

# --- Build 7-day mini history with arrows ---
hist_days <- 7
hist_df <- regime %>%
  arrange(date) %>%
  filter(date >= (today_date - days(hist_days - 1))) %>%
  mutate(
    d_coverage = coverage_ratio - dplyr::lag(coverage_ratio),
    d_back     = backwardation_index - dplyr::lag(backwardation_index),
    cov_arrow  = trend_arrow(d_coverage),
    back_arrow = trend_arrow(d_back),
    cov_str    = paste0(fmt_num(coverage_ratio), " ", cov_arrow),
    back_str   = paste0(fmt_num(backwardation_index), " ", back_arrow)
  ) %>%
  select(date, regime, cov_str, back_str)

# Markdown table (pipe format)
md_hist <- if (nrow(hist_df)) {
  lines <- c(
    "| Date | Regime | Coverage | Backwardation |",
    "|------|--------|----------|---------------|"
  )
  rows <- apply(hist_df, 1, function(r) {
    paste0("| ", r[["date"]], " | ", r[["regime"]], " | ", r[["cov_str"]], " | ", r[["back_str"]], " |")
  })
  paste(c(lines, rows), collapse = "\n")
} else {
  "_No recent history available._"
}

# --- Write outputs ---
dir.create("report/daily", recursive = TRUE, showWarnings = FALSE)
path_json <- glue("report/daily/{summary$date}-summary.json")
path_md   <- glue("report/daily/{summary$date}-summary.md")

write_json_pretty(
  list(
    date = summary$date,
    regime = summary$regime,
    confidence = summary$confidence,
    coverage_ratio = summary$coverage_ratio,
    backwardation_index = summary$backwardation_index,
    trend = trend,
    narrative = summary$text,
    actions = summary$actions,
    history_rows = hist_df
  ),
  path_json
)

md <- paste0(
  "# Daily Metals Report — ", summary$date, "\n\n",
  "### Regime Summary\n",
  "**Regime:** ", summary$regime, " (confidence ", summary$confidence, ")\n\n",
  "**Coverage ratio:** ", fmt_num(summary$coverage_ratio),
  "  \n**Backwardation index:** ", fmt_num(summary$backwardation_index),
  "  \n**Trend:** Coverage ", trend$cov, ", Backwardation ", trend$back, "\n\n",
  "### Narrative\n", summary$text, "\n\n",
  "### Suggested Actions\n",
  paste0("- ", summary$actions, collapse = "\n"),
  "\n\n### Last 7 Sessions — Key Signals\n",
  md_hist, "\n\n",
  "---\n",
  "_Auto-generated at ", Sys.time(), "_\n"
)
writeLines(md, path_md)

DBI::dbDisconnect(con)
