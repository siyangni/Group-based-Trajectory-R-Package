# crimeTrajec Package - Installation and Testing Guide

This guide walks through the steps to finalize, test, and install the crimeTrajec package.

## Prerequisites

Ensure you have R installed (version >= 3.5.0) along with the following packages:

```r
install.packages(c("devtools", "roxygen2", "knitr", "rmarkdown", "testthat"))
```

## Step-by-Step Installation

### Step 1: Generate the Example Dataset

From the package root directory, run in R:

```r
setwd("/home/user/Group-based-Trajectory-R-Package")
source("data-raw/generate_crime_data.R")
```

This will create `data/crime_data.rda` with simulated longitudinal crime data.

Expected output:
```
Dataset generated successfully!
Total observations: 2500
Number of individuals: 250
Missing values: 125 (5.0%)
```

### Step 2: Generate Documentation

Generate man pages from Roxygen2 comments:

```r
library(devtools)
setwd("/home/user/Group-based-Trajectory-R-Package")
document()
```

This creates `.Rd` files in the `man/` directory.

### Step 3: Check Package

Run R CMD check to identify issues:

```r
check()
```

Address any errors, warnings, or notes. Common issues:
- Missing examples in documentation
- Undeclared dependencies
- Non-ASCII characters
- Long-running examples (wrap in `\dontrun{}`)

### Step 4: Build Vignettes

Build the package vignette:

```r
build_vignettes()
```

This may take a few minutes. The vignette will be available via `vignette("crimeTrajec-vignette")` after installation.

### Step 5: Test Core Functionality

Load the package in development mode and test:

```r
load_all()

# Load example data
data(crime_data)
str(crime_data)

# Fit a simple 2-group model
fit2 <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  dist = "poisson",
  groups = 2,
  degree = 1,
  zero_inflated = FALSE,
  verbose = TRUE
)

# Check results
print(fit2)
plot(fit2)
predict(fit2, type = "class")

# Fit a 3-group ZIP model
fit3 <- fitTrajectory(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  dist = "zip",
  groups = 3,
  degree = 2,
  zero_inflated = TRUE,
  verbose = TRUE
)

print(fit3)
plot(fit3, include_ci = TRUE)

# Test model selection
comparison <- selectNumGroups(
  data = crime_data,
  id = "id",
  time = "age",
  outcome = "offense_count",
  max_groups = 4,
  criteria = c("BIC", "AIC"),
  dist = "zip",
  degree = 2,
  verbose = TRUE
)

print(comparison)
```

### Step 6: Build the Package

Build the package tarball:

```r
build()
```

This creates `crimeTrajec_0.1.0.tar.gz` in the parent directory.

### Step 7: Install the Package

Install from the tarball:

```r
install.packages("../crimeTrajec_0.1.0.tar.gz", repos = NULL, type = "source")
```

Or install directly:

```r
install()
```

### Step 8: Verify Installation

After installation, test in a fresh R session:

```r
library(crimeTrajec)

# Check help
?fitTrajectory

# Load vignette
vignette("crimeTrajec-vignette")

# Run example
data(crime_data)
fit <- fitTrajectory(data = crime_data, id = "id", time = "age",
                     outcome = "offense_count", groups = 3, degree = 2)
plot(fit)
```

## Testing Suite (Optional but Recommended)

Create unit tests in `tests/testthat/`:

```r
use_testthat()
```

Then create test files:

**tests/testthat/test-fitTrajectory.R:**
```r
test_that("fitTrajectory returns correct structure", {
  data(crime_data)
  fit <- fitTrajectory(data = crime_data, id = "id", time = "age",
                       outcome = "offense_count", groups = 2, degree = 1,
                       verbose = FALSE)

  expect_s3_class(fit, "crimeTrajec")
  expect_true(fit$groups == 2)
  expect_true(fit$degree == 1)
  expect_true(nrow(fit$coefficients) == 2)
  expect_true(ncol(fit$coefficients) == 2)
})

test_that("fitTrajectory handles missing data", {
  data(crime_data)
  expect_no_error({
    fit <- fitTrajectory(data = crime_data, id = "id", time = "age",
                         outcome = "offense_count", groups = 2, degree = 1,
                         verbose = FALSE)
  })
})
```

Run tests:
```r
test()
```

## CRAN Submission Checklist

Before submitting to CRAN:

### Required Checks
- [ ] `devtools::check()` returns 0 errors, 0 warnings, 0 notes
- [ ] All examples run successfully
- [ ] Vignette builds without errors
- [ ] Package installs cleanly
- [ ] All URLs are valid and accessible

### Documentation
- [ ] DESCRIPTION has valid email addresses
- [ ] LICENSE file is correct
- [ ] NEWS.md documents version changes
- [ ] README.md is up to date
- [ ] All functions have complete documentation
- [ ] All parameters are documented

### Code Quality
- [ ] No calls to `browser()`, `print()`, or `cat()` in functions (except when appropriate)
- [ ] No absolute file paths
- [ ] No modification of user's .Rprofile or .Renviron
- [ ] Examples complete in < 5 seconds each
- [ ] Package size < 5 MB

### Testing
- [ ] Examples tested on multiple platforms (if possible)
- [ ] Vignette tested
- [ ] No warnings during installation

## Known Issues and Solutions

### Issue: EM Algorithm Doesn't Converge

**Solution**:
- Reduce `max_iter` or increase `tol`
- Try simpler model (fewer groups, lower polynomial degree)
- Check data for extreme outliers
- Try different starting values

### Issue: BIC Values All Increase

**Solution**:
- Data may not have clear group structure
- Try different polynomial degrees
- Check if distribution is appropriate

### Issue: Vignette Build Fails

**Solution**:
- Ensure knitr and rmarkdown are installed
- Check for errors in vignette R code chunks
- Verify data is available

### Issue: Package Check Notes About Undefined Global Variables

**Solution**:
Add to a utils.R file:
```r
utils::globalVariables(c("variable_name"))
```

## Troubleshooting

### R CMD check warnings about examples

Wrap long-running examples in `\dontrun{}`:
```r
#' @examples
#' \dontrun{
#' # This takes > 5 seconds
#' fit <- selectNumGroups(data, id, time, outcome, max_groups = 6)
#' }
```

### Missing Rd files

Re-run:
```r
devtools::document()
```

### Namespace conflicts

Check that all exported functions are properly documented with `@export` tag and all imported functions use `@importFrom` or are listed in DESCRIPTION Imports.

## Development Workflow

For ongoing development:

1. Make changes to R code
2. Run `devtools::load_all()` to test changes
3. Run `devtools::document()` to update documentation
4. Run `devtools::test()` to run tests
5. Run `devtools::check()` before committing
6. Commit and push changes
7. Increment version number in DESCRIPTION when ready for release

## Next Steps After Installation

1. **Test on real data**: Apply the package to actual longitudinal crime data
2. **Gather feedback**: Share with colleagues and incorporate suggestions
3. **Write paper**: Finalize the academic paper (paper-draft.md)
4. **Submit to journal**: Journal of Quantitative Criminology or similar
5. **Submit to CRAN**: After thorough testing and peer review
6. **Promote**: Present at conferences, share on social media, etc.

## Getting Help

- Package issues: Open GitHub issue
- Statistical questions: Consult references in vignette
- R programming: RStudio Community, Stack Overflow

## Contact

For questions about this package, contact:
[Author Name] - [email@example.com]
