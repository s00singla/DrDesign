# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(default_data[["CRD"]])
result <- run_design_analysis(data, "CRD", comparison_method="Tukey")
