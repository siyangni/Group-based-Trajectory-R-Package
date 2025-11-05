#!/usr/bin/env Rscript

#' Complete Package Finalization Script
#'
#' This script performs all necessary steps to finalize the crimeTrajec package:
#' 1. Install required packages
#' 2. Generate example dataset
#' 3. Generate documentation
#' 4. Run R CMD check
#' 5. Build vignettes
#' 6. Run tests
#' 7. Build and install package
#'
#' Usage: Rscript finalize_package.R
#'   or in R: source("finalize_package.R")

cat("\n")
cat("========================================\n")
cat("crimeTrajec Package Finalization Script\n")
cat("========================================\n\n")

# Set working directory to package root
if (!file.exists("DESCRIPTION")) {
  stop("Please run this script from the package root directory (where DESCRIPTION file is located)")
}

pkg_dir <- getwd()
cat("Package directory:", pkg_dir, "\n\n")

# Step 1: Install required packages
cat("Step 1: Installing required packages...\n")
required_packages <- c("devtools", "roxygen2", "knitr", "rmarkdown", "testthat")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("  Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cran.r-project.org")
  } else {
    cat("  ", pkg, "already installed\n")
  }
}

library(devtools)

cat("\nStep 1: Complete\n")
cat("----------------------------------------\n\n")

# Step 2: Generate example dataset
cat("Step 2: Generating example dataset...\n")

if (!dir.exists("data")) {
  dir.create("data")
}

if (file.exists("data-raw/generate_crime_data.R")) {
  cat("  Running data generation script...\n")
  source("data-raw/generate_crime_data.R")
  cat("  Dataset generated successfully\n")
} else {
  cat("  Warning: data generation script not found\n")
}

cat("\nStep 2: Complete\n")
cat("----------------------------------------\n\n")

# Step 3: Generate documentation
cat("Step 3: Generating documentation from Roxygen2 comments...\n")
tryCatch({
  devtools::document()
  cat("  Documentation generated successfully\n")
}, error = function(e) {
  cat("  Error generating documentation:", e$message, "\n")
})

cat("\nStep 3: Complete\n")
cat("----------------------------------------\n\n")

# Step 4: Run R CMD check
cat("Step 4: Running R CMD check...\n")
cat("  This may take a few minutes...\n\n")

check_results <- NULL
tryCatch({
  check_results <- devtools::check(quiet = FALSE)

  cat("\n  Check results:\n")
  cat("    Errors:", length(check_results$errors), "\n")
  cat("    Warnings:", length(check_results$warnings), "\n")
  cat("    Notes:", length(check_results$notes), "\n")

  if (length(check_results$errors) > 0) {
    cat("\n  ERRORS:\n")
    for (err in check_results$errors) {
      cat("    -", err, "\n")
    }
  }

  if (length(check_results$warnings) > 0) {
    cat("\n  WARNINGS:\n")
    for (warn in check_results$warnings) {
      cat("    -", warn, "\n")
    }
  }

  if (length(check_results$notes) > 0) {
    cat("\n  NOTES:\n")
    for (note in check_results$notes) {
      cat("    -", note, "\n")
    }
  }

}, error = function(e) {
  cat("  Error during check:", e$message, "\n")
})

cat("\nStep 4: Complete\n")
cat("----------------------------------------\n\n")

# Step 5: Build vignettes
cat("Step 5: Building vignettes...\n")
cat("  This may take a few minutes...\n")

tryCatch({
  devtools::build_vignettes()
  cat("  Vignettes built successfully\n")
}, error = function(e) {
  cat("  Error building vignettes:", e$message, "\n")
  cat("  (Vignettes can be built later with devtools::build_vignettes())\n")
})

cat("\nStep 5: Complete\n")
cat("----------------------------------------\n\n")

# Step 6: Run tests
cat("Step 6: Running test suite...\n")

if (dir.exists("tests")) {
  tryCatch({
    test_results <- devtools::test()
    cat("  Tests completed\n")
    print(test_results)
  }, error = function(e) {
    cat("  Error running tests:", e$message, "\n")
  })
} else {
  cat("  No tests directory found (optional)\n")
}

cat("\nStep 6: Complete\n")
cat("----------------------------------------\n\n")

# Step 7: Build package
cat("Step 7: Building package tarball...\n")

build_path <- NULL
tryCatch({
  build_path <- devtools::build()
  cat("  Package built successfully:\n")
  cat("   ", build_path, "\n")
}, error = function(e) {
  cat("  Error building package:", e$message, "\n")
})

cat("\nStep 7: Complete\n")
cat("----------------------------------------\n\n")

# Step 8: Install package
cat("Step 8: Installing package...\n")

tryCatch({
  devtools::install()
  cat("  Package installed successfully\n")
}, error = function(e) {
  cat("  Error installing package:", e$message, "\n")
})

cat("\nStep 8: Complete\n")
cat("----------------------------------------\n\n")

# Step 9: Quick functionality test
cat("Step 9: Testing basic functionality...\n")

tryCatch({
  library(crimeTrajec)

  # Check if data loads
  data(crime_data)
  cat("  Example data loaded:", nrow(crime_data), "observations\n")

  # Try fitting a simple model
  cat("  Fitting test model (2 groups, linear)...\n")
  fit_test <- fitTrajectory(
    data = crime_data[crime_data$id %in% 1:50, ],  # Use subset for speed
    id = "id",
    time = "age",
    outcome = "offense_count",
    dist = "poisson",
    groups = 2,
    degree = 1,
    zero_inflated = FALSE,
    verbose = FALSE,
    max_iter = 50
  )

  cat("  Model fitted successfully\n")
  cat("  Convergence:", fit_test$converged, "\n")
  cat("  Log-likelihood:", round(fit_test$loglik, 2), "\n")

}, error = function(e) {
  cat("  Error in functionality test:", e$message, "\n")
})

cat("\nStep 9: Complete\n")
cat("----------------------------------------\n\n")

# Summary
cat("========================================\n")
cat("FINALIZATION SUMMARY\n")
cat("========================================\n\n")

cat("Package finalization complete!\n\n")

cat("Next steps:\n")
cat("  1. Review any warnings or notes from R CMD check\n")
cat("  2. Update author information in DESCRIPTION\n")
cat("  3. Update GitHub URLs in DESCRIPTION and README.md\n")
cat("  4. Test the package thoroughly with real data\n")
cat("  5. Finalize the academic paper (paper-draft.md)\n")
cat("  6. Consider submitting to CRAN\n\n")

cat("To test the installed package:\n")
cat("  library(crimeTrajec)\n")
cat("  ?fitTrajectory\n")
cat("  vignette('crimeTrajec-vignette')\n")
cat("  data(crime_data)\n\n")

if (!is.null(build_path)) {
  cat("Package tarball location:\n")
  cat(" ", build_path, "\n\n")
}

cat("For bug reports or questions:\n")
cat("  See README.md for contact information\n\n")

cat("========================================\n")
cat("All done!\n")
cat("========================================\n\n")
