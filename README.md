# crimeTrajec: Group-Based Trajectory Modeling for Criminology

[![CRAN status](https://www.r-pkg.org/badges/version/crimeTrajec)](https://CRAN.R-project.org/package=crimeTrajec)
[![License: GPL-3](https://img.shields.io/badge/License-GPL%203-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Overview

**crimeTrajec** is an R package for group-based trajectory modeling (GBTM) of longitudinal data, with a focus on criminological applications. The package implements finite mixture models to identify distinct developmental trajectories in longitudinal data, providing an open-source alternative to proprietary software like SAS PROC TRAJ.

### Key Features

- **Multiple Distributions**: Poisson, zero-inflated Poisson, and Gaussian models
- **Flexible Trajectories**: Polynomial specifications up to cubic degree
- **Model Selection**: BIC, AIC, and cross-validation for determining optimal number of groups
- **User-Friendly**: Standard R workflow with formula interface and S3 methods
- **Well-Documented**: Comprehensive vignettes, examples, and academic paper
- **Open Source**: Free, transparent, and extensible (GPL-3 license)

## Installation

Install from CRAN:

```r
install.packages("crimeTrajec")
```

Or install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("yourusername/crimeTrajec")
```

## Quick Start

```r
library(crimeTrajec)

# Load example data
data(crime_data)

# Fit a 3-group trajectory model
fit <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  dist = "zip",
  groups = 3,
  degree = 2
)

# View results
print(fit)

# Plot trajectories
plot(fit, include_ci = TRUE)

# Get group assignments
groups <- predict(fit, type = "class")
```

## What is Group-Based Trajectory Modeling?

Group-based trajectory modeling (GBTM) is a statistical method for identifying distinct developmental patterns in longitudinal data. Rather than assuming all individuals follow a single average trajectory, GBTM identifies subgroups with qualitatively different patterns over time.

### Applications in Criminology

GBTM has been widely used in criminology to study:

- **Developmental trajectories of offending** across the life course
- **Age-crime curves** for different offender types
- **Desistance patterns** from criminal behavior
- **Co-occurrence** of crime, substance use, and other behaviors

Common trajectory patterns identified in criminological research include:

- **Low-rate chronic**: Consistently low levels of offending
- **Adolescence-peaked**: Offending concentrated in teenage years
- **High-rate chronic**: Persistent high-level offending across ages

## Example: Analyzing Criminal Trajectories

### Step 1: Explore the Data

```r
# Load data
data(crime_data)
head(crime_data)

# Plot raw trajectories for sample of individuals
sample_ids <- sample(unique(crime_data$id), 20)
plot(0, 0, type = "n", xlim = c(10, 19), ylim = c(0, 15),
     xlab = "Age", ylab = "Offense Count")
for (id in sample_ids) {
  ind_data <- subset(crime_data, id == id)
  lines(ind_data$age, ind_data$offense_count, col = "gray70")
}
```

### Step 2: Select Number of Groups

```r
# Compare models with 1-5 groups using BIC
comparison <- selectNumGroups(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  max_groups = 5,
  criteria = c("BIC", "AIC"),
  dist = "zip",
  degree = 2,
  verbose = TRUE
)

print(comparison)

# Plot BIC values
plot(comparison$num_groups, comparison$BIC, type = "b",
     xlab = "Number of Groups", ylab = "BIC")
```

### Step 3: Fit Selected Model

```r
# Fit 3-group model (assuming BIC selects 3 groups)
fit3 <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  dist = "zip",
  groups = 3,
  degree = 2,
  zero_inflated = TRUE
)

print(fit3)
```

### Step 4: Interpret Results

```r
# Visualize trajectories
plot(fit3, include_ci = TRUE, observed = FALSE,
     main = "Three Developmental Trajectories of Offending")

# Extract group membership
posterior <- predict(fit3, type = "group")
groups <- predict(fit3, type = "class")

# Summarize group assignments
table(groups)

# Examine characteristics by group
aggregate(male ~ groups,
          data = crime_data[!duplicated(crime_data$id), ],
          FUN = mean)
```

## Distribution Options

### Poisson

For count data without excess zeros:

```r
fit_poisson <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  dist = "poisson",
  groups = 3,
  degree = 2
)
```

### Zero-Inflated Poisson

For count data with excess zeros (recommended for sparse offense counts):

```r
fit_zip <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  dist = "zip",
  groups = 3,
  degree = 2,
  zero_inflated = TRUE
)
```

### Gaussian

For continuous outcomes:

```r
fit_gaussian <- fitTrajectory(
  data = your_data,
  id = "id",
  time = "time",
  outcome = "continuous_outcome",
  dist = "gaussian",
  groups = 3,
  degree = 2
)
```

## Model Selection

### Information Criteria

The Bayesian Information Criterion (BIC) is recommended for mixture models:

```r
# Compare multiple models
comparison <- selectNumGroups(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  max_groups = 6,
  criteria = c("BIC", "AIC")
)

# Best model by BIC
best_k <- attr(comparison, "best")$BIC
```

### Cross-Validation

For more robust model selection:

```r
# 5-fold cross-validation (computationally intensive)
comparison_cv <- selectNumGroups(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  max_groups = 4,
  criteria = c("BIC", "CVE"),
  cv_folds = 5
)
```

## Package Functions

### Main Functions

- **`fitTrajectory()`**: Fit group-based trajectory model
- **`selectNumGroups()`**: Compare models with different numbers of groups
- **`print.crimeTrajec()`**: Print model summary
- **`plot.crimeTrajec()`**: Visualize estimated trajectories
- **`predict.crimeTrajec()`**: Extract predictions and group assignments

### Example Data

- **`crime_data`**: Simulated longitudinal offense data (250 individuals, 10 time points)

## Documentation

Comprehensive documentation is available:

- **Vignette**: `vignette("crimeTrajec-vignette")` - Tutorial and technical details
- **Help pages**: `?fitTrajectory`, `?selectNumGroups`, etc.
- **Academic paper**: See `paper-draft.md` in the repository

## Statistical Background

The package implements finite mixture models for longitudinal data. For individual i at time t, the probability distribution is:

P(Y_it | Group k) = f(Y_it; θ_kit)

where trajectories are modeled using polynomials:

- Degree 0: Flat (intercept only)
- Degree 1: Linear
- Degree 2: Quadratic (one curve)
- Degree 3: Cubic (two curves)

Parameters are estimated using the Expectation-Maximization (EM) algorithm.

For detailed methodology, see:
- Nagin, D. S. (2005). Group-based modeling of development. Harvard University Press.
- Jones et al. (2001). A SAS procedure based on mixture models for estimating developmental trajectories. Sociological Methods & Research, 29(3), 374-393.

## Comparison with Other Software

| Feature                    | crimeTrajec | PROC TRAJ | traj (Stata) |
|----------------------------|-------------|-----------|--------------|
| Open Source                | Yes         | No        | No           |
| Cost                       | Free        | SAS license | Stata license |
| Zero-Inflated Poisson      | Yes         | Yes       | Limited      |
| Cross-Validation           | Yes         | No        | No           |
| R Integration              | Native      | No        | No           |
| Customizable               | Yes         | Limited   | Limited      |

## Requirements

- R >= 3.5.0
- Dependencies: stats, graphics, MASS (all in base R)

## Getting Help

- **Bug reports**: Open an issue on [GitHub](https://github.com/yourusername/crimeTrajec/issues)
- **Questions**: See package vignette or documentation
- **Feature requests**: Open an issue with the "enhancement" label

## Contributing

Contributions are welcome! Please see CONTRIBUTING.md for guidelines.

Areas for contribution:
- Additional distribution families
- Covariate integration
- Multilevel trajectories
- Performance optimization
- Documentation improvements

## Citation

If you use crimeTrajec in published research, please cite:

```
[Author Name] (2024). crimeTrajec: Group-Based Trajectory Modeling for
  Criminology. R package version 0.1.0.
  https://github.com/yourusername/crimeTrajec
```

And the methodology paper:

```
[Author Name] (2024). crimeTrajec: An Open-Source R Package for Group-Based
  Trajectory Modeling in Criminology. [Journal Name], [Volume]([Issue]), [Pages].
```

## License

GPL-3 - see LICENSE file for details.

## Acknowledgments

This package builds on foundational work by:
- Daniel Nagin and colleagues on group-based trajectory modeling
- Bobby Jones on the original PROC TRAJ implementation
- The R Core Team and CRAN maintainers

Development was supported by [Funding Source].

## References

D'Unger, A. V., Land, K. C., McCall, P. L., & Nagin, D. S. (1998). How many latent classes of delinquent/criminal careers? American Journal of Sociology, 103(6), 1593-1630.

Jones, B. L., Nagin, D. S., & Roeder, K. (2001). A SAS procedure based on mixture models for estimating developmental trajectories. Sociological Methods & Research, 29(3), 374-393.

Moffitt, T. E. (1993). Adolescence-limited and life-course-persistent antisocial behavior: A developmental taxonomy. Psychological Review, 100(4), 674-701.

Nagin, D. S. (2005). Group-based modeling of development. Harvard University Press.

Nagin, D. S., & Land, K. C. (1993). Age, criminal careers, and population heterogeneity. Criminology, 31(3), 327-362.

Nielsen, J. D., et al. (2014). Group-based criminal trajectory analysis using cross-validation criteria. Communications in Statistics - Theory and Methods, 43(20), 4337-4356.
