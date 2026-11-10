# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(default_data[["Factorial RBD"]])
result <- run_design_analysis(data, "Factorial RBD", levels_a=2, levels_b=2)
