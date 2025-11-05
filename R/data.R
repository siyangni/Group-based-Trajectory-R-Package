#' Simulated Longitudinal Crime Data
#'
#' A simulated dataset containing longitudinal offense counts for 250 individuals
#' across 10 time points (ages 10-19). The data were generated from a group-based
#' trajectory model with three distinct developmental trajectories of offending.
#'
#' @format A data frame with 2500 rows and 5 variables:
#' \describe{
#'   \item{id}{Individual identifier (1-250)}
#'   \item{age}{Age at observation (10-19 years)}
#'   \item{offense_count}{Number of offenses committed (count variable)}
#'   \item{male}{Gender indicator (1 = male, 0 = female)}
#'   \item{risk_score}{Baseline risk score (standardized, higher = more risk)}
#' }
#'
#' @details
#' The data were generated to reflect three common developmental trajectories
#' identified in criminological research:
#' \itemize{
#'   \item Group 1 (60%): Low-rate chronic - individuals with consistently low
#'     offending rates across development
#'   \item Group 2 (30%): Adolescence-peaked - individuals whose offending rises
#'     during adolescence and declines in late teens
#'   \item Group 3 (10%): High-rate chronic - individuals with persistently high
#'     offending rates
#' }
#'
#' The offense counts were generated from a zero-inflated Poisson distribution
#' with group-specific polynomial trajectories. Missing data (approximately 5%
#' of observations) were introduced to reflect realistic attrition in longitudinal
#' studies.
#'
#' @source Simulated data based on parameters from empirical criminological
#'   research (Nagin & Land, 1993; Moffitt, 1993).
#'
#' @references
#' Nagin, D. S., & Land, K. C. (1993). Age, criminal careers, and population
#' heterogeneity: Specification and estimation of a nonparametric, mixed Poisson
#' model. Criminology, 31(3), 327-362.
#'
#' Moffitt, T. E. (1993). Adolescence-limited and life-course-persistent
#' antisocial behavior: A developmental taxonomy. Psychological Review, 100(4), 674-701.
#'
#' @examples
#' data(crime_data)
#' head(crime_data)
#'
#' # Visualize raw trajectories for a few individuals
#' ids_to_plot <- sample(unique(crime_data$id), 10)
#' plot(0, 0, type = "n", xlim = c(10, 19), ylim = c(0, 10),
#'      xlab = "Age", ylab = "Offense Count")
#' for (i in ids_to_plot) {
#'   ind_data <- subset(crime_data, id == i)
#'   lines(ind_data$age, ind_data$offense_count, col = "gray")
#' }
#'
"crime_data"


#' Generate Simulated Crime Trajectory Data
#'
#' Internal function to generate the simulated crime dataset. This function is
#' included for reproducibility and to allow users to generate similar datasets
#' with different parameters.
#'
#' @param n Number of individuals. Default is 250.
#' @param time_points Number of time points. Default is 10.
#' @param seed Random seed for reproducibility. Default is 12345.
#'
#' @return A data frame with the same structure as \code{crime_data}.
#'
#' @keywords internal
#' @importFrom stats rbinom rnorm rpois
.generate_crime_data <- function(n = 250, time_points = 10, seed = 12345) {

  set.seed(seed)

  # Time points (ages 10-19)
  ages <- 10:19

  # Define three trajectory groups based on criminological theory
  # Group 1: Low-rate chronic (60%)
  # Group 2: Adolescence-peaked (30%)
  # Group 3: High-rate chronic (10%)

  group_props <- c(0.60, 0.30, 0.10)
  true_groups <- sample(1:3, size = n, replace = TRUE, prob = group_props)

  # Generate covariates
  male <- rbinom(n, 1, 0.7)  # 70% male (typical in crime samples)
  risk_score <- rnorm(n, mean = 0, sd = 1)

  # Trajectory parameters (polynomial coefficients)
  # Time scaled to [0, 1]
  time_scaled <- (ages - min(ages)) / (max(ages) - min(ages))

  # Group 1: Low and stable (slight quadratic decline)
  beta1 <- c(0.5, 0.2, -0.3, 0)  # Intercept, linear, quadratic, cubic

  # Group 2: Adolescence-peaked (inverted U-shape)
  beta2 <- c(0.8, 3.5, -3.0, 0)  # Peaks around age 15

  # Group 3: High-rate chronic (high and stable)
  beta3 <- c(2.0, 0.3, -0.1, 0)  # High intercept, slight decline

  beta_matrix <- rbind(beta1, beta2, beta3)

  # Zero-inflation probabilities by group
  p_zero <- c(0.15, 0.10, 0.05)  # Low group has more structural zeros

  # Generate data
  data_list <- list()

  for (i in 1:n) {
    g <- true_groups[i]

    for (t in 1:time_points) {
      # Compute expected count
      t_scaled <- time_scaled[t]
      X_it <- c(1, t_scaled, t_scaled^2, t_scaled^3)

      eta <- sum(beta_matrix[g, ] * X_it)
      lambda <- exp(eta)

      # Zero-inflated Poisson
      is_structural_zero <- rbinom(1, 1, p_zero[g])

      if (is_structural_zero == 1) {
        y <- 0
      } else {
        y <- rpois(1, lambda)
      }

      data_list[[length(data_list) + 1]] <- data.frame(
        id = i,
        age = ages[t],
        offense_count = y,
        male = male[i],
        risk_score = risk_score[i],
        true_group = g
      )
    }
  }

  # Combine data
  data <- do.call(rbind, data_list)

  # Introduce missing data (5% MCAR)
  n_obs <- nrow(data)
  missing_indices <- sample(1:n_obs, size = floor(0.05 * n_obs))
  data$offense_count[missing_indices] <- NA

  # Remove true_group for the actual dataset (but keep for testing)
  # For crime_data, we'll remove it; for internal testing, we keep it
  return(data)
}
