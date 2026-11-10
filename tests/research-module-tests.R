source("R/shared.R")
source("R/analysis.R")
source("R/met_analysis.R")
source("R/app_builders.R")
source("R/research_analysis.R")
source("R/research_ui.R")
dir.create("output/research-tests",recursive=TRUE,showWarnings=FALSE)
results <- list(); outputs <- list()
check <- function(name, expr) {
  tryCatch({
    value <- force(expr)
    if (is.list(value) && !is.null(value$tables)) {
      stopifnot(length(value$tables)>0,all(vapply(value$tables,is.data.frame,logical(1))))
      outputs[[name]] <<- value
    }
    results[[name]] <<- "PASS"; cat("PASS",name,"\n")
  },error=function(e) {results[[name]] <<- paste("FAIL",conditionMessage(e));cat("FAIL",name,conditionMessage(e),"\n")})
}
must_error <- function(expr, pattern) {
  error <- tryCatch({force(expr);NULL},error=identity)
  stopifnot(inherits(error,"error"),grepl(pattern,conditionMessage(error),ignore.case=TRUE))
}
check("Data preparation",run_data_preparation(research_example("data-preparation"),c("Yield","Height"),c("Genotype","Rep")))
check("Augmented",run_augmented_trial(research_example("augmented-trial"),c("C1","C2")))
check("Strip",run_strip_trial(research_example("strip-plot")))
check("Genetic",run_genetic_variability(research_example("genetic-variability"),c("Yield","Height")))
check("Weighted selection",run_multi_trait_selection(research_example("multi-trait-selection"),c("Yield","Height","Maturity"),"Maturity"))
check("MGIDI",{
  r<-run_multi_trait_selection(research_example("multi-trait-selection"),c("Yield","Height","Maturity"),"Maturity",method="mgidi")
  stopifnot(all(r$tables$Rankings$Genotype %in% research_example("multi-trait-selection")$Genotype));r
})
check("PCA",run_diversity(research_example("pca-diversity"),c("Yield","Height","Maturity")))
check("Power",{r<-run_power_planning(c(20,22,24),3);stopifnot(r$tables[[1]]$AchievedPower>=0.8);r})
check("Two group power",run_power_planning(c(20,22),3,method="two-sample"))
check("Alpha layout",{a<-run_alpha_layout();b<-run_alpha_layout();stopifnot(identical(a,b),nrow(a)==36,!anyDuplicated(a$PlotID))})
check("Legacy fieldbook recording metadata",{
  a<-run_design_layout("RBD",42,trt=4,rep=3)$fieldbook
  b<-run_design_layout("RBD",seed=42,trt=4,rep=3)$fieldbook
  stopifnot(identical(a,b),all(a$Seed==42),!anyDuplicated(a$PlotID),all(is.na(a$Response)),all(c("Row","Column") %in% names(a)))
})
check("Incomplete random",run_genetic_variability(research_example("incomplete-block"),"Yield",incomplete=TRUE))
check("Incomplete fixed",run_genetic_variability(research_example("incomplete-block"),"Yield",incomplete=TRUE,genotype_random=FALSE))
check("Spatial fixed",run_spatial_trial(research_example("spatial-field")))
check("Spatial random",run_spatial_trial(research_example("spatial-field"),genotype_random=TRUE))
check("Line tester",run_combining_ability(research_example("combining-ability")))
check("Diallel",{
  pairs<-which(upper.tri(matrix(0,4,4),diag=TRUE),arr.ind=TRUE)
  d<-do.call(rbind,lapply(1:3,function(r)data.frame(Rep=paste0("R",r),Parent1=paste0("P",pairs[,1]),Parent2=paste0("P",pairs[,2]),Value=20+pairs[,1]+pairs[,2]+sin(seq_len(nrow(pairs))*r))))
  run_combining_ability(d,method="diallel")
})
check("Heterosis",run_heterosis(research_example("heterosis"),"G01","G02",c("G03","G04"),"G05"))
check("Generation means",run_generation_means(research_example("generation-means")))
check("Generation analytical coefficients",{
  d<-research_example("generation-means")
  a<-c(1,-1,0,0,.5,-.5);b<-c(0,0,1,.5,.5,.5)
  X<-cbind(1,a,b,a*a,a*b,b*b);truth<-c(20,4,5,2,1,3);d$Mean<-as.numeric(X%*%truth)
  result<-run_generation_means(d)
  stopifnot(isTRUE(all.equal(result$tables[[2]]$Estimate,truth,tolerance=1e-8)))
})
check("Independent CRD power reference",{
  result<-run_power_planning(c(120,130,140,150),sqrt(500),target_power=.9)
  stopifnot(result$tables[[1]]$ReplicationsPerGroup==16)
})
check("Genetic variance against balanced ANOVA",{
  d<-research_example("genetic-variability"); av<-anova(lm(Yield~Rep+Genotype,d))
  r<-run_genetic_variability(d,"Yield")$tables[[1]]
  expected<-(av["Genotype","Mean Sq"]-av["Residuals","Mean Sq"])/3
  stopifnot(abs(r$GeneticVariance-expected)<1e-4,abs(r$ResidualVariance-av["Residuals","Mean Sq"])<1e-4)
})
check("Augmented adjustment against check means",{
  d<-research_example("augmented-trial");r<-run_augmented_trial(d,c("C1","C2"))$tables[[1]]
  checks<-d[d$Genotype %in% c("C1","C2"),]; offsets<-tapply(checks$Value,checks$Block,mean)-mean(checks$Value)
  test<-d[!d$Genotype %in% c("C1","C2"),]
  expected<-test$Value-offsets[test$Block]
  stopifnot(max(abs(r$mean.adj[match(test$Genotype,r$Genotype)]-expected))<1e-8)
})
check("Strip main-effect error strata",{
  d<-research_example("strip-plot");r<-run_strip_trial(d)$tables[[1]]
  m<-tapply(d$Value,d[c("Rep","FactorA")],mean); grand<-mean(m)
  ssA<-9*sum((colMeans(m)-grand)^2)
  ssRA<-3*sum((sweep(sweep(m,1,rowMeans(m)),2,colMeans(m))+grand)^2)
  expected<-(ssA/2)/(ssRA/4)
  stopifnot(abs(r[2,"F value"]-expected)<1e-7)
})
check("Line tester GCA against marginal means",{
  d<-research_example("combining-ability");r<-run_combining_ability(d)$tables[[3]]
  expected<-tapply(d$Value,d$Parent1,mean)-mean(d$Value)
  stopifnot(max(abs(r$estimate[match(paste("Line GCA",names(expected)),r$contrast)]-expected))<1e-8)
})
check("Heterosis against observed balanced means",{
  d<-research_example("heterosis");r<-run_heterosis(d,"G01","G02","G03")$tables[[1]]
  m<-tapply(d$Value,d$Genotype,mean)
  expected<-100*(m["G03"]/mean(m[c("G01","G02")])-1)
  stopifnot(abs(r$HeterosisPercent[r$Comparison=="Mid-parent"]-expected)<1e-8)
})
check("PCA orthogonal variance accounting",{
  r<-run_diversity(research_example("pca-diversity"),c("Yield","Height","Maturity"))
  loadings<-as.matrix(r$tables$Loadings[,-1]);stopifnot(max(abs(crossprod(loadings)-diag(3)))<1e-8,abs(sum(r$tables[[1]]$VariancePercent)-100)<1e-8)
})
check("Reviewed exclusions",{
  d<-research_example("pca-diversity");d$Yield[2]<-NA_real_
  must_error(run_diversity(d,c("Yield","Height")),"Review")
  r<-run_diversity(d,c("Yield","Height"),exclude_missing=TRUE)
  stopifnot(identical(r$exclusions$Observation,2L),nrow(r$dataset)==11)
})
check("Invalid designs rejected",{
  d<-research_example("strip-plot");must_error(run_strip_trial(d[-1,]),"balanced")
  must_error(run_strip_trial(rbind(d,d[1,])),"Duplicate")
  d<-research_example("augmented-trial");must_error(run_augmented_trial(d[-1,],c("C1","C2")),"Checks")
  d<-research_example("pca-diversity");d$Yield<-1;must_error(run_diversity(d,c("Yield","Height")),"constant")
})
check("Regression reviewed missing values and names",{
  d<-read_pasted_table(correlation_example);d$Yield[1]<-NA
  must_error(run_correlation_regression(d,"Yield",c("Rainfall","Nitrogen")),"Review")
  r<-run_correlation_regression(d,"Yield",c("Rainfall","Nitrogen"),TRUE)
  stopifnot(identical(r$diagnostics$Observation,2:5))
  names(d)[names(d)=="Yield"]<-"Grain `yield`"
  r<-run_correlation_regression(d,"Grain `yield`",c("Rainfall","Nitrogen"),TRUE)
  stopifnot(nrow(r$diagnostics)==4)
})
for (key in names(module_registry)) check(paste("UI",key),{
  rendered<-htmltools::renderTags(module_ui(key))$html
  stopifnot(nchar(rendered)>100,grepl(module_registry[[key]]$label,rendered,fixed=TRUE) || grepl("&",module_registry[[key]]$label,fixed=TRUE))
})
check("New module server and stale export guard",{
  server<-function(input,output,session) research_server("pca-diversity",input,output,session)
  shiny::testServer(server,{
    session$setInputs(research_paste=research_example_text("pca-diversity"),map_Genotype="Genotype",research_traits=c("Yield","Height","Maturity"),cluster_count=2,research_alpha=.05,research_exclude=FALSE)
    session$setInputs(research_run=1)
    stopifnot(grepl("Completed",output$research_status$html,fixed=TRUE))
    session$setInputs(research_table_1_rows_current=1:3,research_table_1_rows_all=1:3,research_table_1_state=list(start=0),DataTables_Table_16_length=10)
    stopifnot(grepl("Completed",output$research_status$html,fixed=TRUE))
    session$setInputs(cluster_count=3)
    stopifnot(grepl("stale",output$research_status$html,fixed=TRUE))
  })
})
check("Legacy stale guard",{
  server<-function(input,output,session){result<-guarded_event_reactive(input$run,{list(answer=input$x)});output$answer<-renderText(result()$answer)}
  shiny::testServer(server,{
    session$setInputs(x=1,run=1);stopifnot(identical(output$answer,"1"))
    session$setInputs(x=2);must_error(output$answer,"Inputs changed")
    session$setInputs(run=2);stopifnot(identical(output$answer,"2"))
  })
})
check("Display inputs do not rebuild result UI",{
  server<-function(input,output,session){
    signature<-stable_input_signature(input,"table_choice","^DataTables_")
    renders<-0L
    output$result<-renderText({signature();renders<<-renders+1L;as.character(renders)})
  }
  shiny::testServer(server,{
    session$setInputs(trait="Yield");before<-output$result
    session$setInputs(DataTables_Table_1_length=10,table_choice="Rankings")
    stopifnot(identical(output$result,before))
    session$setInputs(trait="Height");stopifnot(as.integer(output$result)>as.integer(before))
  })
})
check("Publication table renderer retains server scope and reactivity",{
  shiny::testServer(function(input,output,session) {
    local_result<-shiny::reactive(structure(data.frame(Estimate=input$x,P=1e-6),mesg="Confidence level used: 0.95"))
    output$tab<-render_publication_table(local_result())
  },{
    session$setInputs(x=2)
    stopifnot(grepl("2.000",output$tab,fixed=TRUE),grepl("&lt;0.001",output$tab,fixed=TRUE))
    stopifnot(grepl("Confidence level used: 0.95",output$tab,fixed=TRUE))
    session$setInputs(x=3)
    stopifnot(grepl("3.000",output$tab,fixed=TRUE))
  })
})
check("Report titles prefer explicit analysis names and avoid duplicate tables",{
  d<-data.frame(Contrast="A - B",Estimate=2,P=.01)
  tables<-legacy_report_tables(list(anova_table=d,extra_tables=list("Test Result"=d)))
  stopifnot(identical(names(tables),"Test Result"),identical(tables[[1]],d))
})
saveRDS(outputs,"output/research-tests/results.rds")
write.csv(data.frame(Check=names(results),Result=unlist(results)),"output/research-tests/checks.csv",row.names=FALSE)
cat(sum(unlist(results)=="PASS"),"/",length(results),"checks passed\n")
if(any(unlist(results)!="PASS")) quit(status=1)
