# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- data.frame(Seed=7)
result <- run_design_layout("Augmented RCBD",seed=7,checks=3,test_trt=6,rep=3)
