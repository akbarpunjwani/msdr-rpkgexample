test_that("summarized data have correct shape", {
  expect_equal(length(fars_summarize_years(2013:2015)), 4)
  expect_equal(length(fars_summarize_years(2013:2015)[[1]]), 12)
})
