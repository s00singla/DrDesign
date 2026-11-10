# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(default_data[["Descriptive Statistics"]])
result <- run_descriptive_analysis(data,"summary",c("Yield","Height"),"Group")
