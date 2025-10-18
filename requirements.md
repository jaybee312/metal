# Metals Squeeze Research — REQUIREMENTS (R‑first)

**Owner:** JM
**Repo Name (suggested):** `metals-squeeze`
**Version:** v0.1 (initial public draft)
**Language Bias:** R‑first (with limited Python helpers where unavoidable)

---

## Executive Summary

This repository builds a **data + research pipeline** that explains metals market plumbing (paper ↔ physical), detects **short‑squeeze conditions**, and turns those signals into **portfolio actions** across GLD, SLV, GDX, GDXJ, SIL, and SILJ.

**Core Components:**

1. ETL in R for QuantKiosk + external sources (CME, CFTC, LBMA, ETF sponsors, FRED).
2. Normalized warehouse (DuckDB or Postgres) with schema + dictionary.
3. Derived indicators (coverage ratio, backwardation, lease/GOFO proxies, ETF tension, skew).
4. Regime engine that classifies daily states: Neutral, Tightening, Squeeze, Resolution, Expansion.
5. Reporting (daily JSON/Markdown, weekly RMarkdown, historical case studies).
6. Portfolio module mapping regime → target weights for GLD, SLV, GDX, GDXJ, SIL, SILJ.

---

## Repository Layout

```
metals-squeeze/
├─ README.md
├─ LICENSE
├─ .gitignore
├─ .env.example
├─ renv/
├─ renv.lock
├─ Makefile
├─ config/
│  ├─ data_sources.yaml
│  ├─ regime_spec.yaml
│  ├─ reporting.yaml
│  └─ universe.yaml
├─ data/
│  ├─ raw/
│  ├─ external/
│  └─ processed/
├─ db/
│  ├─ duckdb/
│  └─ migrations/
├─ R/
│  ├─ 00_utils.R
│  ├─ 01_ingest_quantkiosk.R
│  ├─ 02_ingest_cme_cot_lbma.R
│  ├─ 03_conform_transform.R
│  ├─ 04_features_indicators.R
│  ├─ 05_regime_engine.R
│  ├─ 06_reporting_daily.R
│  ├─ 07_reporting_weekly.Rmd
│  ├─ 08_case_studies.Rmd
│  └─ 99_tests.R
├─ tests/
│  ├─ testthat.R
│  └─ test_*.R
└─ docs/
   ├─ data_dictionary.md
   ├─ plumbing_primer.md
   └─ CHANGELOG.md
```

---

## Environment & Tooling

**R:** tidyverse, httr2, jsonlite, duckdb, DBI, arrow, data.table, lubridate, zoo, RMarkdown, gt, ggplot2, patchwork, yaml, purrr, glue, rlang, readr, janitor, testthat.
**Package manager:** renv
**Database:** DuckDB (default) or Postgres (optional).
**Rendering:** RMarkdown → HTML/PDF via pandoc/tinytex.
**Secrets:** `.env` file loaded via dotenv/config.

---

## Data Sources

| Vendor       | Purpose                                                    | Cadence | Auth       |
| ------------ | ---------------------------------------------------------- | ------- | ---------- |
| QuantKiosk   | Prices, options, ETF holdings/flows, filings, fundamentals | Daily   | QK_API_KEY |
| CME          | Futures, OI, warehouse stocks                              | Daily   | —          |
| CFTC         | Commitment of Traders                                      | Weekly  | —          |
| LBMA         | Vault holdings                                             | Monthly | —          |
| ETF Sponsors | GLD/SLV/PSLV metal held, shares                            | Daily   | —          |
| FRED         | WALCL, RRP, TGA, DXY, real rates                           | Weekly  | —          |

---

## Data Model (Warehouse)

**Dimensions:** `dim_instrument`, `dim_calendar`

**Facts:** `fact_futures_daily`, `fact_cot_weekly`, `fact_comex_inventory`, `fact_etf_holdings`, `fact_options_summary`, `fact_macro_liquidity`, `fact_ownership_flows`, `fact_fundamentals`, `fact_premiums_proxy`

All facts partitioned by date; indexed on symbol/ticker.

---

## Derived Indicators

| Indicator                  | Formula                                 | Meaning                      |
| -------------------------- | --------------------------------------- | ---------------------------- |
| Physical Coverage Ratio    | registered_oz / (oi * contract_size_oz) | Metal available per contract |
| Backwardation Index        | (f1 - f2) / f1                          | Spot scarcity measure        |
| Dealer Short Concentration | dealer_short_oi / total_oi              | Short squeeze pressure       |
| ETF Tension                | Δ metal_oz – spot_return                | Paper/physical divergence    |
| Lease Rate Proxy           | Forward – spot                          | Credit cost of holding metal |
| Vol Skew Pressure          | call_iv - put_iv                        | Sentiment indicator          |

---

## Regime Engine Specification

```yaml
z_window_days: 126
min_confidence: 0.55
signals:
  coverage:
    squeeze:   { lt: 0.25 }
    tightening:{ lt: 0.40 }
  backwardation:
    squeeze:   { gt_pct: 0.01 }
    tightening:{ gt_pct: 0.0 }
  lease:
    squeeze:   { gt_pct: 0.01 }
    tightening:{ gt_pct: 0.005 }
  dealer_short_z:
    tightening:{ gt: 1.0 }
  etf_tension_z:
    squeeze:   { gt: 1.5 }
  liquidity_pulse_z:
    expansion: { lt: -0.7 }
    neutral:   { between: [-0.7, 0.7] }
logic:
  - name: Squeeze
    when:
      all: [coverage.squeeze, backwardation.squeeze]
      any: [lease.squeeze, etf_tension_z.squeeze]
  - name: Tightening
    when:
      any: [coverage.tightening, backwardation.tightening, dealer_short_z.tightening]
  - name: Resolution
    when:
      allof:
        trending_up: [coverage]
        trending_down: [lease]
  - name: Expansion
    when:
      any: [liquidity_pulse_z.expansion]
  - name: Neutral
    fallback: true
```

---

## Reporting

**Daily**

* Input: indicators → regime engine
* Output: JSON + Markdown under `report/daily/`

  * Spot/futures summary (Au, Ag)
  * Indicator table with percentiles
  * Regime + confidence
  * Portfolio targets for GLD–SILJ
  * Stress flags
  * Narrative paragraph

**Weekly**

* Render RMarkdown HTML/PDF with: coverage trend, EFP heatmap, ETF vs price, lease curve, liquidity panel, historical overlay.

**Case Studies**

* Template sections: Context → Trigger → Mechanism → Resolution → Post‑mortem.

---

## Portfolio Integration

**Universe:** GLD, SLV, GDX, GDXJ, SIL, SILJ.

| Regime     | GLD | SLV | GDX | SIL | GDXJ | SILJ |
| ---------- | --- | --- | --- | --- | ---- | ---- |
| Neutral    | 30  | 10  | 20  | 10  | 5    | 5    |
| Tightening | 25  | 20  | 15  | 15  | 10   | 15   |
| Squeeze    | 10  | 30  | 10  | 10  | 20   | 20   |
| Resolution | 35  | 15  | 20  | 10  | 5    | 5    |
| Expansion  | 15  | 10  | 25  | 15  | 20   | 15   |

Bands ±5%, constrained by risk budget. Optional SLV/GLD call ladders in Tightening/Squeeze.

---

## Makefile Tasks

```
.DEFAULT_GOAL := help
help: ## List tasks
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' Makefile | awk -F':|##' '{printf "\033[36m%-22s\033[0m %s\n", $$1, $$3}'
renv: ## Init/restore R env
	Rscript -e "if (!require('renv')) install.packages('renv'); renv::restore()"
fetch: ## Run all ETL
	Rscript R/01_ingest_quantkiosk.R && Rscript R/02_ingest_cme_cot_lbma.R
build: ## Compute indicators + regime
	Rscript R/03_conform_transform.R && Rscript R/04_features_indicators.R && Rscript R/05_regime_engine.R
report-daily: ## Emit daily JSON/MD
	Rscript R/06_reporting_daily.R
report-weekly: ## Render weekly report
	Rscript -e "rmarkdown::render('R/07_reporting_weekly.Rmd', output_dir='report/weekly')"
test: ## Run tests
	Rscript -e "testthat::test_dir('tests')"
all: renv fetch build report-daily ## Full pipeline
```

---

## Config Examples

**`config/universe.yaml`**

```yaml
metals: [GLD, SLV]
miners: [GDX, GDXJ, SIL, SILJ]
contract_size_oz:
  GOLD: 100
  SILVER: 5000
```

**`config/reporting.yaml`**

```yaml
daily:
  include_tables: [summary, indicators, regime, allocations, stress_flags]
  stress_threshold_pct: 90
  narrative_template: "{date}: Coverage {coverage:.2f}, backwardation {back:.3%}, regime {regime} ({confidence:.0%})."
weekly:
  charts: [coverage_trend, efp_heatmap, etf_vs_price, lease_curve, liquidity_panel]
```

---

## Testing & Data Quality

* Unit tests for indicator math and edge cases.
* Schema validation on ingest.
* Repro checks for a sample day.
* Historical backfill tests (1979, 2008, 2020, 2021).

---

## Governance & Documentation

* License: MIT (default).
* Docs: `data_dictionary.md`, `plumbing_primer.md`, `CHANGELOG.md`.
* PRs must pass tests & DQ checks.

---

## Setup Instructions

```bash
git clone git@github.com:you/metals-squeeze.git
cd metals-squeeze
make renv
cp .env.example .env  # add API keys
make all
make report-weekly
```

Open reports in `report/daily/` and `report/weekly/`.

---

## Roadmap

* v0.2 – Options backtester (SLV/GLD calls)
* v0.3 – Miner fundamentals overlay (QuantKiosk)
* v0.4 – Regime clustering/PCA
* v1.0 – GitHub Action for scheduled builds

---

## Acceptance Criteria

* `make all` runs end‑to‑end on a clean machine.
* Daily report emits JSON + MD with valid data.
* Regime engine classifies full history with no gaps.
* Weekly HTML renders ≥5 charts + case study section.

---

**End of File**
