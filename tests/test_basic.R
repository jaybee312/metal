testthat::test_that("coverage ratio exists", {
  con <- connect_db()
  df <- dbReadTable(con, "features_coverage")
  testthat::expect_true("coverage_ratio" %in% names(df))
  dbDisconnect(con)
})
