# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(met_example)
data$Height <- 50+2*data$Yield+cos(seq_len(nrow(data)))
batch <- run_met_batch_analysis(data,"GEN","ENV","REP",c("Yield","Height"),c(Yield="h",Height="l"))
result <- list(tables=met_all_batch_result_tables(batch,batch$results[[1]]))
