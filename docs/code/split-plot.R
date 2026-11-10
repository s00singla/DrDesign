# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
data <- expand.grid(Rep=paste0("R",1:4),MainPlot=paste0("A",1:3),SubPlot=paste0("B",1:3))
i <- seq_len(nrow(data))
data$Value <- 30+as.numeric(data$MainPlot)*2+as.numeric(data$SubPlot)+sin(i*1.7)+rep(c(-2,1,0,1),9)
result <- run_split_plot(data)
