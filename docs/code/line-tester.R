# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- research_example("combining-ability")
result <- run_combining_ability(data)
