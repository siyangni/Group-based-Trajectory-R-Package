# crimeTrajec 0.1.0

## Initial Release

This is the first public release of crimeTrajec, an open-source R package for group-based trajectory modeling in criminology.

### Features

* **Core Functionality**
  - `fitTrajectory()`: Fit group-based trajectory models using EM algorithm
  - Support for Poisson, zero-inflated Poisson, and Gaussian distributions
  - Polynomial trajectory specification (degree 0-3)
  - Robust numerical stability enhancements

* **S3 Methods**
  - `print.crimeTrajec()`: Display model summary
  - `plot.crimeTrajec()`: Visualize trajectories with confidence intervals
  - `predict.crimeTrajec()`: Extract group membership and predictions

* **Model Selection**
  - `selectNumGroups()`: Compare models using BIC, AIC, and cross-validation
  - k-fold cross-validation implementation (default k=5)
  - Automated optimal group identification

* **Data**
  - `crime_data`: Simulated longitudinal offense data for 250 individuals
  - Realistic patterns based on criminological research

* **Documentation**
  - Comprehensive vignette with tutorial and technical details
  - Complete function documentation via Roxygen2
  - Example analyses and interpretation guidelines

### Implementation Details

* Custom EM algorithm implementation from scratch for transparency
* Iteratively weighted least squares (IWLS) for Poisson regression
* Log-sum-exp trick for numerical stability
* Automatic handling of missing data (listwise deletion)
* Time variable standardization for improved convergence

### Known Limitations

* Limited support for covariates (planned for v0.2.0)
* No standard errors or confidence intervals for parameters (planned)
* Pure R implementation may be slow for very large datasets
* Missing data assumed MCAR (missing completely at random)

### References

This package implements methods described in:

* Nagin, D. S. (2005). Group-based modeling of development. Harvard University Press.
* Jones, B. L., Nagin, D. S., & Roeder, K. (2001). A SAS procedure based on mixture models for estimating developmental trajectories. Sociological Methods & Research, 29(3), 374-393.

---

# Future Releases

## Planned for v0.2.0

* Full covariate support for group membership and trajectory shape
* Standard errors via observed information matrix
* Bootstrap procedures for confidence intervals
* Improved starting value algorithms
* Performance optimizations

## Planned for v0.3.0

* Bayesian estimation via MCMC
* Multilevel trajectory models
* Time-varying covariates
* Rcpp integration for computational speed

## Planned for v1.0.0

* Multivariate joint trajectory modeling
* Shiny GUI for interactive analysis
* Integration with tidymodels framework
* Comprehensive automated testing suite
