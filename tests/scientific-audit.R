source("tools/example-cases.R");load_drdesign()
dir.create("output/scientific-audit",recursive=TRUE,showWarnings=FALSE)
checks<-list();outputs<-list();inventory<-list()
check<-function(label,expr) {
  checks[[label]]<<-tryCatch({force(expr);"PASS"},error=function(e)paste("FAIL",conditionMessage(e)))
  cat(label,":",checks[[label]],"\n")
}
near<-function(x,y,tol=1e-8) stopifnot(isTRUE(all.equal(as.numeric(x),as.numeric(y),tolerance=tol,check.attributes=FALSE)))
reject<-function(expr) stopifnot(inherits(tryCatch({force(expr);NULL},error=identity),"error"))
cases<-example_cases()
for(id in names(cases)) check(paste("Example",id),{
  env<-new.env(parent=globalenv());eval(parse(text=cases[[id]]$code),env)
  result<-env$result;tables<-example_tables(result);stopifnot(length(tables)>0)
  plots<-example_plots(result)
  for(nm in names(tables)) {
    tab<-tables[[nm]];stopifnot(is.data.frame(tab),!anyDuplicated(names(tab)))
    formatted<-publication_table(tab);stopifnot(nrow(formatted)==nrow(tab))
    for(col in names(tab)) if(is.numeric(tab[[col]]) && grepl("^(P|p|[Pp][._]?[Vv]alue|HolmP|DifferenceP|Pr_F)$|^Pr[.(]",col)) stopifnot(all(is.na(tab[[col]]) | (tab[[col]]>=0 & tab[[col]]<=1)))
    for(pair in list(c("lower.CL","upper.CL"),c("LowerCI","UpperCI"),c("Lower","Upper"),c("ApproxLower","ApproxUpper"))) if(all(pair %in% names(tab))) stopifnot(all(is.na(tab[[pair[1]]]) | is.na(tab[[pair[2]]]) | tab[[pair[1]]]<=tab[[pair[2]]]))
    inventory[[length(inventory)+1]]<-data.frame(Example=id,Module=cases[[id]]$module,Output=nm,Kind="Table",Rows=nrow(tab),Columns=ncol(tab),Check="Schema, p-value bounds, interval ordering, presentation")
  }
  plot_files<-list()
  for(i in seq_along(plots)) {
    path<-file.path("output/scientific-audit",paste0(id,"-",i,".png"))
    p<-plots[[i]]
    png(path,width=1200,height=800,res=130)
    tryCatch({if(is.function(p)) p() else print(p)},finally=dev.off())
    stopifnot(file.info(path)$size>1000)
    plot_files[[names(plots)[i]]]<-path
    inventory[[length(inventory)+1]]<-data.frame(Example=id,Module=cases[[id]]$module,Output=names(plots)[i],Kind="Figure",Rows=NA,Columns=NA,Check="Rendered; numerical source tables audited")
  }
  outputs[[id]]<-list(module=cases[[id]]$module,code=cases[[id]]$code,data=env$data,result=result,tables=tables,plots=plot_files)
})
get_result<-function(id) {stopifnot(!is.null(outputs[[id]]));outputs[[id]]$result}

check("T tests: signs, SE, df, p and confidence limits from scalar formulas",{
  for(id in c("ttest-one-sample","ttest-two-sample","ttest-welch","ttest-paired")) {
    out<-outputs[[id]];d<-out$data;r<-out$result$test_result
    if(id=="ttest-paired") {x<-d$Before-d$After;estimate<-mean(x);se<-sd(x)/sqrt(length(x));df<-length(x)-1}
    else if(id=="ttest-one-sample") {x<-d$Value;estimate<-mean(x)-25;se<-sd(x)/sqrt(length(x));df<-length(x)-1}
    else {
      groups<-split(d$Value,d$Group);x<-groups[[1]];y<-groups[[2]];n<-length(x);m<-length(y);estimate<-mean(x)-mean(y)
      if(id=="ttest-two-sample") {df<-n+m-2;se<-sqrt(((n-1)*var(x)+(m-1)*var(y))/df*(1/n+1/m))}
      else {v1<-var(x)/n;v2<-var(y)/m;se<-sqrt(v1+v2);df<-(v1+v2)^2/(v1^2/(n-1)+v2^2/(m-1))}
    }
    near(r$Estimate,estimate);near(r$SE,se);near(r$df,df);near(r$t,estimate/se);near(r$P,2*pt(-abs(estimate/se),df));near(c(r$LowerCI,r$UpperCI),estimate+c(-1,1)*qt(.975,df)*se)
  }
})
check("CRD/RBD: SS, MS, F and model-based confidence intervals",{
  for(design in c("CRD","RBD")) {
    r<-get_result(paste0(design,"-LSD"));d<-r$dataset;y<-d$Value
    T<-tapply(y,d$Trt,mean);B<-tapply(y,d$Rep,mean);grand<-mean(y);nrep<-length(B);nt<-length(T)
    sst<-sum((y-grand)^2);sstreat<-nrep*sum((T-grand)^2);ssblock<-if(design=="RBD") nt*sum((B-grand)^2) else 0
    sse<-sst-sstreat-ssblock;dferr<-if(design=="RBD") (nt-1)*(nrep-1) else nt*(nrep-1);mse<-sse/dferr
    a<-r$anova;near(a$`Sum Sq`[a$Term=="Trt"],sstreat);near(a$`Mean Sq`[a$Term=="Residuals"],mse)
    near(a$`F value`[a$Term=="Trt"],sstreat/(nt-1)/mse)
    near(r$treatment_summary$SE,rep(sqrt(mse/nrep),nt));near(r$treatment_summary$UpperCI-r$treatment_summary$Mean,rep(qt(.975,dferr)*sqrt(mse/nrep),nt))
    for(method in c("LSD","DMRT","Tukey")) stopifnot(identical(get_result(paste(design,method,sep="-"))$comparison_method,method))
  }
})
check("Regression: matrix least squares, covariance, residuals and correlations",{
  for(id in c("simple-regression","multiple-regression")) {
    r<-get_result(id);d<-r$dataset;vars<-if(id=="simple-regression") "Rainfall" else c("Rainfall","Nitrogen")
    X<-cbind(1,as.matrix(d[vars]));y<-d$Yield;beta<-qr.solve(X,y);res<-as.numeric(y-X%*%beta);v<-sum(res^2)/(nrow(X)-ncol(X))*solve(crossprod(X))
    near(r$coefficients$Estimate,beta,tol=1e-6);near(r$coefficients$`Std. Error`,sqrt(diag(v)),tol=1e-6);near(r$diagnostics$Residual,res)
    near(as.matrix(r$correlation),cor(d[c("Yield",vars)]))
  }
})
check("Factorial: full model retained, ANOVA decomposition and alpha honoured",{
  for(id in c("Factorial-CRD","Factorial-RBD")) {
    r<-get_result(id);d<-r$dataset;X<-model.matrix(if(id=="Factorial-CRD") ~FactA*FactB else ~Rep+FactA*FactB,d)
    res<-d$Value-X%*%qr.solve(X,d$Value);near(tail(r$anova$`Sum Sq`,1),sum(res^2))
    stopifnot("Interaction model" %in% r$factorial$assumptions$Value)
    d0<-read_pasted_table(default_data[[gsub("-"," ",id)]])
    r99<-run_design_analysis(d0,gsub("-"," ",id),alpha=.01)
    stopifnot(all(r99$factorial$emmeans_a$upper.CL-r99$factorial$emmeans_a$lower.CL > r$factorial$emmeans_a$upper.CL-r$factorial$emmeans_a$lower.CL))
  }
})
check("Split plot: error strata and SED from independent mean decomposition",{
  r<-get_result("split-plot");d<-r$dataset;nr<-nlevels(d$Rep);na<-nlevels(d$MainPlot);nb<-nlevels(d$SubPlot)
  cell<-with(d,tapply(Value,list(Rep,MainPlot),mean));grand<-mean(d$Value)
  ea<-nb*sum((cell-rowMeans(cell)-rep(colMeans(cell),each=nr)+grand)^2)/((nr-1)*(na-1))
  a<-r$split_anova;near(a$Mean.Sq[a$Source=="Error(a)"],ea)
  near(r$split_lsd_cv$`SE(d)`[1],sqrt(2*ea/(nr*nb)))
  stopifnot("Interaction model" %in% r$assumptions$Value)
  reject(run_split_plot(d[-1,]));reject(run_split_plot(rbind(d,d[1,])))
})
check("Pooled split: contrasts, CD, CI and fitted-plus-residual identity",{
  r<-get_result("pooled-split-plot");near(r$diagnostics$Fitted+r$diagnostics$Residual,r$dataset$Value)
  for(nm in c("lsd_main","lsd_sub","lsd_interaction","lsd_sub_within_main","lsd_main_within_sub")) {
    t<-r[[nm]];near(t$CD,qt(.975,t$df)*t$SE);near(t$t.ratio,t$estimate/t$SE);near(t$p.value,2*pt(-abs(t$t.ratio),t$df));near(t$upper.CL-t$estimate,t$CD)
  }
})
check("Pooled ANOVA: seasonal SSE and combined decomposition",{
  r<-get_result("pooled-anova");d<-r$dataset
  for(s in levels(d$Season)) {z<-subset(d,Season==s);X<-model.matrix(~Rep+Treatment,z);near(r$error_summary$ErrorMS[r$error_summary$Season==s],sum((z$Value-X%*%qr.solve(X,z$Value))^2)/(nrow(X)-qr(X)$rank))}
  near(sum(r$anova$`Sum Sq`),sum((d$Value-mean(d$Value))^2))
})
check("Descriptive tables: independent group counts, means and SD",{
  r<-get_result("descriptive-sumbygrp");for(i in seq_len(nrow(r$by_group))) {z<-r$by_group[i,];v<-r$dataset[r$dataset$Group==z$Group,z$Variable];near(z$Mean,mean(v));near(z$SD,sd(v));near(z$N,length(v))}
})
check("Genetic parameters: balanced ANOVA moments and BLUP matrix agreement",{
  r<-get_result("genetic");d<-r$dataset
  for(trait in c("Yield","Height")) {
    y<-d[[trait]];G<-tapply(y,d$Genotype,mean);B<-tapply(y,d$Rep,mean);g<-length(G);b<-length(B);mu<-mean(y)
    e<-y-G[d$Genotype]-B[d$Rep]+mu;ve<-sum(e^2)/((g-1)*(b-1));vg<-(b*sum((G-mu)^2)/(g-1)-ve)/b
    p<-r$tables[[paste(trait,"genetic parameters")]];near(p$GeneticVariance,vg,1e-5);near(p$ResidualVariance,ve,1e-5);near(p$H2_entry_mean_balanced_RCBD,vg/(vg+ve/b),1e-5)
    pred<-r$tables[[paste(trait,"BLUPs")]];m<-r$tables[["Genotype trait matrix"]];near(pred$Predicted,m[[trait]][match(pred$GEN,m$Genotype)])
  }
})
check("Selection: signed standardized weights, ranks and cutoff",{
  r<-get_result("selection-weighted");d<-r$dataset;traits<-c("Yield","Height","Maturity");s<-rowMeans(sweep(scale(as.matrix(d[traits])),2,c(1,1,-1),`*`));t<-r$tables$Rankings
  near(t$Score,s[match(t$Genotype,d$Genotype)]);stopifnot(sum(t$Selected)==ceiling(nrow(d)*.15))
})
check("PCA: standardized SVD, eigenvalues, scores and Ward distances",{
  r<-get_result("pca");x<-scale(as.matrix(r$dataset[c("Yield","Height","Maturity")]));z<-svd(x);load<-as.matrix(r$tables$Loadings[,-1]);score<-as.matrix(r$tables[[2]][,grep("^PC",names(r$tables[[2]])),drop=FALSE])
  near(score%*%t(load),x);near(crossprod(load),diag(ncol(x)));near(r$tables[[1]]$VariancePercent,100*z$d^2/sum(z$d^2))
})
check("Power: noncentral F calculation and integer sample size",{
  r<-get_result("power-anova");means<-c(20,22,24);n<-r$tables[[1]]$ReplicationsPerGroup;k<-length(means)
  pow<-function(n) pf(qf(.95,k-1,k*(n-1)),k-1,k*(n-1),ncp=n*sum((means-mean(means))^2)/9,lower.tail=FALSE)
  near(r$tables[[1]]$AchievedPower,pow(n));stopifnot(pow(n)>=.8,pow(n-1)<.8)
})
check("Spatial: fitted values, residuals, RMSE and coordinate mapping",{
  for(id in c("spatial-fixed","spatial-random")) {r<-get_result(id);d<-r$tables[[2]];near(d$Fitted+d$Residual,r$dataset$Value);near(r$tables[[3]]$ResidualRMSE,c(sqrt(mean(d$Residual^2)),sqrt(mean(d$NonspatialResidual^2))));stopifnot(!anyDuplicated(d[c("Row","Column")]))}
})
check("Line x tester: all GCA/SCA effects and Holm tests",{
  r<-get_result("line-tester");d<-r$dataset;t<-r$tables[[3]];m<-with(d,tapply(Value,list(Parent1,Parent2),mean));mu<-mean(m)
  for(i in rownames(m)) near(t$estimate[t$contrast==paste("Line GCA",i)],mean(m[i,])-mu)
  for(j in colnames(m)) near(t$estimate[t$contrast==paste("Tester GCA",j)],mean(m[,j])-mu)
  for(i in rownames(m)) for(j in colnames(m)) near(t$estimate[t$contrast==paste("SCA",i,j)],m[i,j]-mean(m[i,])-mean(m[,j])+mu)
  near(t$HolmP,p.adjust(t$p.value,"holm"))
})
check("Diallel II: effects reconstruct cross means; uncertainty scales with residual SD",{
  r<-get_result("diallel");m<-r$tables[[2]];t<-r$tables[[3]];parents<-levels(r$dataset$Parent1);mu<-mean(m$emmean);g<-t$estimate[grepl("^GCA",t$contrast)];near(sum(g),0)
  for(i in seq_len(nrow(m))) {ij<-as.integer(strsplit(as.character(m$Cross[i]),":",fixed=TRUE)[[1]]);s<-t$estimate[t$contrast==paste("SCA",parents[ij[1]],parents[ij[2]])];near(mu+g[ij[1]]+g[ij[2]]+s,m$emmean[i])}
  d<-outputs$diallel$data;d$Value<-d$Value*3;t3<-run_combining_ability(d,"diallel")$tables[[3]];near(t3$SE,3*t$SE);near(t3$p.value,t$p.value)
})
check("Heterosis: every reference, direction, percent and delta SE",{
  r<-get_result("heterosis");m<-tapply(r$dataset$Value,r$dataset$Genotype,mean);t<-r$tables[[1]];ve<-tail(r$tables$ANOVA$`Mean Sq`,1)/nlevels(r$dataset$Rep)
  for(i in seq_len(nrow(t))) {z<-t[i,];ref<-switch(z$Comparison,`Mid-parent`=mean(m[c("G01","G02")]),`Better-parent`=max(m[c("G01","G02")]),Standard=m["G05"]);h<-m[z$Hybrid];near(z$Difference,h-ref);near(z$HeterosisPercent,100*(h/ref-1));vref<-if(z$Comparison=="Mid-parent") ve/2 else ve;near(z$ApproxSEPercent,100*sqrt(ve/ref^2+h^2*vref/ref^4))}
  near(t$HolmP,p.adjust(t$DifferenceP,"holm"))
})
check("Generation means: exact inverse solution, covariance, scaling and lack of fit",{
  r<-get_result("generation-means");d<-r$dataset;X<-as.matrix(r$tables[[5]][,-1]);inv<-solve(X);near(r$tables[[2]]$Estimate,inv%*%d$Mean);near(r$tables[[2]]$SE,sqrt(diag(inv%*%diag(d$SE^2)%*%t(inv))))
  a<-r$tables[[1]];res<-d$Mean-X[,1:3]%*%a$Estimate;near(r$tables[[4]]$ChiSquare,sum(res^2/d$SE^2));near(r$tables[[4]]$P,pchisq(r$tables[[4]]$ChiSquare,3,lower.tail=FALSE))
  near(r$tables[[3]]$Estimate,c(2*d$Mean[5]-d$Mean[1]-d$Mean[3],2*d$Mean[6]-d$Mean[2]-d$Mean[3],4*d$Mean[4]-d$Mean[1]-d$Mean[2]-2*d$Mean[3],2*d$Mean[4]-d$Mean[5]-d$Mean[6]))
})
check("MET: AMMI SS from double-centred SVD and ranking direction",{
  r<-get_result("met-h");m<-with(r$dataset,tapply(Y,list(GEN,ENV),mean));interaction<-sweep(sweep(m,1,rowMeans(m)),2,colMeans(m))+mean(m);s<-svd(interaction)$d^2*3
  near(head(r$ammi$ipca_summary$SS,2),head(s,2),1e-5)
  low<-get_result("met-l");stopifnot(r$gen_means$GEN[1]==r$gen_means$GEN[which.max(r$gen_means$Mean)],low$gen_means$GEN[1]==low$gen_means$GEN[which.min(low$gen_means$Mean)])
  for(nm in c("h","l")) {r<-get_result(paste0("met-",nm));t<-r$ssi$full;near(t$NP_SSI,t$Rank_Yield+t$Rank_Stability);near(t$WAASBY,.7*t$PctResp+.3*t$PctWAASB)}
  stopifnot(is.na(safe_harmonic(c(1,-2,3))),is.na(safe_harmonic(c(1,0,3))))
  near(met_rank(c(1,1,2)),c(2.5,2.5,1))
})
check("Incomplete MET cells cannot silently trigger AMMI/GGE imputation",{
  d<-get_result("met-h")$dataset;d<-d[!(d$GEN==levels(d$GEN)[1] & d$ENV==levels(d$ENV)[1]),]
  stopifnot(is.null(compute_ammi(d)$mod),is.null(compute_gge(d)$mod))
})
check("Genetic BLUP effect intervals are centred on effects, not predicted means",{
  r<-get_result("genetic");t<-r$tables[["Yield BLUPs"]]
  near((t$EffectLower+t$EffectUpper)/2,t$BLUPg);near(t$EffectUpper-t$BLUPg,qnorm(.975)*t$ConditionalSE)
})
check("Grouped navigation covers every workflow exactly once",{
  stopifnot(setequal(unlist(module_groups),setdiff(names(module_registry),"portal")),!anyDuplicated(unlist(module_groups)))
  html<-as.character(nav_links("pca-diversity"));stopifnot(length(gregexpr("<summary>",html,fixed=TRUE)[[1]])==5)
})
check("Publication formatting: tiny p, tiny estimate, missing values, row identifiers",{
  d<-data.frame(Estimate=c(.00000031,2,NA),P=c(1e-12,.048,NA),Power=c(.8,.9,.95),df=c(3,4.123,5));original<-d;r<-publication_table(d)
  stopifnot(identical(d,original),r$`p-value`[1]=="<0.001",r$Estimate[1]!="0.000",r$Power[1]=="0.800",r$`p-value`[3]=="NA")
  z<-data.frame(a=1:2,row.names=c("Yield","Height"));stopifnot(identical(publication_table(z)[[1]],c("Yield","Height")))
  p<-structure(data.frame(Yield=c(0,1e-5)),p_value_matrix=TRUE)
  stopifnot(all(publication_table(p)$Yield=="<0.001"))
  stopifnot(report_number(1e20)=="1.00e+20")
  stopifnot(publication_table(data.frame(Label=NA_character_))$Label=="NA")
})
write.csv(do.call(rbind,inventory),"output/scientific-audit/inventory.csv",row.names=FALSE)
write.csv(data.frame(Check=names(checks),Result=unlist(checks)),"output/scientific-audit/checks.csv",row.names=FALSE)
saveRDS(outputs,"output/scientific-audit/examples.rds")
writeLines(capture.output(sessionInfo()),"output/scientific-audit/session-info.txt")
cat(sum(unlist(checks)=="PASS"),"/",length(checks),"scientific checks passed;",length(inventory),"outputs inventoried.\n")
if(any(unlist(checks)!="PASS")) quit(status=1)
