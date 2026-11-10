# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("genetic-variability")
result <- run_genetic_variability(data,c("Yield","Height"))
