# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(met_example)
result <- run_met_analysis(data,"GEN","ENV","REP","Yield",direction="h")
