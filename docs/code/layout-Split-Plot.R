# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- data.frame(Seed=7)
result <- run_design_layout("Split Plot",seed=7,main_trt=3,sub_trt=3,rep=3)
