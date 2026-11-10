# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("multi-trait-selection")
result <- run_multi_trait_selection(data,c("Yield","Height","Maturity"),lower_traits="Maturity",method="mgidi")
