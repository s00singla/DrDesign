# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("spatial-field")
result <- run_spatial_trial(data,genotype_random=TRUE)
