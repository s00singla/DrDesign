# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("heterosis")
result <- run_heterosis(data,"G01","G02",c("G03","G04"),check="G05")
