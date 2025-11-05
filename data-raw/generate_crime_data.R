# Script to generate the crime_data dataset
# This script should be run once to create the dataset

library(stats)

# Set seed for reproducibility
set.seed(12345)

n <- 250
time_points <- 10
ages <- 10:19

# Define three trajectory groups
group_props <- c(0.60, 0.30, 0.10)
true_groups <- sample(1:3, size = n, replace = TRUE, prob = group_props)

# Generate covariates
male <- rbinom(n, 1, 0.7)
risk_score <- rnorm(n, mean = 0, sd = 1)

# Trajectory parameters
time_scaled <- (ages - min(ages)) / (max(ages) - min(ages))

# Group 1: Low and stable
beta1 <- c(0.5, 0.2, -0.3, 0)

# Group 2: Adolescence-peaked
beta2 <- c(0.8, 3.5, -3.0, 0)

# Group 3: High-rate chronic
beta3 <- c(2.0, 0.3, -0.1, 0)

beta_matrix <- rbind(beta1, beta2, beta3)

# Zero-inflation probabilities
p_zero <- c(0.15, 0.10, 0.05)

# Generate data
data_list <- list()

for (i in 1:n) {
  g <- true_groups[i]

  for (t in 1:time_points) {
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
      risk_score = risk_score[i]
    )
  }
}

# Combine data
crime_data <- do.call(rbind, data_list)
rownames(crime_data) <- NULL

# Introduce missing data (5% MCAR)
n_obs <- nrow(crime_data)
missing_indices <- sample(1:n_obs, size = floor(0.05 * n_obs))
crime_data$offense_count[missing_indices] <- NA

# Save dataset
save(crime_data, file = "data/crime_data.rda", compress = "bzip2")

cat("Dataset generated successfully!\n")
cat(sprintf("Total observations: %d\n", nrow(crime_data)))
cat(sprintf("Number of individuals: %d\n", length(unique(crime_data$id))))
cat(sprintf("Missing values: %d (%.1f%%)\n",
            sum(is.na(crime_data$offense_count)),
            100 * mean(is.na(crime_data$offense_count))))
