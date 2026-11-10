# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(default_data[["Factorial CRD"]])
result <- run_design_analysis(data, "Factorial CRD", levels_a=2, levels_b=2)
