context("listOMLDataSets")

skip_on_cran()

test_that("listOMLDataSets", {
  for (dsl in list(.listOMLDataSets(limit = 10L), .listOMLDataSets(tag = "study_1", limit = 10L))) {
    expect_data_frame(dsl, col.names = "unique", min.rows = 1)
    expect_set_equal(names(dsl), c("did", "status", "format", "name", "MajorityClassSize",
      "MaxNominalAttDistinctValues", "MinorityClassSize", #"NumBinaryAtts",
      "NumberOfClasses", "NumberOfFeatures", "NumberOfInstances",
      "NumberOfInstancesWithMissingValues", "NumberOfMissingValues",
      "NumberOfNumericFeatures", "NumberOfSymbolicFeatures"))
    expect_integer(dsl$did, any.missing = FALSE, unique = TRUE)
    expect_factor(dsl$status, any.missing = FALSE)
    expect_character(dsl$name, any.missing = FALSE)
  }
})
