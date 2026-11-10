source("tools/example-cases.R");load_drdesign();source("tools/guide-content.R",encoding="UTF-8")
examples<-readRDS("output/scientific-audit/examples.rds")
checks<-read.csv("output/scientific-audit/checks.csv")
stopifnot(all(checks$Result=="PASS"),setequal(names(examples),names(example_cases())))
for(path in c("docs","docs/examples","docs/data","docs/assets","docs/code","vignettes/articles")) dir.create(path,recursive=TRUE,showWarnings=FALSE)
for(id in names(examples)) {
  x<-examples[[id]]
  write.csv(x$data,file.path("docs/data",paste0(id,".csv")),row.names=FALSE)
  for(i in seq_along(x$tables)) {
    t<-x$tables[[i]]
    if(!identical(rownames(t),as.character(seq_len(nrow(t))))) t<-cbind(Term=rownames(t),t)
    write.csv(t,file.path("docs/data",paste0(id,"-table-",i,".csv")),row.names=FALSE)
  }
  examples[[id]]<-list(module=x$module,code=x$code,input=publication_table(head(x$data,8)),rows=nrow(x$data),tables=lapply(x$tables,publication_table),table_notes=lapply(x$tables,report_table_notes),plots=x$plots,diagnostics=unique(c(x$result$warnings,x$result$report_note)))
}
jsonlite::write_json(list(modules=module_registry,groups=module_groups,notes=guide_content,examples=examples,checks=checks,conventions=reporting_note()),"output/scientific-audit/guide.json",dataframe="rows",auto_unbox=TRUE,pretty=TRUE,na="null")
cat("Prepared guide data. Run python tools/build-guide.py next.\n")
