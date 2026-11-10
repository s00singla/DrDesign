# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- data.frame(Mean=c(20,22,24))
result <- run_power_planning(data$Mean,residual_sd=3,method="anova")
