# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("incomplete-block")
result <- run_genetic_variability(data,"Yield",incomplete=TRUE,genotype_random=FALSE)
