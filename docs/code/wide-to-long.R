# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(default_data$RBD)
result <- run_data_preparation(data,c("Rep1","Rep2","Rep3"),"trt",wide=TRUE)
