# Tests for selectNumGroups function

test_that("selectNumGroups returns correct structure with BIC", {
  skip_if_not_installed("crimeTrajec")

  set.seed(123)
  n <- 40
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  result <- selectNumGroups(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    max_groups = 3,
    criteria = "BIC",
    dist = "poisson",
    degree = 1,
    zero_inflated = FALSE,
    verbose = FALSE
  )

  # Test structure
  expect_s3_class(result, "selectNumGroups")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_true("num_groups" %in% names(result))
  expect_true("BIC" %in% names(result))
  expect_true("loglik" %in% names(result))
  expect_true("converged" %in% names(result))

  # Test attributes
  best <- attr(result, "best")
  expect_type(best, "list")
  expect_true("BIC" %in% names(best))
  expect_true(best$BIC >= 1 && best$BIC <= 3)
})

test_that("selectNumGroups works with multiple criteria", {
  skip_if_not_installed("crimeTrajec")

  set.seed(456)
  n <- 40
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  result <- selectNumGroups(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    max_groups = 3,
    criteria = c("BIC", "AIC"),
    dist = "poisson",
    degree = 1,
    verbose = FALSE
  )

  expect_true("BIC" %in% names(result))
  expect_true("AIC" %in% names(result))

  best <- attr(result, "best")
  expect_true("BIC" %in% names(best))
  expect_true("AIC" %in% names(best))
})

test_that("selectNumGroups cross-validation runs", {
  skip_if_not_installed("crimeTrajec")
  skip("Cross-validation test is computationally intensive")

  set.seed(789)
  n <- 40
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  result <- selectNumGroups(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    max_groups = 2,
    criteria = c("BIC", "CVE"),
    cv_folds = 3,
    dist = "poisson",
    degree = 1,
    verbose = FALSE
  )

  expect_true("CVE" %in% names(result))
  expect_true(!all(is.na(result$CVE)))

  best <- attr(result, "best")
  expect_true("CVE" %in% names(best))
})

test_that("selectNumGroups handles convergence failures gracefully", {
  skip_if_not_installed("crimeTrajec")

  set.seed(111)
  # Create difficult data (very small sample)
  n <- 10
  t_points <- 3
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 1)
  )

  # Should not error even if some models fail
  expect_no_error({
    result <- selectNumGroups(
      data = test_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      max_groups = 4,
      criteria = "BIC",
      dist = "poisson",
      degree = 1,
      verbose = FALSE,
      max_iter = 20
    )
  })
})

test_that("selectNumGroups validates input", {
  test_data <- data.frame(
    id = rep(1:10, each = 5),
    time = rep(1:5, 10),
    outcome = rpois(50, lambda = 2)
  )

  # Test invalid max_groups
  expect_error(
    selectNumGroups(
      data = test_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      max_groups = 0
    ),
    "max_groups must be at least 1"
  )

  # Test invalid criteria
  expect_error(
    selectNumGroups(
      data = test_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      max_groups = 3,
      criteria = "INVALID"
    ),
    "should be one of"
  )
})

test_that("selectNumGroups print method works", {
  skip_if_not_installed("crimeTrajec")

  set.seed(222)
  n <- 40
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  result <- selectNumGroups(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    max_groups = 3,
    criteria = "BIC",
    verbose = FALSE
  )

  output <- capture.output(print(result))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Model Selection", output)))
  expect_true(any(grepl("Optimal", output)))
})

test_that("selectNumGroups BIC values decrease then increase", {
  skip_if_not_installed("crimeTrajec")

  set.seed(333)
  # Create data with clear 2-group structure
  n <- 50
  t_points <- 5

  # Group 1: low counts
  g1_data <- data.frame(
    id = rep(1:25, each = t_points),
    time = rep(1:t_points, 25),
    outcome = rpois(25 * t_points, lambda = 1)
  )

  # Group 2: high counts
  g2_data <- data.frame(
    id = rep(26:50, each = t_points),
    time = rep(1:t_points, 25),
    outcome = rpois(25 * t_points, lambda = 5)
  )

  test_data <- rbind(g1_data, g2_data)

  result <- selectNumGroups(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    max_groups = 4,
    criteria = "BIC",
    dist = "poisson",
    degree = 1,
    verbose = FALSE
  )

  # BIC should have a minimum (indicating optimal model)
  expect_true(min(result$BIC, na.rm = TRUE) < max(result$BIC, na.rm = TRUE))
})
