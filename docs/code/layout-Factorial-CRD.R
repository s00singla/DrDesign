# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- data.frame(Seed=7)
result <- run_design_layout("Factorial CRD",seed=7,factor_a_trt=2,factor_b_trt=3,rep=3)
