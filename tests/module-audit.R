source("R/shared.R")
source("R/analysis.R")
source("R/met_analysis.R")
source("R/app_builders.R")

results <- list()
check <- function(label, expr) {
  result <- tryCatch({ force(expr); "PASS" }, error = function(e) paste("FAIL:", conditionMessage(e)))
  results[[label]] <<- result
  cat(label, ": ", result, "\n", sep = "")
}

modules <- c("portal", "design_analyzer", "crd_rbd", "factorial_design",
             "pooled_anova", "pooled_split_plot", "split_plot",
             "correlation_regression", "descriptive_statistics", "compare_means", "met_stability")
for (module in modules) {
  check(paste(module, "UI"), {
    html <- htmltools::renderTags(get(paste0(module, "_ui"))())$html
    stopifnot(nchar(html) > 100)
  })
  check(paste(module, "server initialization"), {
    shiny::testServer(get(paste0(module, "_server")), {
      if (module == "crd_rbd") session$setInputs(design = "CRD")
      if (module == "factorial_design") session$setInputs(design = "Factorial CRD")
      session$flushReact()
    })
  })
}
check("Regression with missing response", {
  dat <- read_pasted_table(correlation_example)
  dat$Yield[1] <- NA_real_
  result <- run_correlation_regression(dat, "Yield", c("Rainfall", "Nitrogen"), exclude_missing = TRUE)
  stopifnot(nrow(result$diagnostics) == sum(complete.cases(dat[c("Yield", "Rainfall", "Nitrogen")])))
})
check("Regression with spaces in column names", {
  dat <- read_pasted_table(correlation_example)
  names(dat)[names(dat) == "Yield"] <- "Grain Yield"
  result <- run_correlation_regression(dat, "Grain Yield", c("Rainfall", "Nitrogen"))
  stopifnot(is.data.frame(result$coefficients))
})
check("CSV upload round trip", {
  dat <- read_pasted_table(correlation_example)
  path <- tempfile(fileext = ".csv")
  write.csv(dat, path, row.names = FALSE)
  stopifnot(isTRUE(all.equal(read_uploaded_table(path), dat)))
  unlink(path)
})
check("XLSX upload round trip", {
  dat <- read_pasted_table(correlation_example)
  path <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(dat, path)
  stopifnot(isTRUE(all.equal(read_uploaded_table(path), dat)))
  unlink(path)
})
check("Application syntax", {
  files <- c("app.R", list.files("R", "\\.R$", full.names = TRUE),
             list.files("inst", "^app\\.R$", recursive = TRUE, full.names = TRUE))
  invisible(lapply(files, parse))
})
dir.create("output", showWarnings = FALSE)
write.csv(data.frame(Check = names(results), Result = unlist(results), row.names = NULL),
          "output/module-audit-results.csv", row.names = FALSE)
if (any(startsWith(unlist(results), "FAIL"))) quit(status = 1)
