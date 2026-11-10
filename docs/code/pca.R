# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("pca-diversity")
result <- run_diversity(data,c("Yield","Height","Maturity"),clusters=3)
