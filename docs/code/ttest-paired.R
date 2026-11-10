# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- data.frame(Before=c(10.1,11.3,9.8,12.2),After=c(11,12,10.4,12.8))
result <- run_ttest_analysis(data,"paired",value_var="Before",pair_left="Before",pair_right="After")
