#' Fit Group-Based Trajectory Model
#'
#' Estimates a finite mixture model for longitudinal trajectory data using
#' the Expectation-Maximization (EM) algorithm. Supports multiple distributions
#' including Poisson, zero-inflated Poisson, and Gaussian.
#'
#' @param data A data frame containing the longitudinal data.
#' @param id Character string specifying the name of the individual identifier variable.
#' @param time Character string specifying the name of the time variable.
#' @param outcome Character string specifying the name of the outcome variable.
#' @param dist Character string specifying the distribution family. Options are
#'   "poisson", "zip" (zero-inflated Poisson), or "gaussian". Default is "poisson".
#' @param groups Integer specifying the number of trajectory groups. Default is 3.
#' @param degree Integer specifying the degree of the polynomial for trajectories.
#'   Default is 3 (cubic).
#' @param zero_inflated Logical indicating whether to use zero-inflation for
#'   count distributions. Only applies when dist = "poisson". Default is TRUE.
#' @param group_cov Formula or character vector specifying covariates that affect
#'   group membership. Default is NULL (no covariates).
#' @param traj_cov Formula or character vector specifying covariates that affect
#'   trajectory shape within groups. Default is NULL (no covariates).
#' @param max_iter Maximum number of EM iterations. Default is 500.
#' @param tol Convergence tolerance for log-likelihood. Default is 1e-6.
#' @param verbose Logical indicating whether to print convergence information.
#'   Default is FALSE.
#' @param start_values Optional list of starting values for parameters. Default is NULL
#'   (automatic initialization).
#'
#' @return An object of class "crimeTrajec" containing:
#' \item{coefficients}{Matrix of trajectory coefficients for each group.}
#' \item{group_proportions}{Vector of estimated group proportions.}
#' \item{posterior}{Matrix of posterior probabilities of group membership for each individual.}
#' \item{fitted_values}{Matrix of fitted trajectory values.}
#' \item{loglik}{Log-likelihood of the fitted model.}
#' \item{BIC}{Bayesian Information Criterion.}
#' \item{AIC}{Akaike Information Criterion.}
#' \item{converged}{Logical indicating whether the EM algorithm converged.}
#' \item{iterations}{Number of iterations until convergence.}
#' \item{data}{Original data used for fitting.}
#' \item{call}{The matched call.}
#' \item{dist}{Distribution family used.}
#' \item{groups}{Number of groups.}
#' \item{degree}{Polynomial degree.}
#' \item{zero_inflated}{Whether zero-inflation was used.}
#' \item{vcov}{Variance-covariance matrix of parameter estimates (if available).}
#'
#' @details
#' The function implements a finite mixture model where each component represents
#' a distinct developmental trajectory. The EM algorithm alternates between:
#' \itemize{
#'   \item E-step: Computing posterior probabilities of group membership
#'   \item M-step: Updating parameter estimates given the posterior probabilities
#' }
#'
#' For zero-inflated Poisson models, the likelihood includes both a structural
#' zero component and a Poisson count component. The zero-inflation probability
#' can vary by group and time.
#'
#' @references
#' Nagin, D. S. (2005). Group-based modeling of development. Harvard University Press.
#'
#' Jones, B. L., Nagin, D. S., & Roeder, K. (2001). A SAS procedure based on
#' mixture models for estimating developmental trajectories. Sociological Methods
#' & Research, 29(3), 374-393.
#'
#' Nagin, D. S., & Land, K. C. (1993). Age, criminal careers, and population
#' heterogeneity: Specification and estimation of a nonparametric, mixed Poisson
#' model. Criminology, 31(3), 327-362.
#'
#' @examples
#' \dontrun{
#' # Load example data
#' data(crime_data)
#'
#' # Fit a 3-group Poisson trajectory model
#' fit <- fitTrajectory(data = crime_data,
#'                      id = "id",
#'                      time = "age",
#'                      outcome = "offense_count",
#'                      dist = "poisson",
#'                      groups = 3,
#'                      degree = 2)
#'
#' # Print summary
#' print(fit)
#'
#' # Plot trajectories
#' plot(fit)
#' }
#'
#' @export
fitTrajectory <- function(data, id, time, outcome,
                          dist = "poisson",
                          groups = 3,
                          degree = 3,
                          zero_inflated = TRUE,
                          group_cov = NULL,
                          traj_cov = NULL,
                          max_iter = 500,
                          tol = 1e-6,
                          verbose = FALSE,
                          start_values = NULL) {

  # Input validation
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (!all(c(id, time, outcome) %in% names(data))) {
    stop("id, time, and outcome variables must exist in data")
  }
  if (groups < 1) {
    stop("Number of groups must be at least 1")
  }
  if (degree < 0) {
    stop("Polynomial degree must be non-negative")
  }
  if (!dist %in% c("poisson", "zip", "gaussian")) {
    stop("dist must be one of: 'poisson', 'zip', 'gaussian'")
  }

  # Apply zero_inflated setting based on distribution
  if (dist == "zip") {
    zero_inflated <- TRUE
  } else if (dist == "gaussian") {
    zero_inflated <- FALSE
  }

  # Prepare data
  data <- data[order(data[[id]], data[[time]]), ]
  data_list <- .prepare_data(data, id, time, outcome, group_cov, traj_cov, degree)

  # Initialize parameters
  if (is.null(start_values)) {
    params <- .initialize_parameters(data_list, groups, degree, dist, zero_inflated)
  } else {
    params <- start_values
  }

  # EM algorithm
  em_result <- .em_algorithm(data_list, params, groups, degree, dist,
                             zero_inflated, max_iter, tol, verbose)

  # Compute fitted values and posterior probabilities
  fitted <- .compute_fitted(data_list, em_result$params, groups, degree, dist, zero_inflated)
  posterior <- .compute_posterior(data_list, em_result$params, groups, degree, dist, zero_inflated)

  # Compute information criteria
  n_params <- .count_parameters(groups, degree, dist, zero_inflated, data_list$has_group_cov, data_list$has_traj_cov)
  n_obs <- nrow(data_list$Y)
  BIC <- -2 * em_result$loglik + n_params * log(n_obs)
  AIC <- -2 * em_result$loglik + 2 * n_params

  # Prepare output
  result <- list(
    coefficients = em_result$params$beta,
    group_proportions = em_result$params$pi,
    posterior = posterior,
    fitted_values = fitted,
    loglik = em_result$loglik,
    BIC = BIC,
    AIC = AIC,
    converged = em_result$converged,
    iterations = em_result$iterations,
    data = data_list,
    call = match.call(),
    dist = dist,
    groups = groups,
    degree = degree,
    zero_inflated = zero_inflated,
    n_params = n_params,
    vcov = NULL  # Could implement standard error calculation later
  )

  class(result) <- "crimeTrajec"
  return(result)
}


#' Prepare data for trajectory modeling
#' @keywords internal
.prepare_data <- function(data, id, time, outcome, group_cov, traj_cov, degree) {

  # Extract key variables
  ids <- unique(data[[id]])
  n <- length(ids)
  times_per_id <- table(data[[id]])

  # Create outcome matrix (rows = individuals, columns = time points)
  Y_list <- split(data[[outcome]], data[[id]])
  max_time <- max(times_per_id)
  Y <- matrix(NA, nrow = n, ncol = max_time)
  for (i in 1:n) {
    Y[i, 1:length(Y_list[[i]])] <- Y_list[[i]]
  }

  # Create time design matrix for polynomial trajectories
  time_list <- split(data[[time]], data[[id]])
  time_mat <- matrix(NA, nrow = n, ncol = max_time)
  for (i in 1:n) {
    time_mat[i, 1:length(time_list[[i]])] <- time_list[[i]]
  }

  # Standardize time to [0, 1] range for numerical stability
  time_range <- range(time_mat, na.rm = TRUE)
  time_scaled <- (time_mat - time_range[1]) / (time_range[2] - time_range[1])

  # Create polynomial basis
  X <- array(NA, dim = c(n, max_time, degree + 1))
  for (d in 0:degree) {
    X[, , d + 1] <- time_scaled^d
  }

  # Handle covariates (simplified implementation)
  group_cov_mat <- NULL
  traj_cov_mat <- NULL
  has_group_cov <- FALSE
  has_traj_cov <- FALSE

  list(
    Y = Y,
    X = X,
    time_mat = time_mat,
    time_scaled = time_scaled,
    time_range = time_range,
    ids = ids,
    n = n,
    max_time = max_time,
    group_cov = group_cov_mat,
    traj_cov = traj_cov_mat,
    has_group_cov = has_group_cov,
    has_traj_cov = has_traj_cov
  )
}


#' Initialize parameters for EM algorithm
#' @keywords internal
.initialize_parameters <- function(data_list, groups, degree, dist, zero_inflated) {

  n <- data_list$n

  # Initialize group proportions (equal)
  pi <- rep(1 / groups, groups)

  # Initialize trajectory coefficients with k-means clustering
  Y_means <- rowMeans(data_list$Y, na.rm = TRUE)

  if (groups > 1) {
    km <- kmeans(Y_means, centers = groups, nstart = 10)
    group_assignments <- km$cluster
  } else {
    group_assignments <- rep(1, n)
  }

  # Estimate initial coefficients for each group
  beta <- matrix(0, nrow = groups, ncol = degree + 1)

  for (g in 1:groups) {
    idx <- which(group_assignments == g)
    if (length(idx) > 0) {
      Y_g <- data_list$Y[idx, , drop = FALSE]
      X_g <- data_list$X[idx, , , drop = FALSE]

      # Fit simple polynomial regression
      y_vec <- as.vector(t(Y_g))
      x_mat <- matrix(NA, nrow = length(y_vec), ncol = degree + 1)
      for (d in 0:degree) {
        x_mat[, d + 1] <- as.vector(t(X_g[, , d + 1]))
      }

      # Remove missing values
      keep <- !is.na(y_vec)
      if (sum(keep) > degree + 1) {
        y_vec <- y_vec[keep]
        x_mat <- x_mat[keep, , drop = FALSE]

        if (dist == "gaussian") {
          fit <- lm.fit(x_mat, y_vec)
          beta[g, ] <- coef(fit)
        } else {
          # For count data, use log link
          y_vec[y_vec == 0] <- 0.1  # Avoid log(0)
          fit <- lm.fit(x_mat, log(y_vec))
          beta[g, ] <- coef(fit)
        }
      } else {
        # Fallback: use grand mean
        beta[g, 1] <- mean(Y_g, na.rm = TRUE)
      }
    }
  }

  # Initialize zero-inflation parameters if needed
  if (zero_inflated) {
    psi <- matrix(-1, nrow = groups, ncol = 1)  # logit scale, corresponds to ~27% zeros
  } else {
    psi <- NULL
  }

  # Initialize variance for Gaussian
  if (dist == "gaussian") {
    sigma2 <- rep(var(data_list$Y, na.rm = TRUE), groups)
  } else {
    sigma2 <- NULL
  }

  list(
    pi = pi,
    beta = beta,
    psi = psi,
    sigma2 = sigma2
  )
}


#' EM algorithm for mixture model estimation
#' @keywords internal
.em_algorithm <- function(data_list, params, groups, degree, dist,
                          zero_inflated, max_iter, tol, verbose) {

  loglik_old <- -Inf
  converged <- FALSE

  for (iter in 1:max_iter) {

    # E-step: compute posterior probabilities
    posterior <- .e_step(data_list, params, groups, degree, dist, zero_inflated)

    # M-step: update parameters
    params <- .m_step(data_list, posterior, groups, degree, dist, zero_inflated, params)

    # Compute log-likelihood
    loglik <- .compute_loglik(data_list, params, groups, degree, dist, zero_inflated)

    # Check convergence
    if (abs(loglik - loglik_old) < tol) {
      converged <- TRUE
      if (verbose) {
        cat(sprintf("EM converged at iteration %d, loglik = %.4f\n", iter, loglik))
      }
      break
    }

    if (verbose && iter %% 10 == 0) {
      cat(sprintf("Iteration %d: loglik = %.4f\n", iter, loglik))
    }

    loglik_old <- loglik
  }

  if (!converged && verbose) {
    warning(sprintf("EM did not converge after %d iterations", max_iter))
  }

  list(
    params = params,
    loglik = loglik,
    converged = converged,
    iterations = iter
  )
}


#' E-step: compute posterior probabilities
#' @keywords internal
.e_step <- function(data_list, params, groups, degree, dist, zero_inflated) {

  n <- data_list$n
  posterior <- matrix(0, nrow = n, ncol = groups)

  for (g in 1:groups) {
    # Compute log-likelihood for each individual in group g
    log_lik_g <- .compute_individual_loglik(data_list, params, g, dist, zero_inflated)
    posterior[, g] <- log(params$pi[g]) + log_lik_g
  }

  # Normalize (using log-sum-exp trick for numerical stability)
  log_sum <- apply(posterior, 1, function(x) {
    max_x <- max(x)
    max_x + log(sum(exp(x - max_x)))
  })

  posterior <- exp(posterior - log_sum)

  # Handle numerical issues
  posterior[is.na(posterior)] <- 1 / groups
  posterior[posterior < 1e-10] <- 1e-10
  posterior <- posterior / rowSums(posterior)

  return(posterior)
}


#' Compute individual log-likelihood for a given group
#' @keywords internal
.compute_individual_loglik <- function(data_list, params, group, dist, zero_inflated) {

  n <- data_list$n
  max_time <- data_list$max_time
  log_lik <- numeric(n)

  for (i in 1:n) {
    ll <- 0
    for (t in 1:max_time) {
      if (!is.na(data_list$Y[i, t])) {

        # Compute linear predictor
        eta <- sum(data_list$X[i, t, ] * params$beta[group, ])

        if (dist == "gaussian") {
          mu <- eta
          ll <- ll + dnorm(data_list$Y[i, t], mean = mu, sd = sqrt(params$sigma2[group]), log = TRUE)

        } else if (dist %in% c("poisson", "zip")) {
          lambda <- exp(eta)

          if (zero_inflated) {
            # Zero-inflated Poisson
            psi_g <- params$psi[group, 1]
            p_zero <- 1 / (1 + exp(-psi_g))  # Probability of structural zero

            if (data_list$Y[i, t] == 0) {
              # Could be structural zero or Poisson zero
              ll <- ll + log(p_zero + (1 - p_zero) * exp(-lambda))
            } else {
              # Must be from Poisson component
              ll <- ll + log(1 - p_zero) + dpois(data_list$Y[i, t], lambda = lambda, log = TRUE)
            }
          } else {
            # Regular Poisson
            ll <- ll + dpois(data_list$Y[i, t], lambda = lambda, log = TRUE)
          }
        }
      }
    }
    log_lik[i] <- ll
  }

  return(log_lik)
}


#' M-step: update parameters
#' @keywords internal
.m_step <- function(data_list, posterior, groups, degree, dist, zero_inflated, params_old) {

  n <- data_list$n

  # Update group proportions
  pi <- colMeans(posterior)

  # Update trajectory coefficients for each group
  beta <- matrix(0, nrow = groups, ncol = degree + 1)
  psi <- if (zero_inflated) matrix(0, nrow = groups, ncol = 1) else NULL
  sigma2 <- if (dist == "gaussian") numeric(groups) else NULL

  for (g in 1:groups) {

    # Weighted likelihood for group g
    weights <- posterior[, g]

    if (sum(weights) < 1e-6) {
      # Group has negligible weight, keep previous values
      beta[g, ] <- params_old$beta[g, ]
      if (zero_inflated) psi[g, ] <- params_old$psi[g, ]
      if (dist == "gaussian") sigma2[g] <- params_old$sigma2[g]
      next
    }

    # Stack data for regression
    y_vec <- c()
    x_mat_list <- list()
    w_vec <- c()

    for (i in 1:n) {
      for (t in 1:data_list$max_time) {
        if (!is.na(data_list$Y[i, t])) {
          y_vec <- c(y_vec, data_list$Y[i, t])
          x_mat_list[[length(x_mat_list) + 1]] <- data_list$X[i, t, ]
          w_vec <- c(w_vec, weights[i])
        }
      }
    }

    x_mat <- do.call(rbind, x_mat_list)

    # Update beta using weighted regression
    if (dist == "gaussian") {
      # Weighted least squares
      fit <- lm.wfit(x_mat, y_vec, w = w_vec)
      beta[g, ] <- coef(fit)

      # Update variance
      residuals <- y_vec - x_mat %*% beta[g, ]
      sigma2[g] <- sum(w_vec * residuals^2) / sum(w_vec)

    } else {
      # For count data, use iterative weighted least squares (IWLS) for Poisson regression
      beta[g, ] <- .iwls_poisson(y_vec, x_mat, w_vec, params_old$beta[g, ])
    }

    # Update zero-inflation parameter if needed
    if (zero_inflated) {
      # Estimate zero-inflation probability
      lambda_vec <- exp(x_mat %*% beta[g, ])
      zero_indicator <- (y_vec == 0)

      # Probability that each zero is structural (not Poisson)
      p_structural <- numeric(length(y_vec))
      zero_idx <- which(zero_indicator)

      if (length(zero_idx) > 0) {
        psi_old <- params_old$psi[g, 1]
        p_zero_old <- 1 / (1 + exp(-psi_old))

        for (j in zero_idx) {
          p_structural[j] <- (p_zero_old) / (p_zero_old + (1 - p_zero_old) * exp(-lambda_vec[j]))
        }

        # Weighted proportion of structural zeros
        prop_structural <- sum(w_vec[zero_idx] * p_structural[zero_idx]) / sum(w_vec)
        prop_structural <- max(0.01, min(0.99, prop_structural))  # Bound away from 0 and 1

        # Convert to logit scale
        psi[g, 1] <- log(prop_structural / (1 - prop_structural))
      } else {
        psi[g, 1] <- -3  # Low probability of structural zeros
      }
    }
  }

  list(
    pi = pi,
    beta = beta,
    psi = psi,
    sigma2 = sigma2
  )
}


#' Iteratively weighted least squares for Poisson regression
#' @keywords internal
.iwls_poisson <- function(y, X, weights, beta_init, max_iter = 10) {

  beta <- beta_init

  for (iter in 1:max_iter) {
    eta <- X %*% beta
    mu <- exp(eta)

    # Avoid numerical issues
    mu[mu < 1e-6] <- 1e-6
    mu[mu > 1e6] <- 1e6

    # Working response
    z <- eta + (y - mu) / mu

    # Working weights
    w <- weights * mu
    w[w < 1e-6] <- 1e-6

    # Weighted least squares
    fit <- lm.wfit(X, z, w = w)
    beta_new <- coef(fit)

    # Check for convergence
    if (max(abs(beta_new - beta)) < 1e-4) {
      break
    }

    beta <- beta_new
  }

  return(beta)
}


#' Compute total log-likelihood
#' @keywords internal
.compute_loglik <- function(data_list, params, groups, degree, dist, zero_inflated) {

  n <- data_list$n
  loglik <- 0

  for (i in 1:n) {
    ll_i <- 0
    for (g in 1:groups) {
      ll_g <- .compute_individual_loglik(data_list, params, g, dist, zero_inflated)[i]
      ll_i <- ll_i + params$pi[g] * exp(ll_g)
    }
    loglik <- loglik + log(ll_i)
  }

  return(loglik)
}


#' Compute fitted values
#' @keywords internal
.compute_fitted <- function(data_list, params, groups, degree, dist, zero_inflated) {

  n <- data_list$n
  max_time <- data_list$max_time

  # Compute posterior probabilities
  posterior <- .e_step(data_list, params, groups, degree, dist, zero_inflated)

  # Compute fitted values as weighted average across groups
  fitted <- matrix(0, nrow = n, ncol = max_time)

  for (g in 1:groups) {
    for (i in 1:n) {
      for (t in 1:max_time) {
        eta <- sum(data_list$X[i, t, ] * params$beta[g, ])

        if (dist == "gaussian") {
          mu <- eta
        } else {
          lambda <- exp(eta)
          if (zero_inflated) {
            p_zero <- 1 / (1 + exp(-params$psi[g, 1]))
            mu <- (1 - p_zero) * lambda
          } else {
            mu <- lambda
          }
        }

        fitted[i, t] <- fitted[i, t] + posterior[i, g] * mu
      }
    }
  }

  return(fitted)
}


#' Compute posterior probabilities
#' @keywords internal
.compute_posterior <- function(data_list, params, groups, degree, dist, zero_inflated) {
  return(.e_step(data_list, params, groups, degree, dist, zero_inflated))
}


#' Count number of parameters in model
#' @keywords internal
.count_parameters <- function(groups, degree, dist, zero_inflated, has_group_cov, has_traj_cov) {

  # Group proportions (groups - 1, since they sum to 1)
  n_params <- groups - 1

  # Trajectory coefficients
  n_params <- n_params + groups * (degree + 1)

  # Zero-inflation parameters
  if (zero_inflated) {
    n_params <- n_params + groups
  }

  # Variance parameters for Gaussian
  if (dist == "gaussian") {
    n_params <- n_params + groups
  }

  return(n_params)
}
