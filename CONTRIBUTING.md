# Contributing to crimeTrajec

Thank you for considering contributing to crimeTrajec! This document provides guidelines for contributing to the package.

## Code of Conduct

This project adheres to a code of conduct adapted from the Contributor Covenant. By participating, you are expected to uphold this code:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with:

1. **Clear title**: Briefly describe the problem
2. **Description**: Detailed description of the bug
3. **Reproducible example**: Minimal code that reproduces the issue
4. **System information**: R version, operating system, package version
5. **Expected vs actual behavior**: What you expected to happen and what actually happened

Example:
```r
# Bug: fitTrajectory fails with error "X" when using ZIP distribution

library(crimeTrajec)
data(crime_data)

# This code produces an error
fit <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  dist = "zip",
  groups = 3
)
# Error: [error message here]

# System info
sessionInfo()
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please open an issue with:

1. **Use case**: Describe the problem you want to solve
2. **Proposed solution**: How you think it should work
3. **Alternatives**: Other approaches you considered
4. **Additional context**: Examples, references, etc.

Priority enhancement areas:
- Covariate support
- Standard errors and confidence intervals
- Additional distribution families
- Performance optimizations
- Documentation improvements

### Pull Requests

We welcome pull requests! Please follow these steps:

#### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/yourusername/crimeTrajec.git
cd crimeTrajec
```

#### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

Use descriptive branch names:
- `feature/covariate-support`
- `fix/convergence-issue`
- `docs/improve-vignette`

#### 3. Make Changes

Follow these guidelines:

**Code Style**
- Use snake_case for function names and variables
- Use meaningful variable names (no single letters except for standard iterators)
- Maximum line length: 80-100 characters
- Use spaces, not tabs (2-space indentation)
- Add comments for complex logic

**Documentation**
- Document all exported functions with roxygen2
- Include examples in function documentation
- Update vignette if adding major features
- Update NEWS.md with changes

**Testing**
- Add tests for new features in `tests/testthat/`
- Ensure all tests pass with `devtools::test()`
- Aim for high code coverage

**Example of good code style:**
```r
#' Calculate Log-Likelihood for Trajectory Model
#'
#' @param data Data frame with longitudinal observations
#' @param params List of model parameters
#' @return Numeric log-likelihood value
#' @keywords internal
calculate_loglikelihood <- function(data, params) {
  # Initialize log-likelihood
  loglik <- 0

  # Iterate over individuals
  for (i in seq_len(nrow(data))) {
    # Compute individual contribution
    individual_ll <- compute_individual_ll(data[i, ], params)
    loglik <- loglik + individual_ll
  }

  return(loglik)
}
```

#### 4. Test Your Changes

Before submitting:

```r
# Load package
devtools::load_all()

# Run tests
devtools::test()

# Check package
devtools::check()
```

All checks should pass with 0 errors, 0 warnings, 0 notes.

#### 5. Commit Changes

Write clear, descriptive commit messages:

```bash
# Good commit messages
git commit -m "Add support for time-varying covariates in fitTrajectory"
git commit -m "Fix convergence issue for Gaussian models with small samples"
git commit -m "Update vignette with covariate examples"

# Less helpful commit messages (avoid these)
git commit -m "Fix bug"
git commit -m "Update code"
git commit -m "Changes"
```

#### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub with:

- **Title**: Clear, concise description
- **Description**:
  - What changes you made
  - Why you made them
  - How to test them
- **Related issues**: Link to any related issue numbers

**Pull Request Template:**
```
## Description
[Describe your changes]

## Motivation
[Why is this change needed? What problem does it solve?]

## Changes Made
- [List specific changes]
- [Include file names if helpful]

## Testing
[How did you test these changes?]

## Checklist
- [ ] Code follows package style guidelines
- [ ] Documentation updated (roxygen2 comments)
- [ ] Tests added/updated
- [ ] All tests pass locally
- [ ] R CMD check passes with 0 errors, warnings, notes
- [ ] NEWS.md updated
```

## Development Setup

### Required Tools

- R >= 3.5.0
- RStudio (recommended but not required)
- devtools package
- roxygen2 package
- testthat package

### Installation

```r
install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown"))
```

### Development Workflow

```r
# 1. Make changes to R code in R/ directory

# 2. Load all changes
devtools::load_all()

# 3. Test interactively
data(crime_data)
fit <- fitTrajectory(...)

# 4. Update documentation
devtools::document()

# 5. Run tests
devtools::test()

# 6. Check package
devtools::check()

# 7. Repeat as needed
```

## Coding Standards

### R Code

Follow the [Tidyverse Style Guide](https://style.tidyverse.org/):

- Use `<-` for assignment, not `=`
- Put spaces around operators (`x + y`, not `x+y`)
- Use `TRUE` and `FALSE`, not `T` and `F`
- Avoid semicolons
- Use `"` for strings, not `'` (except when needed)

### Documentation

Roxygen2 documentation must include:

```r
#' @title Short title (one line)
#' @description Longer description (paragraph)
#' @param param_name Description of parameter
#' @return Description of return value
#' @examples
#' # Example code
#' @export  # For user-facing functions
#' @keywords internal  # For internal functions
```

### Tests

Write tests using testthat:

```r
test_that("function handles edge case correctly", {
  # Setup
  test_data <- create_test_data()

  # Execute
  result <- my_function(test_data)

  # Assert
  expect_equal(result$value, expected_value)
  expect_true(result$converged)
  expect_type(result$output, "double")
})
```

## Areas for Contribution

We especially welcome contributions in these areas:

### High Priority

1. **Covariate Support**
   - Implement covariates for group membership
   - Implement covariates for trajectory shape
   - Add formula interface

2. **Standard Errors**
   - Implement observed information matrix
   - Add bootstrap procedures
   - Provide confidence intervals

3. **Performance**
   - Profile and optimize bottlenecks
   - Consider Rcpp for critical sections
   - Improve EM convergence speed

### Medium Priority

4. **Additional Distributions**
   - Negative binomial
   - Beta (for proportions)
   - Ordinal outcomes

5. **Missing Data**
   - Full information maximum likelihood
   - Multiple imputation integration

6. **Visualization**
   - ggplot2 plotting option
   - Interactive plots with plotly
   - Diagnostic plots

### Lower Priority

7. **Extensions**
   - Multilevel trajectories
   - Multivariate outcomes
   - Time-varying covariates
   - Bayesian estimation

8. **User Interface**
   - Shiny app for interactive analysis
   - Better error messages
   - Progress bars for long computations

## Questions?

If you have questions about contributing:

- Open an issue with the "question" label
- Email the maintainers (see DESCRIPTION file)
- Check existing issues and pull requests

## Recognition

Contributors will be:

- Listed in the package DESCRIPTION file
- Acknowledged in package documentation
- Credited in any associated publications (for major contributions)

Thank you for helping improve crimeTrajec!
