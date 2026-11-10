source("R/shared.R")
source("R/analysis.R")
source("R/app_builders.R")
source("R/research_analysis.R")
source("R/research_ui.R")
results <- readRDS("output/research-tests/results.rds")
dir.create("output/research-reports",showWarnings=FALSE)
failures <- character()
for(label in names(results)) {
  result <- results[[label]]
  stem <- file.path("output/research-reports",gsub(" ","-",tolower(label)))
  tryCatch({
    sections <- lapply(names(result$tables),function(nm)list(title=nm,table=result$tables[[nm]]))
    sections <- c(sections,lapply(names(result$plots),function(nm)list(title=nm,plot=result$plots[[nm]])),list(list(title="Diagnostics",text=paste(result$warnings,collapse="\n"))))
    save_html_report(result$title,sections,paste0(stem,".html"))
    for(format in c("word_document","pdf_document")) {
      ext <- if(format=="word_document") ".docx" else ".pdf"
      render_parameterized_report(paste0(stem,ext),format,research_report_params(result),template_name="research-report-template.Rmd")
      stopifnot(file.info(paste0(stem,ext))$size>1000)
      if (format == "word_document") {
        connection <- unz(paste0(stem,ext),"word/document.xml")
        document <- xml2::read_xml(connection)
        tables <- xml2::xml_find_all(document,".//w:tbl",xml2::xml_ns(document))
        expected <- Filter(function(x)nrow(x)>0 && ncol(x)>0,result$tables)
        stopifnot(length(tables)>=length(expected))
        # Require body cells, not just headings or successfully created files.
        stopifnot(all(vapply(tables,function(x)length(xml2::xml_find_all(x,".//w:tr",xml2::xml_ns(document)))>1L,logical(1))))
      }
    }
    cat("PASS reports:",label,"\n")
  },error=function(e){failures<<-c(failures,paste(label,conditionMessage(e)));cat("FAIL reports:",label,conditionMessage(e),"\n")})
}
writeLines(failures,"output/research-reports/failures.txt")
if(length(failures)) quit(status=1)
cat("All research reports passed.\n")
