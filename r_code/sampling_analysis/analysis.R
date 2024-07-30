# Sampling analysis ----
library(dplyr)
library(arrow)
library(ggplot2)
library(purrr)
library(viridisLite)

# Reading data ----
df  <- read_parquet("../outputs/sampling/localgini_sprintcore/final/common.parquet")

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



## GES1: WT - 2 reps
res1 <- compare_dist(df, conditions[1], conditions[2], test=t.test) 
pvals1 <- res1 %>% pluck('pval') %>% p.adjust(method='fdr') %>% keep(~.x<0.05)
fc1 <- res1$fc %>% keep(~.x>0.82)

## GES1: WT - Volasertib WT
pvals2 <- compare_dist(df, conditions[1], conditions[3]) %>% p.adjust(method='fdr') %>% keep(~.x<0.05)

## GES1: ARID1A KO - ARID1A KO Volasertib
pvals3 <- compare_dist(df, conditions[2], conditions[4]) %>% p.adjust(method='fdr') %>% keep(~.x<0.05)
