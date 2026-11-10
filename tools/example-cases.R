# Shared executable examples for the scientific audit and documentation.
# Run from the repository root with R 4.5.3 and the locked dependencies.
load_drdesign <- function() {
  for(file in c("shared","analysis","met_analysis","app_builders","research_analysis","research_ui")) source(file.path("R",paste0(file,".R")),local=.GlobalEnv)
}

example_cases <- function() {
  cases<-list()
  add<-function(id,module,code) cases[[id]]<<-list(module=module,code=code)
  for(design in c("CRD","RBD")) for(method in c("LSD","DMRT","Tukey")) add(paste(design,method,sep="-"),"crd-rbd",sprintf('data <- read_pasted_table(default_data[["%s"]])\nresult <- run_design_analysis(data, "%s", comparison_method="%s")',design,design,method))
  for(design in c("Factorial CRD","Factorial RBD")) add(gsub(" ","-",design),"factorial-design",sprintf('data <- read_pasted_table(default_data[["%s"]])\nresult <- run_design_analysis(data, "%s", levels_a=2, levels_b=2)',design,design))
  for(kind in c("summary","sumbygrp","boxplot","histogram","qqplot","nt")) add(paste0("descriptive-",kind),"descriptive-statistics",sprintf('data <- read_pasted_table(default_data[["Descriptive Statistics"]])\nresult <- run_descriptive_analysis(data,"%s",c("Yield","Height"),"Group")',kind))
  for(kind in c("one-sample","two-sample","welch")) add(paste0("ttest-",kind),"compare-means",sprintf('data <- read_pasted_table(default_data[["Compare Means"]])\nresult <- run_ttest_analysis(data,"%s",value_var="Value",group_var="Group",mu=25)',kind))
  add("ttest-paired","compare-means",'data <- data.frame(Before=c(10.1,11.3,9.8,12.2),After=c(11,12,10.4,12.8))\nresult <- run_ttest_analysis(data,"paired",value_var="Before",pair_left="Before",pair_right="After")')
  for(simple in c(TRUE,FALSE)) add(if(simple) "simple-regression" else "multiple-regression","correlation-regression",sprintf('data <- read_pasted_table(correlation_example)\nresult <- run_correlation_regression(data,"Yield",%s)',if(simple) '"Rainfall"' else 'c("Rainfall","Nitrogen")'))
  add("pooled-anova","pooled-anova",'data <- read_pasted_table(pooled_example)\nresult <- run_pooled_anova(data)')
  add("split-plot","split-plot",'data <- expand.grid(Rep=paste0("R",1:4),MainPlot=paste0("A",1:3),SubPlot=paste0("B",1:3))\ni <- seq_len(nrow(data))\ndata$Value <- 30+as.numeric(data$MainPlot)*2+as.numeric(data$SubPlot)+sin(i*1.7)+rep(c(-2,1,0,1),9)\nresult <- run_split_plot(data)')
  add("pooled-split-plot","pooled-split-plot",'data <- read_pasted_table(pooled_split_plot_example)\ndata$Value <- data$Value+sin(seq_len(nrow(data))*1.7)\nresult <- run_pooled_split_plot(data,include_pwpp=TRUE)')
  layout_args<-c(CRD='trt=4,rep=3',RBD='trt=4,rep=3',`Factorial CRD`='factor_a_trt=2,factor_b_trt=3,rep=3',`Factorial RBD`='factor_a_trt=2,factor_b_trt=3,rep=3',`Split Plot`='main_trt=3,sub_trt=3,rep=3',`Strip Plot`='main_trt=3,sub_trt=3,rep=3',`Augmented RCBD`='checks=3,test_trt=6,rep=3')
  for(design in names(layout_args)) add(paste0("layout-",gsub(" ","-",design)),"design-analyzer",sprintf('data <- data.frame(Seed=7)\nresult <- run_design_layout("%s",seed=7,%s)',design,layout_args[[design]]))
  add("alpha-layout","alpha-layout",'data <- data.frame(Genotypes=12,BlockSize=3,Replications=3,Seed=7)\nresult <- list(fieldbook=run_alpha_layout(12,3,3,7))')
  for(method in c("anova","two-sample")) add(paste0("power-",method),"power-planning",sprintf('data <- data.frame(Mean=%s)\nresult <- run_power_planning(data$Mean,residual_sd=3,method="%s")',if(method=="anova") 'c(20,22,24)' else 'c(20,22)',method))
  add("data-preparation","data-preparation",'data <- research_example("data-preparation")\nresult <- run_data_preparation(data,c("Yield","Height"),c("Genotype","Rep"))')
  add("wide-to-long","data-preparation",'data <- read_pasted_table(default_data$RBD)\nresult <- run_data_preparation(data,c("Rep1","Rep2","Rep3"),"trt",wide=TRUE)')
  add("augmented","augmented-trial",'data <- research_example("augmented-trial")\nresult <- run_augmented_trial(data,c("C1","C2"))')
  add("strip-plot","strip-plot",'data <- research_example("strip-plot")\nresult <- run_strip_trial(data)')
  add("genetic","genetic-variability",'data <- research_example("genetic-variability")\nresult <- run_genetic_variability(data,c("Yield","Height"))')
  for(method in c("weighted","mgidi")) add(paste0("selection-",method),"multi-trait-selection",sprintf('data <- research_example("multi-trait-selection")\nresult <- run_multi_trait_selection(data,c("Yield","Height","Maturity"),lower_traits="Maturity",method="%s")',method))
  add("pca","pca-diversity",'data <- research_example("pca-diversity")\nresult <- run_diversity(data,c("Yield","Height","Maturity"),clusters=3)')
  for(random in c(TRUE,FALSE)) {
    add(paste0("incomplete-",if(random) "random" else "fixed"),"incomplete-block",sprintf('data <- research_example("incomplete-block")\nresult <- run_genetic_variability(data,"Yield",incomplete=TRUE,genotype_random=%s)',random))
    add(paste0("spatial-",if(random) "random" else "fixed"),"spatial-field",sprintf('data <- research_example("spatial-field")\nresult <- run_spatial_trial(data,genotype_random=%s)',random))
  }
  add("line-tester","combining-ability",'data <- research_example("combining-ability")\nresult <- run_combining_ability(data)')
  add("diallel","combining-ability",'pairs <- which(upper.tri(matrix(0,4,4),diag=TRUE),arr.ind=TRUE)\ndata <- do.call(rbind,lapply(1:3,function(r)data.frame(Rep=paste0("R",r),Parent1=paste0("P",pairs[,1]),Parent2=paste0("P",pairs[,2]),Value=20+pairs[,1]+pairs[,2]+sin(seq_len(nrow(pairs))*r))))\nresult <- run_combining_ability(data,method="diallel")')
  add("heterosis","heterosis",'data <- research_example("heterosis")\nresult <- run_heterosis(data,"G01","G02",c("G03","G04"),check="G05")')
  add("generation-means","generation-means",'data <- research_example("generation-means")\nresult <- run_generation_means(data)')
  for(direction in c("h","l")) add(paste0("met-",direction),"met-stability",sprintf('data <- read_pasted_table(met_example)\nresult <- run_met_analysis(data,"GEN","ENV","REP","Yield",direction="%s")',direction))
  add("met-batch","met-stability",'data <- read_pasted_table(met_example)\ndata$Height <- 50+2*data$Yield+cos(seq_len(nrow(data)))\nbatch <- run_met_batch_analysis(data,"GEN","ENV","REP",c("Yield","Height"),c(Yield="h",Height="l"))\nresult <- list(tables=met_all_batch_result_tables(batch,batch$results[[1]]))')
  cases
}

example_tables <- function(result) {
  if(!is.null(result$tables)) return(result$tables)
  if(!is.null(result$ammi)) return(c(met_result_tables(result),setNames(result$ind_anova,paste("Environment",names(result$ind_anova)))))
  collect<-function(x,prefix="") {
    if(is.data.frame(x) || is.matrix(x)) return(setNames(list(as.data.frame(x)),prefix))
    if(!is.list(x) || inherits(x,c("lm","merMod","ggplot","ggplot2::ggplot"))) return(list())
    out<-list();for(nm in names(x)) if(!nm %in% c("model","plots")) out<-c(out,collect(x[[nm]],paste(prefix,nm)))
    out
  }
  out<-collect(result);names(out)<-trimws(names(out));out
}

example_plots <- function(result) {
  if(!is.null(result$plots)) return(result$plots)
  if(!is.null(result$ammi)) {
    plots<-list()
    if(!is.null(result$ammi$mod)) for(i in 1:2) plots[[paste0("AMMI",i)]]<-metan::plot_scores(result$ammi$mod,type=i)
    if(!is.null(result$gge$mod)) for(i in c(2,3,4,6)) plots[[paste0("GGE",i)]]<-plot(result$gge$mod,type=i)
    if(!is.null(result$waasb$mod)) plots$WAASBY<-metan::plot_scores(result$waasb$mod,type=3)
    return(plots)
  }
  collect<-function(x,prefix="") {
    if(inherits(x,c("ggplot","ggplot2::ggplot"))) return(setNames(list(x),prefix))
    if(!is.list(x) || is.data.frame(x) || inherits(x,c("lm","merMod"))) return(list())
    out<-list();for(nm in names(x)) if(!nm %in% c("model","mod","ammi","gge","waasb")) out<-c(out,collect(x[[nm]],paste(prefix,nm)))
    out
  }
  collect(result)
}
