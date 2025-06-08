# Load required libraries
library(dplyr)
library(arrow)
library(ggplot2)
library(purrr)
library(viridisLite)
library(readr)
library(progress)

# sampling_analysis <- function(input_file, output_dir) {
#   
#   # Ensure output directory exists
#   if (!dir.exists(output_dir)) {
#     dir.create(output_dir, recursive = TRUE)
#   }
#   
#   # Read the dataset
#   df <- read_parquet(input_file)
# 
#   return(df)
#   
# #   # Replace 'GES_W1' with 'GES_WT'
# #   df <- df %>% mutate(experiment = replace(experiment, experiment == 'GES_W1', 'GES_WT'))
#   
#   
# #   # Define conditions and perform analysis
# #   analyze_conditions("GES_WT", "GES1_ARID1A_KO", df, output_dir)
# #   analyze_conditions("GES_WT", "GES1_WT_Volasertib", df, output_dir)
# #   analyze_conditions("GES1_ARID1A_KO", "GES1_ARID1A_KO_Volasertib", df, output_dir)
# #   analyze_conditions("OVCAR3_WT", "OVCAR3_ARID1A_KO", df, output_dir)
# }


rxn_df <- read_csv("../data/recon_reaction_names.csv", show_col_types = F) 

# Define helper functions
flux_change <- function(x1, x2) {
    m1 <- mean(x1)
    m2 <- mean(x2)
    return((m2 - m1) / abs(m2 + m1))
}

custom_bootstrap <- function(data,statistic=mean, conf.interval=0.95,
                             n_resamples=10000, batchsize=100) {
  stat_distribution <- rep(0, n_resamples)
  
  for(i in 1:n_resamples){
    boot_data <- sample(data, batchsize)
    stat_distribution[i] <- statistic(boot_data)
  }
  ci <- list()
  ci_low <- 0+ (1-conf.interval)/2
  ci_high <-  1 - (1-conf.interval)/2
  ci <- quantile(stat_distribution, probs=c(ci_low, ci_high))
  return(ci)  
} 

compare_dist <- function(data, condition1, condition2, test = ks.test) {
    data1 <- data %>% filter(experiment == condition1) %>% select(-experiment)
    data2 <- data %>% filter(experiment == condition2) %>% select(-experiment)
    
    fc_result <- list()
    result <- list()
    prog <- progress_bar$new(total = length(colnames(data1)))
    for (reaction in colnames(data1)) {
      prog$tick()
      
      reac1 <- data1[[reaction]]
      reac2 <- data2[[reaction]]
      
      if(all(!is.na(reac1)) & all(!is.na(reac2))) {
        
        result[[reaction]] <- test(
          reac1, reac2
        ) %>% 
          pluck('p.value') # Extract p-value
        fc_result[[reaction]] <- flux_change(reac1, reac2)
        
      } else if(all(is.na(reac1)) & all(is.na(reac2))) {
        next
        
      } else if(all(is.na(reac1))) {
        reac1 <- 0 #set the value 0 for fold change calculation
        ci <- custom_bootstrap(reac2)
        result[[reaction]] <- ifelse(reac1>ci[1] & reac1<ci[2], 1, 0) # if zero in range, nothing interesting
        fc_result[[reaction]] <- flux_change(reac1, reac2)
        
      } else if(all(is.na(reac2))) {
        reac2 <- 0 #set the value 0 for fold change calculation
        ci <- custom_bootstrap(reac1)
        result[[reaction]] <- ifelse(reac2>ci[1] & reac2<ci[2], 1, 0) # if zero in range, nothing interesting
        fc_result[[reaction]] <- flux_change(reac1, reac2)
      }
      
      
    }
    fc_result <- fc_result %>% unlist
    return(tibble(Reaction = names(fc_result), fc = fc_result, pval = unlist(result)))
    # return(list(fc=fc_result, pval=result))
}

plot_flux_dist <- function(data, reaction) {
  p <- data %>% 
    ggplot(aes(x=.data[[reaction]], fill=experiment)) + 
    geom_histogram(alpha=0.5, bins=50) +
    labs(y='Count', fill='Condition')
  
  return(p)
}


get_final_df <- function(res, fc_cutoff = 0.82, pval_cutoff = 0.05) {
    res %>% 
      filter(abs(fc) > fc_cutoff) %>% 
      mutate(pval = p.adjust(pval, method = 'fdr')) %>% 
      filter(pval < pval_cutoff) %>% 
      return()
}

# Perform analysis for specific conditions
# analyze_conditions <- function(condition1, condition2, df, output_dir) {
#     res <- compare_dist(df, condition1, condition2) %>% 
#       return()
# }

construct_comprehensive_df <- function(flux, differential_reactions,  conditions, subsystem=rxn_df){
  df <- flux %>% 
    filter(experiment %in% conditions) %>% 
    group_by(experiment) %>% 
    summarise(across(where(is.numeric), mean)) %>% 
    tidyr::pivot_longer(cols = !experiment, values_to = "mean", names_to = "Reaction") %>%
    tidyr::pivot_wider(names_from = experiment, id_cols = Reaction, values_from= mean) 
  
  differential_reactions <- left_join(differential_reactions, df, by = "Reaction")
  
  final_df <- left_join(differential_reactions, subsystem, by="Reaction")
  return(final_df)
}


# Flow of steps:
# Read data file -> compare_dist -> get_final_df -> construct_comprehensive_df

# Example usage:
# sampling_analysis("../outputs/sampling/localgini_sprintcore_avg/final/common.parquet", "../outputs/sampling_analysis/clus_vs_disp")