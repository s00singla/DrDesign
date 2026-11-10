# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(default_data[["RBD"]])
result <- run_design_analysis(data, "RBD", comparison_method="LSD")
