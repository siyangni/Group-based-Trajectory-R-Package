# Tests for fitTrajectory function

test_that("fitTrajectory returns correct structure with Poisson distribution", {
  skip_if_not_installed("crimeTrajec")

  # Create minimal test data
  set.seed(123)
  n <- 50
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  fit <- fitTrajectory(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    dist = "poisson",
    groups = 2,
    degree = 1,
    zero_inflated = FALSE,
    verbose = FALSE,
    max_iter = 100
  )

  # Test object structure
  expect_s3_class(fit, "crimeTrajec")
  expect_true(fit$groups == 2)
  expect_true(fit$degree == 1)
  expect_equal(nrow(fit$coefficients), 2)
  expect_equal(ncol(fit$coefficients), 2)
  expect_equal(length(fit$group_proportions), 2)
  expect_true(all(fit$group_proportions >= 0))
  expect_equal(sum(fit$group_proportions), 1, tolerance = 0.001)
})

test_that("fitTrajectory works with ZIP distribution", {
  skip_if_not_installed("crimeTrajec")

  set.seed(456)
  n <- 50
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = c(rep(0, n * t_points * 0.3), rpois(n * t_points * 0.7, lambda = 3))
  )

  fit <- fitTrajectory(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    dist = "zip",
    groups = 2,
    degree = 1,
    verbose = FALSE,
    max_iter = 100
  )

  expect_s3_class(fit, "crimeTrajec")
  expect_true(fit$zero_inflated)
  expect_true(!is.null(fit$loglik))
  expect_true(!is.null(fit$BIC))
  expect_true(!is.null(fit$AIC))
})

test_that("fitTrajectory works with Gaussian distribution", {
  skip_if_not_installed("crimeTrajec")

  set.seed(789)
  n <- 50
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rnorm(n * t_points, mean = 5, sd = 2)
  )

  fit <- fitTrajectory(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    dist = "gaussian",
    groups = 2,
    degree = 1,
    verbose = FALSE,
    max_iter = 100
  )

  expect_s3_class(fit, "crimeTrajec")
  expect_equal(fit$dist, "gaussian")
  expect_false(fit$zero_inflated)
})

test_that("fitTrajectory handles missing data", {
  skip_if_not_installed("crimeTrajec")

  set.seed(111)
  n <- 50
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  # Introduce missing data
  test_data$outcome[sample(1:nrow(test_data), 20)] <- NA

  expect_no_error({
    fit <- fitTrajectory(
      data = test_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      dist = "poisson",
      groups = 2,
      degree = 1,
      verbose = FALSE,
      max_iter = 100
    )
  })
})

test_that("fitTrajectory handles different polynomial degrees", {
  skip_if_not_installed("crimeTrajec")

  set.seed(222)
  n <- 50
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  # Test degrees 0-3
  for (deg in 0:3) {
    fit <- fitTrajectory(
      data = test_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      dist = "poisson",
      groups = 2,
      degree = deg,
      verbose = FALSE,
      max_iter = 100
    )

    expect_equal(fit$degree, deg)
    expect_equal(ncol(fit$coefficients), deg + 1)
  }
})

test_that("fitTrajectory validates input", {
  test_data <- data.frame(
    id = rep(1:10, each = 5),
    time = rep(1:5, 10),
    outcome = rpois(50, lambda = 2)
  )

  # Test invalid data type
  expect_error(
    fitTrajectory(data = "not_a_dataframe", id = "id", time = "time", outcome = "outcome"),
    "data must be a data frame"
  )

  # Test missing columns
  expect_error(
    fitTrajectory(data = test_data, id = "missing_id", time = "time", outcome = "outcome"),
    "must exist in data"
  )

  # Test invalid number of groups
  expect_error(
    fitTrajectory(data = test_data, id = "id", time = "time", outcome = "outcome", groups = 0),
    "Number of groups must be at least 1"
  )

  # Test invalid polynomial degree
  expect_error(
    fitTrajectory(data = test_data, id = "id", time = "time", outcome = "outcome", degree = -1),
    "Polynomial degree must be non-negative"
  )

  # Test invalid distribution
  expect_error(
    fitTrajectory(data = test_data, id = "id", time = "time", outcome = "outcome", dist = "invalid"),
    "dist must be one of"
  )
})

test_that("fitTrajectory convergence information is recorded", {
  skip_if_not_installed("crimeTrajec")

  set.seed(333)
  n <- 50
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  fit <- fitTrajectory(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    dist = "poisson",
    groups = 2,
    degree = 1,
    verbose = FALSE,
    max_iter = 100
  )

  expect_true(!is.null(fit$converged))
  expect_true(!is.null(fit$iterations))
  expect_type(fit$converged, "logical")
  expect_type(fit$iterations, "integer")
  expect_true(fit$iterations <= 100)
})
