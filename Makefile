# Metals Squeeze Makefile — minimal & robust

.PHONY: all renv fetch build report-daily report-weekly test clean

all: fetch build report-daily

renv:
	Rscript -e "if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv'); \
	if (!file.exists('renv.lock')) renv::init(bare=TRUE); \
	pkgs <- c('duckdb','DBI','dplyr','jsonlite','lubridate','glue','readr','rmarkdown','testthat','arrow','data.table','ggplot2','gt','patchwork','zoo','purrr','janitor','tidyr'); \
	to_install <- setdiff(pkgs, rownames(installed.packages())); if (length(to_install)) install.packages(to_install); \
	renv::snapshot(prompt=FALSE, force=TRUE); renv::restore()"

fetch:
	Rscript -e "source('R/01_ingest_quantkiosk.R')"
	Rscript -e "source('R/02_ingest_cme_cot_lbma.R')"

build:
	Rscript -e "source('R/03_conform_transform.R')"
	Rscript -e "source('R/04_features_indicators.R')"
	Rscript -e "source('R/05_regime_engine.R')"

report-daily:
	Rscript -e "source('R/06_reporting_daily.R')"

report-weekly:
	Rscript -e "rmarkdown::render('R/07_reporting_weekly.Rmd', output_dir='report/weekly')"

test:
	Rscript -e "testthat::test_dir('tests')"

clean:
	rm -rf db/duckdb/*.duckdb
	rm -rf report/daily/*.json report/daily/*.md report/weekly/*.html
