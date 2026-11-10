# Exercise downloadHandler in the environment used by a running Shiny app.
# Standalone report tests source helpers globally and cannot catch this bug.
stopifnot(!exists("reporting_note",envir=globalenv(),inherits=FALSE))
app_env<-new.env(parent=globalenv())
for(file in c("shared","app_builders")) source(file.path("R",paste0(file,".R")),local=app_env)
stopifnot(!exists("reporting_note",envir=globalenv(),inherits=FALSE))
dir.create("output/report-download-tests",recursive=TRUE,showWarnings=FALSE)
server<-eval(quote(function(input,output,session) {
  params<-reactive(list(report_title="Download handler test",design_name="Regression",
    extra_tables=list("Coefficients"=data.frame(Term=c("(Intercept)","Treatment"),Estimate=c(2.5,1.2),P=c(.01,.00001))),
    report_note="Report generated inside the application environment."))
  register_report_downloads(output,"legacy_pdf","legacy_word","legacy",params)
  register_report_downloads(output,"research_pdf","research_word","research",params,template_name="research-report-template.Rmd")
}),envir=app_env)
shiny::testServer(server,{
  for(id in c("legacy_pdf","legacy_word","research_pdf","research_word")) {
    path<-output[[id]]
    stopifnot(file.exists(path),file.info(path)$size>1000)
    pdf<-endsWith(id,"pdf")
    signature<-readBin(path,"raw",n=if(pdf)4L else 2L)
    stopifnot(identical(signature,charToRaw(if(pdf)"%PDF" else "PK")))
    if(!pdf) {
      document<-xml2::read_xml(unz(path,"word/document.xml"))
      stopifnot(grepl("2.500",xml2::xml_text(document),fixed=TRUE),
                grepl("<0.001",xml2::xml_text(document),fixed=TRUE))
    }
    file.copy(path,file.path("output/report-download-tests",paste0(id,if(pdf)".pdf" else ".docx")),overwrite=TRUE)
    cat("PASS download handler:",id,"\n")
  }
})
