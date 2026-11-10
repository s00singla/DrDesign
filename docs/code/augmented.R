# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("augmented-trial")
result <- run_augmented_trial(data,c("C1","C2"))
