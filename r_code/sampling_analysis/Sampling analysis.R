# Sampling analysis ----
library(dplyr)
library(arrow)
library(ggplot2)
library(purrr)
library(viridisLite)



out_dir <- '../outputs/sampling_analysis/localgini_sprintcore_avg/'

# Reading data ----
df  <- read_parquet(
  "../outputs/sampling/localgini_sprintcore_avg/final/common.parquet",
  # as_data_frame = FALSE
)

#Change that eyesore GES_W1 to GES_WT
df <- df %>% mutate(experiment = replace(experiment, experiment=='GES_W1', 'GES_WT'))

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
      pluck('p.value') # not caring about the statistic
    
    fc_result[[reaction]] <- flux_change(data1[[reaction]], data2[[reaction]])
  }
  fc_result = fc_result %>% unlist
  return(tibble(Reaction=colnames(data1), fc=fc_result, pval=result))
}

get_fc <- function(res, cutoff=0.82) {
  
  res$fc %>% 
    keep(\(x) x>0.82) %>% 
    unlist %>% 
    as_tibble(rownames = 'Reaction') %>% 
    return
}

get_pval <- function(res, cutoff=0.05) {
  res$pval %>% 
    p.adjust("fdr") %>% 
    keep(\(x) x<0.05) %>% 
    return
}

get_final_df <- function(res, fc_cutoff=0.82, pval_cutoff=0.05) {
  res %>% 
    filter(abs(fc)>fc_cutoff) %>% 
    mutate(pval = p.adjust(pval, method='fdr')) %>% 
    filter(pval<pval_cutoff) %>% 
    return
}

plot_distributions <- function(df, reaction, experiments, result_df) {
  
  fold_change <- result_df %>% filter(Reaction == reaction) %>% pluck('fc')
  pval <- result_df %>% filter( Reaction == reaction) %>% pluck('pval')
    
  relevant_df <- df %>% 
    select(reaction, experiment) %>%
    filter(experiment %in% experiments)  
  # print(relevant_df)
  # #positions
  range_x = max(relevant_df[[reaction]]) 
  range_x = range_x - range_x/2  # FInding a good position
  
  ggplot(relevant_df, aes(x=.data[[reaction]], fill=experiment)) +   #tidy evalutation of programmatic access
    geom_histogram(bins=50, alpha=0.5) +
    # annotate(
    #   "text",
    #   x=range_x, y=10,
    #   hjust = 0,
    #   vjust= 0,
    #   label = paste("Fold change", round(fold_change,2),  sep=" : ")
    # ) %>% 
    labs(title = paste("Fold change", round(fold_change,2),  sep=" : ")) %>% 
    return()
}

# Getting Results ----
## GES1: WT - ARID1A KO

condition_1 <- "GES_WT"
condition_2 <- "GES1_ARID1A_KO"
res1 <- compare_dist(df, condition_1, condition_2) %>% get_final_df %>% 
write_csv(., paste0(out_dir, condition_2, '-', condition_1, '.csv')) 

## GES1: WT - Volasertib WT

condition_1 <- "GES_WT"
condition_2 <- "GES1_WT_Volasertib"
res2 <- compare_dist(df, condition_1, condition_2) %>% get_final_df %>% 
  write_csv(., paste0(out_dir, condition_2, '-', condition_1, '.csv'))

## GES1: ARID1A KO - ARID1A KO Volasertib

condition_1 <- "GES1_ARID1A_KO"
condition_2 <- "GES1_ARID1A_KO_Volasertib"
res3 <- compare_dist(df, condition_1, condition_2) %>% get_final_df %>% 
  write_csv(., paste0(out_dir, condition_2, '-', condition_1, '.csv'))

## OVCAR3_WT - ARID1A_KO

condition_1 <- "OVCAR3_WT"
condition_2 <- "OVCAR3_ARID1A_KO"
res4 <- compare_dist(df, condition_1, condition_2) %>% get_final_df %>% 
  write_csv(., paste0(out_dir, condition_2, '-', condition_1, '.csv'))


