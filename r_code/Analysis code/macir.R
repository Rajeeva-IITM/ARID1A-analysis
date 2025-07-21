# Analysis of MACIR data 

# Getting relevant functions and data -----
source('./sampling_analysis/sampling_analysis.r')
source('./enrichment_analysis/flux_enrichment_analysis.R')
source('theme_set.R')
library(ggvenn)


result_path <- '../results/sampling_results/MACIR/loopless-non_growing/'

df_macir <- read_parquet(
  "../outputs/sampling/macir_redo/loopless/final/full.parquet"
)

# Starting analysis (Need to be done only once) -----

s1c1_vs_s1k1 <- compare_dist(
  df_macir,
  'S1C1', 'S1K1',
) %>%
  get_final_df(0.33) %>%
  construct_comprehensive_df(df_macir,., c('S1C1', 'S1K1'))
write_csv(
  s1c1_vs_s1k1,
  file.path(result_path, 's1c1_vs_s1k1.csv')
)

s1c2_vs_s1k2 <- compare_dist(
  df_macir,
  'S1C2', 'S1K2',
) %>%
  get_final_df(0.33) %>%
  construct_comprehensive_df(df_macir,., c('S1C2', 'S1K2'))
write_csv(
  s1c2_vs_s1k2,
  file.path(result_path, 's1c2_vs_s1k2.csv')
)

s1k1_vs_s1k1fc5 <- compare_dist(
  df_macir,
  'S1K1', 'S1K1_FC5',
) %>%
  get_final_df(0.33) %>%
  construct_comprehensive_df(df_macir,., c('S1K1', 'S1K1_FC5'))
write_csv(
  s1k1_vs_s1k1fc5,
  file.path(result_path, 's1k1_vs_s1k1fc5.csv')
)

s1k2_vs_s1k2fc5 <- compare_dist(
  df_macir,
  'S1K2', 'S1K2_FC5',
) %>%
  get_final_df(0.33) %>%
  construct_comprehensive_df(df_macir,., c('S1K2', 'S1K2_FC5'))
write_csv(
  s1k2_vs_s1k2fc5,
  file.path(result_path, 's1k2_vs_s1k2fc5.csv')
)

# Averaged
s1k_vs_s1kfc5 <- compare_dist(
  df_macir,
  'S1K', 'S1K_FC5',
) %>%
  get_final_df(0.33) %>%
  construct_comprehensive_df(df_macir,., c('S1K', 'S1K_FC5'))
write_csv(
  s1k_vs_s1kfc5,
  file.path(result_path, 's1k_vs_s1kfc5.csv')
)

# Plotting ----

## getting reactions 

s1c1_rxn <- s1c1_vs_s1k1 %>% get_unique_active(
  'S1K1', 'less'
) %>% filter(!is.na(S1C1)) %>% pluck('Reaction')
s1k1_rxn <- s1c1_vs_s1k1 %>% get_unique_active(
  'S1C1', 
) %>% filter(!is.na(S1K1)) %>% pluck('Reaction')

s1c2_rxn <- s1c2_vs_s1k2 %>% get_unique_active(
  'S1K2', 'less'
) %>% filter(!is.na(S1C2)) %>% pluck('Reaction')
s1k2_rxn <- s1c2_vs_s1k2 %>% get_unique_active(
  'S1C2', 
) %>% filter(!is.na(S1K2)) %>% pluck('Reaction')

s1k1_rescue_rxn <- s1k1_vs_s1k1fc5 %>% get_unique_active(
  'S1K1_FC5', 'less'
) %>% filter(!is.na(S1K1)) %>% pluck('Reaction')
s1k1fc5_rxn <- s1k1_vs_s1k1fc5 %>% get_unique_active(
  'S1K1', 
) %>% filter(!is.na(S1K1_FC5)) %>% pluck('Reaction')

s1k2_rescue_rxn <- s1k2_vs_s1k2fc5 %>% get_unique_active(
  'S1K2_FC5', 'less'
) %>% filter(!is.na(S1K2)) %>% pluck('Reaction')
s1k2fc5_rxn <- s1k2_vs_s1k2fc5 %>% get_unique_active(
  'S1K2', 
) %>% filter(!is.na(S1K2_FC5)) %>% pluck('Reaction')

s1k__rescue_rxn <- s1k_vs_s1kfc5 %>% get_unique_active(
  'S1K_FC5', 'less'
) %>% filter(!is.na(S1K)) %>% pluck('Reaction')
s1kfc5_rxn <- s1k_vs_s1kfc5 %>% get_unique_active(
  'S1K', 
) %>% filter(!is.na(S1K_FC5)) %>% pluck('Reaction')

## Intersections

ko_common_control <- intersect(s1k1_rxn, s1k2_rxn) # Common across knockouts compared to controls
wt_common_ko <- intersect(s1c1_rxn, s1c2_rxn) # Common across controls compared to KO

ko_common_rescue <- intersect(s1k1_rescue_rxn, s1k2_rescue_rxn) # Common across knockouts compared to rescue
rescue_common <- intersect(s1k1fc5_rxn, s1k2fc5_rxn) # Common across rescues compared to KO

ko_common_ungrouped <- intersect(ko_common_control, ko_common_rescue)
ko_common_all <- intersect(ko_common_ungrouped, s1k__rescue_rxn) 

rescue_common_all <- intersect(rescue_common, s1kfc5_rxn)

## figures

# Grouped vs common

list(
  KO_vs_control = ko_common_control,
  KO_vs_rescue = ko_common_rescue
) %>% 
  ggvenn(fill_color = cbPalette)
save_plot(file.path(result_path,"ko_common_venn.png"))

ko_common_ungrouped %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA()
save_plot(file.path(result_path,"ko_common_fea.png"))

ko_common_all %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA()
save_plot(file.path(result_path,"ko_common_ko_common_grouped_and_ungrouped_fea.png_fea.png"))

list(
  Rescue_ungrouped_common = rescue_common,
  Rescue_grouped = s1k__rescue_rxn
) %>% 
  ggvenn(fill_color = cbPalette)
save_plot(file.path(result_path, "Rescue_grouped_vs_rescue_ungrouped_venn.png"))

rescue_common_all %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA()
save_plot(file.path(result_path, "Rescue_grouped_vs_rescue_ungrouped_fea.png"))

rescue_comm
