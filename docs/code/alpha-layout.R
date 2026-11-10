# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- data.frame(Genotypes=12,BlockSize=3,Replications=3,Seed=7)
result <- list(fieldbook=run_alpha_layout(12,3,3,7))
