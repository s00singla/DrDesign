# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- data.frame(Seed=7)
result <- run_design_layout("CRD",seed=7,trt=4,rep=3)
