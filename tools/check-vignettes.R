# Execute every future vignette from its own directory, as a reader would.
dir.create("output/vignette-checks",recursive=TRUE,showWarnings=FALSE)
destination<-normalizePath("output/vignette-checks")
checks<-list()
for(path in list.files("vignettes/articles","\\.Rmd$",full.names=TRUE)) {
  checks[[basename(path)]]<-tryCatch({
    rmarkdown::render(path,output_dir=destination,quiet=TRUE,envir=new.env(parent=globalenv()))
    "PASS"
  },error=function(e) paste("FAIL",conditionMessage(e)))
  cat(basename(path),checks[[basename(path)]],"\n")
}
write.csv(data.frame(Article=names(checks),Result=unlist(checks)),file.path(destination,"checks.csv"),row.names=FALSE)
if(any(unlist(checks)!="PASS")) quit(status=1)
