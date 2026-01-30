# Analysis for Clus vs Disp data

# Getting relevant functions and data -----
source('./sampling_analysis/sampling_analysis.r')
source('./enrichment_analysis/flux_enrichment_analysis.R')
source('theme_set.R')

library(showtext)

# To be able to print reaction arrows \u2192, \u21bc
font_add("FreeSans", "../data/freesans-2-cufonfonts/FreeSans.otf") # need to run this only once every R session
showtext_auto()

df <- read_parquet(
  '../outputs/sampling/clus_vs_disp_median/loopless/final/full.parquet'
)

# Starting analysis -----
result_df <- compare_dist(df, 'Clus', 'Disp') %>% 
  get_final_df(0.33) %>% 
  construct_comprehensive_df(df, ., c('Clus', 'Disp'))

unfiltered_result <- compare_dist(df, 'Clus', 'Disp') %>% 
  # get_final_df(0.33) %>% 
  construct_comprehensive_df(df, ., c('Clus', 'Disp'))

result_df %>% 
write_csv("../results/sampling_results/clus_vs_disp/median/clus_vs_disp_fc2.csv")

unfiltered_result %>% 
  filter(!is.na(fc)) %>% 
  write_csv("../results/sampling_results/clus_vs_disp/median/clus_vs_disp_unfiltered.csv")

# Plotting ----

get_unique_active <- function(df, condition, cutoff='more') {
  if(cutoff=='more'){
    cutoff_filter <- df$fc > 0
  } else {
    cutoff_filter <- df$fc < 0
  }
  df %>% 
    filter((is.na(.data[[condition]])) | cutoff_filter) %>%
    # pluck('Reaction') %>% 
    return
}

active_disp <- result_df %>% 
  get_unique_active('Clus') %>% 
  filter(!is.na(Disp)) %>% 
  pluck('Reaction') 

active_clus <- result_df %>% 
  get_unique_active('Disp', 'less') %>% 
  filter(!is.na(Clus)) %>% 
  pluck('Reaction')


