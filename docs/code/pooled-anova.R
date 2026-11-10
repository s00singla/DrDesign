# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(pooled_example)
result <- run_pooled_anova(data)
