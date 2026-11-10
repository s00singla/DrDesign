# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("data-preparation")
result <- run_data_preparation(data,c("Yield","Height"),c("Genotype","Rep"))
