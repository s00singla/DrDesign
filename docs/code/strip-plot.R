# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("strip-plot")
result <- run_strip_trial(data)
