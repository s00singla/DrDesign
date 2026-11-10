# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(correlation_example)
result <- run_correlation_regression(data,"Yield",c("Rainfall","Nitrogen"))
