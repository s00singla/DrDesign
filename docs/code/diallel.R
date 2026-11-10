# Run from the DrDesign repository root.
source("tools/example-cases.R")
load_drdesign()
pairs <- which(upper.tri(matrix(0,4,4),diag=TRUE),arr.ind=TRUE)
data <- do.call(rbind,lapply(1:3,function(r)data.frame(Rep=paste0("R",r),Parent1=paste0("P",pairs[,1]),Parent2=paste0("P",pairs[,2]),Value=20+pairs[,1]+pairs[,2]+sin(seq_len(nrow(pairs))*r))))
result <- run_combining_ability(data,method="diallel")
