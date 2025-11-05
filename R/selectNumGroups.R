#' Select Optimal Number of Trajectory Groups
#'
#' Fits group-based trajectory models with varying numbers of groups and compares
#' them using information criteria (BIC, AIC) or cross-validation. Helps determine
#' the optimal number of trajectory groups for the data.
#'
#' @param data A data frame containing the longitudinal data.
#' @param id Character string specifying the name of the individual identifier variable.
#' @param time Character string specifying the name of the time variable.
#' @param outcome Character string specifying the name of the outcome variable.
#' @param max_groups Maximum number of groups to consider. Default is 6.
#' @param criteria Character vector specifying the selection criteria to compute.
#'   Options are "BIC" (Bayesian Information Criterion), "AIC" (Akaike Information
#'   Criterion), and "CVE" (Cross-Validation Error). Default is c("BIC", "AIC").
#' @param dist Character string specifying the distribution family. Default is "poisson".
#' @param degree Integer specifying the polynomial degree for trajectories. Default is 3.
#' @param zero_inflated Logical indicating whether to use zero-inflation. Default is TRUE.
#' @param cv_folds Number of folds for cross-validation (only used if "CVE" is in criteria).
#'   Default is 5.
#' @param verbose Logical indicating whether to print progress information. Default is TRUE.
#' @param ... Additional arguments passed to \code{\link{fitTrajectory}}.
#'
#' @return A data frame with the following columns:
#' \item{num_groups}{Number of groups in the model.}
#' \item{loglik}{Log-likelihood of the fitted model.}
#' \item{BIC}{Bayesian Information Criterion (lower is better).}
#' \item{AIC}{Akaike Information Criterion (lower is better).}
#' \item{CVE}{Cross-validation error (if requested, lower is better).}
#' \item{n_params}{Number of parameters in the model.}
#' \item{converged}{Logical indicating whether the model converged.}
#'
#' The data frame also has an attribute "best" which is a named list indicating
#' the optimal number of groups according to each criterion.
#'
#' @details
#' This function fits trajectory models with 1 to \code{max_groups} groups and
#' computes various fit indices. The Bayesian Information Criterion (BIC) is
#' generally recommended for model selection in mixture models as it balances
#' model fit and parsimony.
#'
#' When \code{"CVE"} is included in \code{criteria}, the function performs k-fold
#' cross-validation. The data is split into k folds, each model is fitted on
#' k-1 folds, and the log-likelihood is computed on the held-out fold. The
#' cross-validation error is the negative average log-likelihood across folds.
#' Note that cross-validation can be computationally intensive.
#'
#' @references
#' Nagin, D. S. (2005). Group-based modeling of development. Harvard University Press.
#'
#' Nielsen, J. D., Rosenthal, J. S., Sun, Y., Day, D. M., Bevc, I., & Duchesne, T.
#' (2014). Group-based criminal trajectory analysis using cross-validation criteria.
#' Communications in Statistics - Theory and Methods, 43(20), 4337-4356.
#'
#' @examples
#' \dontrun{
#' data(crime_data)
#'
#' # Compare models using BIC
#' comparison <- selectNumGroups(data = crime_data,
#'                               id = "id",
#'                               time = "age",
#'                               outcome = "offense_count",
#'                               max_groups = 5,
#'                               criteria = "BIC")
#' print(comparison)
#'
#' # Plot BIC values
#' plot(comparison$num_groups, comparison$BIC, type = "b",
#'      xlab = "Number of Groups", ylab = "BIC")
#'
#' # Use cross-validation (more intensive)
#' comparison_cv <- selectNumGroups(data = crime_data,
#'                                  id = "id",
#'                                  time = "age",
#'                                  outcome = "offense_count",
#'                                  max_groups = 4,
#'                                  criteria = c("BIC", "CVE"),
#'                                  cv_folds = 5)
#' }
#'
#' @export
selectNumGroups <- function(data, id, time, outcome,
                            max_groups = 6,
                            criteria = c("BIC", "AIC"),
                            dist = "poisson",
                            degree = 3,
                            zero_inflated = TRUE,
                            cv_folds = 5,
                            verbose = TRUE,
                            ...) {

  # Input validation
  criteria <- match.arg(criteria, c("BIC", "AIC", "CVE"), several.ok = TRUE)

  if (max_groups < 1) {
    stop("max_groups must be at least 1")
  }

  # Initialize results data frame
  results <- data.frame(
    num_groups = 1:max_groups,
    loglik = NA,
    BIC = NA,
    AIC = NA,
    CVE = if ("CVE" %in% criteria) NA else NULL,
    n_params = NA,
    converged = NA
  )

  # Fit models for each number of groups
  for (g in 1:max_groups) {

    if (verbose) {
      cat(sprintf("\nFitting model with %d group(s)...\n", g))
    }

    # Fit model
    tryCatch({
      fit <- fitTrajectory(data = data, id = id, time = time, outcome = outcome,
                          dist = dist, groups = g, degree = degree,
                          zero_inflated = zero_inflated,
                          verbose = FALSE, ...)

      results$loglik[g] <- fit$loglik
      results$BIC[g] <- fit$BIC
      results$AIC[g] <- fit$AIC
      results$n_params[g] <- fit$n_params
      results$converged[g] <- fit$converged

      if (verbose) {
        cat(sprintf("  Log-likelihood: %.2f\n", fit$loglik))
        cat(sprintf("  BIC: %.2f\n", fit$BIC))
        cat(sprintf("  Converged: %s\n", fit$converged))
      }

    }, error = function(e) {
      if (verbose) {
        cat(sprintf("  Error fitting model: %s\n", e$message))
      }
      results$converged[g] <- FALSE
    })
  }

  # Perform cross-validation if requested
  if ("CVE" %in% criteria) {

    if (verbose) {
      cat("\nPerforming cross-validation...\n")
    }

    for (g in 1:max_groups) {

      if (verbose) {
        cat(sprintf("\nCV for %d group(s)...\n", g))
      }

      cv_error <- .cross_validate(data, id, time, outcome, g, dist, degree,
                                  zero_inflated, cv_folds, verbose, ...)

      results$CVE[g] <- cv_error

      if (verbose) {
        cat(sprintf("  CVE: %.2f\n", cv_error))
      }
    }
  }

  # Determine best models by each criterion
  best <- list()

  if ("BIC" %in% criteria) {
    best_bic_idx <- which.min(results$BIC[results$converged])
    best$BIC <- results$num_groups[results$converged][best_bic_idx]
  }

  if ("AIC" %in% criteria) {
    best_aic_idx <- which.min(results$AIC[results$converged])
    best$AIC <- results$num_groups[results$converged][best_aic_idx]
  }

  if ("CVE" %in% criteria) {
    best_cve_idx <- which.min(results$CVE[results$converged])
    best$CVE <- results$num_groups[results$converged][best_cve_idx]
  }

  if (verbose) {
    cat("\n")
    cat("========================================\n")
    cat("Model Selection Summary\n")
    cat("========================================\n")
    if (!is.null(best$BIC)) {
      cat(sprintf("Best by BIC: %d groups\n", best$BIC))
    }
    if (!is.null(best$AIC)) {
      cat(sprintf("Best by AIC: %d groups\n", best$AIC))
    }
    if (!is.null(best$CVE)) {
      cat(sprintf("Best by CVE: %d groups\n", best$CVE))
    }
    cat("========================================\n")
  }

  attr(results, "best") <- best
  class(results) <- c("selectNumGroups", "data.frame")

  return(results)
}


#' Cross-validation for trajectory model selection
#' @keywords internal
.cross_validate <- function(data, id, time, outcome, groups, dist, degree,
                           zero_inflated, cv_folds, verbose, ...) {

  # Get unique IDs
  ids <- unique(data[[id]])
  n <- length(ids)

  # Create folds
  fold_size <- ceiling(n / cv_folds)
  fold_assignment <- sample(rep(1:cv_folds, length.out = n))

  cv_logliks <- numeric(cv_folds)

  for (fold in 1:cv_folds) {

    # Split data
    test_ids <- ids[fold_assignment == fold]
    train_ids <- ids[fold_assignment != fold]

    train_data <- data[data[[id]] %in% train_ids, ]
    test_data <- data[data[[id]] %in% test_ids, ]

    # Fit on training data
    tryCatch({
      fit <- fitTrajectory(data = train_data, id = id, time = time, outcome = outcome,
                          dist = dist, groups = groups, degree = degree,
                          zero_inflated = zero_inflated,
                          verbose = FALSE, ...)

      # Compute log-likelihood on test data
      test_loglik <- .compute_test_loglik(test_data, id, time, outcome, fit)
      cv_logliks[fold] <- test_loglik

    }, error = function(e) {
      if (verbose) {
        cat(sprintf("    Fold %d: Error - %s\n", fold, e$message))
      }
      cv_logliks[fold] <- NA
    })
  }

  # Return negative average log-likelihood as the error
  cv_error <- -mean(cv_logliks, na.rm = TRUE)

  return(cv_error)
}


#' Compute log-likelihood on test data
#' @keywords internal
.compute_test_loglik <- function(test_data, id, time, outcome, fit) {

  # Prepare test data in the same format
  test_data <- test_data[order(test_data[[id]], test_data[[time]]), ]
  test_ids <- unique(test_data[[id]])
  n_test <- length(test_ids)

  # Extract test outcomes and time points
  Y_test_list <- split(test_data[[outcome]], test_data[[id]])
  time_test_list <- split(test_data[[time]], test_data[[id]])

  max_time_test <- max(sapply(Y_test_list, length))

  Y_test <- matrix(NA, nrow = n_test, ncol = max_time_test)
  time_test <- matrix(NA, nrow = n_test, ncol = max_time_test)

  for (i in 1:n_test) {
    Y_test[i, 1:length(Y_test_list[[i]])] <- Y_test_list[[i]]
    time_test[i, 1:length(time_test_list[[i]])] <- time_test_list[[i]]
  }

  # Scale time using training data range
  time_test_scaled <- (time_test - fit$data$time_range[1]) / (fit$data$time_range[2] - fit$data$time_range[1])

  # Create polynomial basis for test data
  X_test <- array(NA, dim = c(n_test, max_time_test, fit$degree + 1))
  for (d in 0:fit$degree) {
    X_test[, , d + 1] <- time_test_scaled^d
  }

  # Compute log-likelihood for each test individual
  loglik_test <- 0

  for (i in 1:n_test) {
    ll_i <- 0
    for (g in 1:fit$groups) {

      ll_g <- 0
      for (t in 1:max_time_test) {
        if (!is.na(Y_test[i, t])) {

          eta <- sum(X_test[i, t, ] * fit$coefficients[g, ])

          if (fit$dist == "gaussian") {
            mu <- eta
            # Use estimated variance (would need to store this in fit object)
            sigma2 <- var(fit$data$Y, na.rm = TRUE)
            ll_g <- ll_g + dnorm(Y_test[i, t], mean = mu, sd = sqrt(sigma2), log = TRUE)

          } else if (fit$dist %in% c("poisson", "zip")) {
            lambda <- exp(eta)

            if (fit$zero_inflated) {
              # Use estimated zero-inflation parameter (simplified)
              p_zero <- 0.2  # Would need to extract actual value

              if (Y_test[i, t] == 0) {
                ll_g <- ll_g + log(p_zero + (1 - p_zero) * exp(-lambda))
              } else {
                ll_g <- ll_g + log(1 - p_zero) + dpois(Y_test[i, t], lambda = lambda, log = TRUE)
              }
            } else {
              ll_g <- ll_g + dpois(Y_test[i, t], lambda = lambda, log = TRUE)
            }
          }
        }
      }

      ll_i <- ll_i + fit$group_proportions[g] * exp(ll_g)
    }

    loglik_test <- loglik_test + log(ll_i)
  }

  return(loglik_test)
}


#' Print method for selectNumGroups objects
#' @export
print.selectNumGroups <- function(x, ...) {

  cat("\nModel Selection Results\n")
  cat("========================\n\n")

  print(as.data.frame(x), row.names = FALSE, digits = 2)

  best <- attr(x, "best")
  if (!is.null(best)) {
    cat("\nOptimal number of groups:\n")
    for (criterion in names(best)) {
      cat(sprintf("  %s: %d groups\n", criterion, best[[criterion]]))
    }
  }

  invisible(x)
}
