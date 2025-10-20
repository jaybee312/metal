# Metals Squeeze Research (R-first)

A complete R-based research and reporting pipeline for analyzing the “plumbing” between paper and physical precious-metals markets.
It identifies and tracks short-squeeze conditions in gold and silver, translating them into portfolio actions across GLD, SLV, GDX, GDXJ, SIL, and SILJ.

---

## Features

* ETL in R for QuantKiosk + CME, CFTC, LBMA, ETF sponsors, and FRED
* Local warehouse (DuckDB by default; Postgres optional)
* Derived indicators: coverage ratio, backwardation, lease proxy, ETF tension, vol-skew
* Regime Engine: classifies states — Neutral · Tightening · Squeeze · Resolution · Expansion
* Reporting: daily JSON + Markdown, weekly RMarkdown → HTML/PDF
* Portfolio targets for GLD, SLV, GDX, GDXJ, SIL, SILJ

---

## Requirements

| Tool               | Purpose                                  |
| ------------------ | ---------------------------------------- |
| R 4.3+             | Core language                            |
| renv               | Package management                       |
| pandoc / tinytex   | RMarkdown rendering                      |
| DuckDB             | Local analytics database                 |
| QuantKiosk API key | Live data (optional; mock works offline) |

No paid services required — everything runs locally.

---

## Directory Structure

metals-squeeze/
├─ config/               # YAML configs (data sources, regimes, reporting, universe)
├─ data/                 # raw/external/processed data (ignored in git)
├─ db/duckdb/            # local DuckDB file (ignored in git)
├─ R/                    # R scripts (ETL → indicators → regime → reports)
├─ report/               # daily & weekly outputs
├─ tests/                # testthat unit tests
├─ docs/                 # dictionary, primer, changelog
├─ .env.example          # environment variable template
├─ .gitignore
├─ Makefile
└─ REQUIREMENTS.md       # detailed technical spec

---

## Quick Start

git clone [git@github.com](mailto:git@github.com):jmizel312/metal.git
cd metals-squeeze
make renv                   # Initialize R environment
cp .env.example .env         # Add API keys (optional for mock)
make all                    # Full pipeline: ETL → regime → report
make report-weekly          # Render weekly HTML

Outputs:

* Database: db/duckdb/metals.duckdb
* Daily report: report/daily/YYYY-MM-DD-summary.{json,md}
* Weekly report: report/weekly/YYYY-WW.html (and .pdf if TinyTeX installed)

---

## Configuration Overview

### .env

DB_BACKEND=duckdb
DUCKDB_PATH=db/duckdb/metals.duckdb

# Optional Postgres settings:

# PGHOST=localhost

# PGPORT=5432

# PGDATABASE=metals

# PGUSER=postgres

# PGPASSWORD=changeme

QK_API_KEY=your_quantkiosk_key_here
FRED_API_KEY=optional

### config/universe.yaml

metals: [GLD, SLV]
miners: [GDX, GDXJ, SIL, SILJ]
contract_size_oz:
GOLD: 100
SILVER: 5000

### config/data_sources.yaml

Defines APIs and cadence for QuantKiosk, CME, CFTC, LBMA, ETF sponsors, and FRED.

### config/regime_spec.yaml

Thresholds and logic for regime classification — coverage, backwardation, lease rate, dealer short concentration, ETF tension, liquidity pulse — with smoothing and hysteresis.

### config/reporting.yaml

Controls which tables, stress flags, and narrative templates appear in daily and weekly reports.

---

## Makefile Commands

make renv            Initialize or restore R environment
make fetch           Run all ETL scripts
make build           Compute indicators and regimes
make report-daily    Generate daily JSON + Markdown
make report-weekly   Render weekly HTML
make test            Run tests
make all             End-to-end pipeline (ETL → report)

---

## Core R Scripts

R/00_utils.R – DB connection helpers (DuckDB/Postgres) + I/O
R/01_ingest_quantkiosk.R – QuantKiosk data ingest (mock until key added)
R/02_ingest_cme_cot_lbma.R – CME / CFTC / LBMA / ETF / FRED ingest (mock initially)
R/03_conform_transform.R – Data conformance and joins
R/04_features_indicators.R – Compute features: coverage, backwardation, z-scores
R/05_regime_engine.R – Apply regime logic from YAML spec
R/06_reporting_daily.R – Generate daily JSON + Markdown summary
R/07_reporting_weekly.Rmd – Render weekly HTML/PDF report
R/08_case_studies.Rmd – Historical squeeze case studies (optional)

---

## Key Indicators

Physical Coverage = registered_oz / (open_interest × contract_size_oz)
Backwardation Index = (F1 – F2) / F1
Dealer Short Concentration = dealer_short_oi / total_oi
ETF Tension = Δ metal_oz – spot_return
Lease Rate Proxy (GOFO) = forward – spot
Vol Skew Pressure = call IV – put IV

---

## Regime → Portfolio Mapping

Regime | GLD | SLV | GDX | SIL | GDXJ | SILJ
Neutral | 30 | 10 | 20 | 10 | 5 | 5
Tightening | 25 | 20 | 15 | 15 | 10 | 15
Squeeze | 10 | 30 | 10 | 10 | 20 | 20
Resolution | 35 | 15 | 20 | 10 | 5 | 5
Expansion | 15 | 10 | 25 | 15 | 20 | 15

(Bands ±5%; constrained by total risk budget.)

---

## Notes

* Runs entirely on your machine using DuckDB — no cloud dependency.
* Replace mock ETL with live API pulls once validated.
* Keep data/raw/, data/external/, and db/duckdb/*.duckdb out of version control.
* Reports auto-generate under report/.

---

## License

MIT License (or your preferred open-source license)



