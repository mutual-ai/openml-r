context("getCachedOMLDataSetStatus")

test_that("getCachedOMLDataSetStatus", {
  with_empty_cache({
    status = getCachedOMLDataSetStatus(limit = 100)
    expect_true(identical(dim(status), c(0L, 0L)))
    
    dids = 1:2
    populateOMLCache(dids = dids)
    
    status = getCachedOMLDataSetStatus(limit = 100)
    expect_is(status, "data.frame")
    expect_equal(nrow(status), length(dids))
    expect_true(all(dids %in% status$did))
  })
})
