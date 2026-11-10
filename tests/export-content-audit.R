source("R/shared.R")
results<-readRDS("output/research-tests/results.rds")
counts<-list()
for(label in names(results)) {
  path<-paste0("output/research-reports/",gsub(" ","-",tolower(label)),".docx")
  document<-xml2::read_xml(unz(path,"word/document.xml"))
  text<-xml2::xml_text(document)
  values<-unique(unlist(lapply(results[[label]]$tables,function(x) as.character(unlist(publication_table(x),use.names=FALSE))),use.names=FALSE))
  values<-unique(c(values,unlist(lapply(results[[label]]$tables,report_table_notes),use.names=FALSE)))
  missing<-values[!vapply(values,function(value)grepl(value,text,fixed=TRUE),logical(1))]
  if(length(missing)) stop(label,": missing rendered values: ",paste(missing,collapse=", "))
  counts[[label]]<-length(values)
}
write.csv(data.frame(Report=names(counts),DistinctValuesChecked=unlist(counts),Result="PASS"),"output/scientific-audit/word-content-checks.csv",row.names=FALSE)
cat("PASS:",length(counts),"Word reports contain every expected formatted table value and inference note.\n")
