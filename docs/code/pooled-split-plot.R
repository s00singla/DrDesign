# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- read_pasted_table(pooled_split_plot_example)
data$Value <- data$Value+sin(seq_len(nrow(data))*1.7)
result <- run_pooled_split_plot(data,include_pwpp=TRUE)
