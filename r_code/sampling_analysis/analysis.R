# Sampling analysis ----
library(dplyr)
library(arrow)
library(ggplot2)
library(purrr)
library(viridisLite)

# Reading data ----
df  <- read_parquet(
  "../outputs/sampling/localgini_sprintcore_avg/final/common.parquet",
  # as_data_frame = FALSE
)

# Preliminary analysis ----

conditions <- unique(df$experiment)

flux_change <- function(x1, x2){
  m1 = mean(x1)
  m2 = mean(x2)
  return((m2-m1)/abs(m2+m1))
}

compare_dist <- function(data, condition1, condition2, test=ks.test) {
  data1 <- data %>% filter(experiment == condition1) %>% select(-experiment)
  data2 <- data %>% filter(experiment == condition2) %>% select(-experiment)
  
  fc_result = list()
  result = list()
  
  for(reaction in colnames(data1)){
    result[[reaction]] <- test(
      data1[[reaction]],
      data2[[reaction]]
    ) %>% 
      pluck('p.value')
    
    fc_result[[reaction]] <- flux_change(data1[[reaction]], data2[[reaction]])
  }
  return(list(fc=fc_result, pval=result))
}

get_fc <- function(res, cutoff=0.82) {
  res$fc %>% 
    keep(\(x) x>0.82) %>% 
    t %>% 
    t %>% 
    as_tibble(rownames = "Reactions", .name_repair = \(x) "Fold Change") %>% 
    return
}

get_pval <- function(res, cutoff=0.05) {
  res$pval %>% 
    p.adjust("fdr") %>% 
    keep(\(x) x<0.05) %>% 
    return
}

## GES1: WT - ARID1A KO
res1 <- compare_dist(df, conditions[1], conditions[2]) 
pvals1 <- get_pval(res1)
fc1 <- get_fc(res1)

## GES1: WT - Volasertib WT
res2 <- compare_dist(df, conditions[1], conditions[4])
pvals2 <- get_pval(res2)
fc2 <- get_fc(res2)

## GES1: ARID1A KO - ARID1A KO Volasertib
res3 <- compare_dist(df, conditions[2], conditions[3]) 
pvals3 <- get_pval(res2)
fc3 <- get_fc(res3)
