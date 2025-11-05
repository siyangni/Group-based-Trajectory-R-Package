# Tests for S3 methods

# Helper function to create a simple fitted model for testing
create_test_fit <- function() {
  set.seed(123)
  n <- 30
  t_points <- 5
  test_data <- data.frame(
    id = rep(1:n, each = t_points),
    time = rep(1:t_points, n),
    outcome = rpois(n * t_points, lambda = 2)
  )

  fitTrajectory(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    dist = "poisson",
    groups = 2,
    degree = 1,
    verbose = FALSE,
    max_iter = 50
  )
}

test_that("print.crimeTrajec displays correctly", {
  skip_if_not_installed("crimeTrajec")

  fit <- create_test_fit()

  # Capture output
  output <- capture.output(print(fit))

  expect_true(length(output) > 0)
  expect_true(any(grepl("Group-Based Trajectory Model", output)))
  expect_true(any(grepl("Model Specification", output)))
  expect_true(any(grepl("Group Proportions", output)))
  expect_true(any(grepl("Trajectory Coefficients", output)))
})

test_that("plot.crimeTrajec runs without error", {
  skip_if_not_installed("crimeTrajec")

  fit <- create_test_fit()

  # Test basic plot
  expect_no_error({
    plot(fit)
  })

  # Test with confidence intervals
  expect_no_error({
    plot(fit, include_ci = TRUE)
  })

  # Test with observed data
  expect_no_error({
    plot(fit, include_ci = FALSE, observed = FALSE)
  })
})

test_that("predict.crimeTrajec returns correct types", {
  skip_if_not_installed("crimeTrajec")

  fit <- create_test_fit()

  # Test type = "group"
  pred_group <- predict(fit, type = "group")
  expect_type(pred_group, "double")
  expect_true(is.matrix(pred_group))
  expect_equal(ncol(pred_group), fit$groups)
  expect_true(all(pred_group >= 0 & pred_group <= 1))
  expect_true(all(abs(rowSums(pred_group) - 1) < 0.001))

  # Test type = "class"
  pred_class <- predict(fit, type = "class")
  expect_type(pred_class, "integer")
  expect_true(is.vector(pred_class))
  expect_true(all(pred_class %in% 1:fit$groups))

  # Test type = "trajectory"
  pred_traj <- predict(fit, type = "trajectory")
  expect_type(pred_traj, "double")
  expect_true(is.matrix(pred_traj))
})

test_that("predict.crimeTrajec handles invalid input", {
  skip_if_not_installed("crimeTrajec")

  fit <- create_test_fit()

  # Test invalid type
  expect_error(
    predict(fit, type = "invalid"),
    "should be one of"
  )

  # Test newdata not yet implemented
  new_data <- data.frame(id = 1, time = 1, outcome = 1)
  expect_error(
    predict(fit, newdata = new_data),
    "not yet implemented"
  )
})

test_that("predict consistency between group and class", {
  skip_if_not_installed("crimeTrajec")

  fit <- create_test_fit()

  pred_group <- predict(fit, type = "group")
  pred_class <- predict(fit, type = "class")

  # Class should be argmax of group probabilities
  expected_class <- apply(pred_group, 1, which.max)
  expect_equal(pred_class, expected_class)
})

test_that("plot.crimeTrajec accepts custom parameters", {
  skip_if_not_installed("crimeTrajec")

  fit <- create_test_fit()

  expect_no_error({
    plot(fit, main = "Custom Title", xlab = "Time", ylab = "Count",
         col = c("red", "blue"), lwd = 3)
  })
})
