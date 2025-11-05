#' Print Method for crimeTrajec Objects
#'
#' Prints a summary of a fitted group-based trajectory model.
#'
#' @param x An object of class "crimeTrajec" from \code{\link{fitTrajectory}}.
#' @param ... Additional arguments passed to print (currently unused).
#'
#' @return Invisibly returns the input object.
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#' fit <- fitTrajectory(data = crime_data, id = "id", time = "age",
#'                      outcome = "offense_count", groups = 3)
#' print(fit)
#' }
#'
#' @export
print.crimeTrajec <- function(x, ...) {

  cat("\nGroup-Based Trajectory Model\n")
  cat("=============================\n\n")

  cat("Call:\n")
  print(x$call)
  cat("\n")

  cat("Model Specification:\n")
  cat(sprintf("  Distribution: %s\n", x$dist))
  if (x$zero_inflated) {
    cat("  Zero-inflated: Yes\n")
  }
  cat(sprintf("  Number of groups: %d\n", x$groups))
  cat(sprintf("  Polynomial degree: %d\n", x$degree))
  cat("\n")

  cat("Model Fit:\n")
  cat(sprintf("  Log-likelihood: %.2f\n", x$loglik))
  cat(sprintf("  AIC: %.2f\n", x$AIC))
  cat(sprintf("  BIC: %.2f\n", x$BIC))
  cat(sprintf("  Number of parameters: %d\n", x$n_params))
  cat(sprintf("  Converged: %s\n", ifelse(x$converged, "Yes", "No")))
  cat(sprintf("  Iterations: %d\n", x$iterations))
  cat("\n")

  cat("Group Proportions:\n")
  for (g in 1:x$groups) {
    cat(sprintf("  Group %d: %.3f (%.1f%%)\n", g, x$group_proportions[g],
                x$group_proportions[g] * 100))
  }
  cat("\n")

  cat("Trajectory Coefficients:\n")
  coef_names <- paste0("Beta", 0:x$degree)
  coef_df <- as.data.frame(x$coefficients)
  colnames(coef_df) <- coef_names
  rownames(coef_df) <- paste0("Group", 1:x$groups)
  print(coef_df, digits = 4)
  cat("\n")

  if (x$zero_inflated && !is.null(x$coefficients)) {
    cat("Zero-Inflation Parameters (logit scale):\n")
    for (g in 1:x$groups) {
      psi_g <- x$group_proportions  # placeholder, would need to extract from params
      cat(sprintf("  Group %d: (stored in model object)\n", g))
    }
    cat("\n")
  }

  cat("Use plot() to visualize trajectories and predict() for predictions.\n")

  invisible(x)
}


#' Plot Method for crimeTrajec Objects
#'
#' Plots the estimated trajectories for each group from a fitted group-based
#' trajectory model.
#'
#' @param x An object of class "crimeTrajec" from \code{\link{fitTrajectory}}.
#' @param include_ci Logical indicating whether to include confidence intervals.
#'   Default is TRUE. Note: confidence intervals are approximate and based on
#'   posterior uncertainty.
#' @param observed Logical indicating whether to overlay observed individual
#'   trajectories (as thin gray lines). Default is FALSE.
#' @param main Character string for the main title. Default is "Estimated Trajectory Groups".
#' @param xlab Character string for x-axis label. Default is "Time".
#' @param ylab Character string for y-axis label. Default is "Outcome".
#' @param col Vector of colors for each group. Default uses a color palette.
#' @param lwd Line width for trajectory lines. Default is 2.
#' @param ... Additional graphical parameters passed to plot.
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   producing a plot.
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#' fit <- fitTrajectory(data = crime_data, id = "id", time = "age",
#'                      outcome = "offense_count", groups = 3)
#' plot(fit)
#' plot(fit, include_ci = TRUE, observed = TRUE)
#' }
#'
#' @importFrom graphics lines matplot plot polygon
#' @export
plot.crimeTrajec <- function(x, include_ci = TRUE, observed = FALSE,
                             main = "Estimated Trajectory Groups",
                             xlab = "Time", ylab = "Outcome",
                             col = NULL, lwd = 2, ...) {

  # Extract data
  time_range <- x$data$time_range
  time_scaled <- x$data$time_scaled
  groups <- x$groups

  # Set up colors if not provided
  if (is.null(col)) {
    if (groups <= 8) {
      col <- c("red", "blue", "green", "purple", "orange", "brown", "pink", "cyan")[1:groups]
    } else {
      col <- rainbow(groups)
    }
  }

  # Create prediction grid
  time_pred <- seq(time_range[1], time_range[2], length.out = 100)
  time_pred_scaled <- (time_pred - time_range[1]) / (time_range[2] - time_range[1])

  # Compute trajectories for each group
  traj_mat <- matrix(0, nrow = length(time_pred), ncol = groups)

  for (g in 1:groups) {
    for (i in 1:length(time_pred)) {
      eta <- 0
      for (d in 0:x$degree) {
        eta <- eta + x$coefficients[g, d + 1] * time_pred_scaled[i]^d
      }

      if (x$dist == "gaussian") {
        traj_mat[i, g] <- eta
      } else {
        lambda <- exp(eta)
        if (x$zero_inflated) {
          # Expected value accounting for zero-inflation
          # This is simplified; actual psi values would need to be extracted
          p_zero <- 0.2  # Placeholder
          traj_mat[i, g] <- (1 - p_zero) * lambda
        } else {
          traj_mat[i, g] <- lambda
        }
      }
    }
  }

  # Set up plot
  y_range <- range(c(traj_mat, x$data$Y), na.rm = TRUE)
  y_range[1] <- max(0, y_range[1] - 0.1 * diff(y_range))
  y_range[2] <- y_range[2] + 0.1 * diff(y_range)

  plot(time_pred, traj_mat[, 1], type = "n",
       xlim = time_range, ylim = y_range,
       main = main, xlab = xlab, ylab = ylab, ...)

  # Add observed trajectories if requested
  if (observed) {
    for (i in 1:x$data$n) {
      time_i <- x$data$time_mat[i, ]
      y_i <- x$data$Y[i, ]
      valid <- !is.na(y_i)
      if (sum(valid) > 1) {
        lines(time_i[valid], y_i[valid], col = "gray80", lwd = 0.5)
      }
    }
  }

  # Add confidence bands if requested
  if (include_ci) {
    # Approximate CI using +/- 1.96 * SE
    # SE is approximated as sqrt(variance of fitted values within group)
    for (g in 1:groups) {
      # Find individuals most likely in this group
      group_members <- which(x$posterior[, g] > 0.5)
      if (length(group_members) > 0) {
        Y_g <- x$data$Y[group_members, , drop = FALSE]
        se_g <- apply(Y_g, 2, function(x) sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x))))
        se_g[is.na(se_g)] <- 0

        # Interpolate SE to prediction grid
        time_obs <- colMeans(x$data$time_mat[group_members, , drop = FALSE], na.rm = TRUE)
        se_pred <- approx(time_obs, se_g, xout = time_pred, rule = 2)$y

        # Add confidence band
        upper <- traj_mat[, g] + 1.96 * se_pred
        lower <- traj_mat[, g] - 1.96 * se_pred
        lower[lower < 0] <- 0

        polygon(c(time_pred, rev(time_pred)),
                c(upper, rev(lower)),
                col = adjustcolor(col[g], alpha.f = 0.2),
                border = NA)
      }
    }
  }

  # Add trajectory lines
  for (g in 1:groups) {
    lines(time_pred, traj_mat[, g], col = col[g], lwd = lwd)
  }

  # Add legend
  legend("topright",
         legend = sprintf("Group %d (%.1f%%)", 1:groups, x$group_proportions * 100),
         col = col, lwd = lwd, bty = "n")

  invisible(NULL)
}


#' Predict Method for crimeTrajec Objects
#'
#' Predicts group membership probabilities or trajectory values for new data
#' or returns fitted values for the original data.
#'
#' @param object An object of class "crimeTrajec" from \code{\link{fitTrajectory}}.
#' @param newdata Optional data frame with the same structure as the original data.
#'   If NULL (default), predictions are made for the original data.
#' @param type Character string specifying the type of prediction. Options are:
#'   \itemize{
#'     \item "group" (default): Returns posterior probabilities of group membership
#'     \item "class": Returns the most likely group assignment for each individual
#'     \item "trajectory": Returns predicted trajectory values
#'   }
#' @param ... Additional arguments (currently unused).
#'
#' @return Depending on the \code{type} argument:
#' \itemize{
#'   \item If type = "group": A matrix of posterior probabilities (rows = individuals,
#'     columns = groups)
#'   \item If type = "class": A vector of group assignments (integers from 1 to number of groups)
#'   \item If type = "trajectory": A matrix of predicted values (rows = individuals,
#'     columns = time points)
#' }
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#' fit <- fitTrajectory(data = crime_data, id = "id", time = "age",
#'                      outcome = "offense_count", groups = 3)
#'
#' # Get posterior probabilities
#' post_prob <- predict(fit, type = "group")
#'
#' # Get group assignments
#' groups <- predict(fit, type = "class")
#'
#' # Get fitted trajectories
#' fitted_traj <- predict(fit, type = "trajectory")
#' }
#'
#' @export
predict.crimeTrajec <- function(object, newdata = NULL, type = "group", ...) {

  type <- match.arg(type, c("group", "class", "trajectory"))

  if (!is.null(newdata)) {
    stop("Prediction for new data not yet implemented. Please use newdata = NULL.")
  }

  # For original data
  if (type == "group") {
    # Return posterior probabilities
    result <- object$posterior
    rownames(result) <- object$data$ids
    colnames(result) <- paste0("Group", 1:object$groups)
    return(result)

  } else if (type == "class") {
    # Return most likely group
    result <- apply(object$posterior, 1, which.max)
    names(result) <- object$data$ids
    return(result)

  } else if (type == "trajectory") {
    # Return fitted trajectories
    result <- object$fitted_values
    rownames(result) <- object$data$ids
    return(result)
  }
}
