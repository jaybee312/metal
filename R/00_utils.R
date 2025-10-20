suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(jsonlite)
  library(lubridate)
  library(glue)
})

# Connect to local DuckDB (default) or Postgres if you switch later.
connect_db <- function() {
  backend <- Sys.getenv("DB_BACKEND", "duckdb")
  if (backend == "postgres") {
    if (!requireNamespace("RPostgres", quietly = TRUE)) install.packages("RPostgres")
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      host = Sys.getenv("PGHOST", "localhost"),
      port = as.integer(Sys.getenv("PGPORT", "5432")),
      dbname = Sys.getenv("PGDATABASE", "metals"),
      user = Sys.getenv("PGUSER", "postgres"),
      password = Sys.getenv("PGPASSWORD", "")
    )
  } else {
    path <- Sys.getenv("DUCKDB_PATH", "db/duckdb/metals.duckdb")
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    # pass args to dbConnect(), not duckdb()
    con <- DBI::dbConnect(duckdb::duckdb(),
                          dbdir = path,
                          read_only = FALSE,
                          array = "matrix")
  }
  con
}

# Write/replace a table safely
write_table <- function(con, df, name) {
  message("Writing table: ", name)
  DBI::dbWriteTable(con, name, df, overwrite = TRUE)
}

# Pretty JSON writer
write_json_pretty <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(jsonlite::toJSON(x, pretty = TRUE, auto_unbox = TRUE), path)
}