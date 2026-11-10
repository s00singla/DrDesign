# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(default_data[["Compare Means"]])
result <- run_ttest_analysis(data,"welch",value_var="Value",group_var="Group",mu=25)
