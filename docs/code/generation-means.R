# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("generation-means")
result <- run_generation_means(data)
