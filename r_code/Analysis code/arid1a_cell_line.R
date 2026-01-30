# Analysis for ARID1A data

# Getting relevant functions and data -----
source('./sampling_analysis/sampling_analysis.r')
source('./enrichment_analysis/flux_enrichment_analysis.R')
source('theme_set.R')
library(ggvenn)

df <- read_parquet(
  '../outputs/sampling/arid1a_redo/loopless/final/full.parquet'
)
tcga_df <- read_parquet(
  '../outputs/sampling/TCGA-arid1a-avg/loopless/final/full.parquet'
)

# Starting analysis (Need to be done only once) -----
ges_wt_ko_unfiltered <- compare_dist(df, 'Ges1_P_D', 'Ges1_A_D')
  
mcf10a_wt_ko_unfiltered <- compare_dist(df, 'MCF10A_P', 'MCF10A_KO')

ovcar_wt_ko_unfiltered <- compare_dist(df, 'OVCAR3_P', 'OVCAR3_A1AKO') 

tcga_wt_trunc_unfiltered <- compare_dist(tcga_df, 'WT', 'Truncating') 

tcga_wt_mutant_unfiltered <- compare_dist(tcga_df, 'WT', 'mutant') 

ges_wt_ko <- ges_wt_ko_unfiltered %>% get_final_df(0.33) %>% 
  construct_comprehensive_df(df, ., c('Ges1_P_D', 'Ges1_A_D'))

mcf10a_wt_ko <- mcf10a_wt_ko_unfiltered %>% 
  get_final_df(0.33) %>% 
  construct_comprehensive_df(df, ., c('MCF10A_P', 'MCF10A_KO'))

ovcar_wt_ko <- ovcar_wt_ko_unfiltered %>% 
  get_final_df(0.33) %>% 
  construct_comprehensive_df(df, ., c('OVCAR3_P', 'OVCAR3_A1AKO'))

tcga_wt_trunc <- tcga_wt_trunc_unfiltered %>% 
  get_final_df(0.33) %>% 
  construct_comprehensive_df(tcga_df, ., c('WT', 'Truncating'))

tcga_wt_mutant <- tcga_wt_mutant_unfiltered %>% 
  get_final_df(0.33) %>% 
  construct_comprehensive_df(tcga_df, ., c('WT', 'mutant'))

## write results
ges_wt_ko %>% write_csv(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/ges_wt_ko.csv"
)

mcf10a_wt_ko %>% write_csv(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/mcf10a_wt_ko.csv"
)

ovcar_wt_ko %>% write_csv(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/ovcar_wt_ko.csv"
)

tcga_wt_trunc %>% 
  write_csv(
    "../results/sampling_results/TCGA-arid1a/loopless-non_growing/wt_trunc_fc2.csv"
  )

tcga_wt_mutant %>% 
  write_csv(
    "../results/sampling_results/TCGA-arid1a/loopless-non_growing/wt_mutant_fc2.csv"
  )

ges_wt_ko_unfiltered %>% write_csv(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/ges_wt_ko_unfiltered.csv"
)

mcf10a_wt_ko_unfiltered %>% write_csv(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/mcf10a_wt_ko_unfiltered.csv"
)

ovcar_wt_ko_unfiltered %>% write_csv(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/ovcar_wt_ko_unfiltered.csv"
)

tcga_wt_trunc_unfiltered %>% 
  write_csv(
    "../results/sampling_results/TCGA-arid1a/loopless-non_growing/wt_trunc_unfiltered.csv"
  )

tcga_wt_mutant_unfiltered %>% 
  write_csv(
    "../results/sampling_results/TCGA-arid1a/loopless-non_growing/wt_mutant_unfiltered.csv"
  )

# Plotting -----

## Read data (optional, if already saved)

# ges_wt_ko <- read_csv(
#   "../results/sampling_results/arid1a_redo/loopless-non_growing/ges_wt_ko.csv"
# )
# 
# mcf10a_wt_ko <- read_csv(
#   "../results/sampling_results/arid1a_redo/loopless-non_growing/mcf10a_wt_ko.csv"
# )
# 
# ovcar_wt_ko <-read_csv(
#   "../results/sampling_results/arid1a_redo/loopless-non_growing/ovcar_wt_ko.csv"
# )
# 
# tcga_wt_trunc <- read_csv(
#     "../results/sampling_results/TCGA-arid1a/loopless-non_growing/wt_trunc_fc2.csv"
#   )
# 
# tcga_wt_mutant <- read_csv(
#     "../results/sampling_results/TCGA-arid1a/loopless-non_growing/wt_mutant_fc2.csv"
#   )

# FEA



ges_ko_rxn <- ges_wt_ko %>% 
  get_unique_active('Ges1_P_D') %>% 
  filter(!is.na(Ges1_A_D)) %>% 
  pluck('Reaction')

ges_wt_rxn <- ges_wt_ko %>% 
  get_unique_active('Ges1_A_D', 'less') %>% 
  filter(!is.na(Ges1_P_D)) %>% 
  pluck('Reaction')

mcf_ko_rxn <- mcf10a_wt_ko %>% 
  get_unique_active('MCF10A_P') %>% 
  filter(!is.na(MCF10A_KO)) %>% 
  pluck('Reaction')

mcf_wt_rxn <- mcf10a_wt_ko %>% 
  get_unique_active('MCF10A_KO', 'less') %>% 
  filter(!is.na(MCF10A_P)) %>% 
  pluck('Reaction')

ovcar_ko_rxn <- ovcar_wt_ko %>% 
  get_unique_active('OVCAR3_P') %>% 
  filter(!is.na(OVCAR3_A1AKO)) %>% 
  pluck('Reaction')

ovcar_wt_rxn <- ovcar_wt_ko %>% 
  get_unique_active('OVCAR3_A1AKO', 'less') %>% 
  filter(!is.na(OVCAR3_P)) %>% 
  pluck('Reaction')

tcga_trunc_rxn <- tcga_wt_trunc %>% 
  get_unique_active('WT', ) %>% 
  filter(!is.na(Truncating)) %>% 
  pluck('Reaction')

tcga_wt_rxn <- tcga_wt_trunc %>% 
  get_unique_active('Truncating', 'less') %>% 
  filter(!is.na(WT)) %>% 
  pluck('Reaction')

tcga_mutant_rxn <- tcga_wt_mutant %>% 
  get_unique_active('WT', ) %>% 
  filter(!is.na(mutant)) %>% 
  pluck('Reaction')

active_all <- intersect(ovcar_ko_rxn, ges_ko_rxn) %>% intersect(mcf_ko_rxn)
inactive_all <- intersect(ovcar_wt_rxn, ges_wt_rxn) %>% intersect(mcf_wt_rxn)
ges_trunc <- intersect(ges_ko_rxn, tcga_trunc_rxn)
trunc_mut <- intersect(tcga_mutant_rxn, tcga_trunc_rxn)
trunc_mut_ges <- intersect(trunc_mut, ges_ko_rxn)

active_everywhere <- intersect(active_all, tcga_trunc_rxn) 
inactive_everywhere <- intersect(inactive_all, tcga_wt_rxn)

## Venn diagrams

active_venn <- list(
  GES1=ges_ko_rxn,
  MCF10A=mcf_ko_rxn,
  OVCAR3=ovcar_ko_rxn
) %>% 
  ggvenn(fill_color = cbPalette)

save_plot(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/ko_active_venn.png",
  height=5, width=5
)

inactive_venn <- list(
  GES1=ges_wt_rxn,
  MCF10A=mcf_wt_rxn,
  OVCAR3=ovcar_wt_rxn
) %>% 
  ggvenn(fill_color = cbPalette)

save_plot(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/wt_active_venn.png",
  height=5, width=5
)

ges_trunc_venn <- list(
  GES1=ges_wt_rxn,
  Truncating_TCGA=tcga_trunc_rxn
) %>% 
  ggvenn(fill_color = cbPalette)

save_plot(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/ges_trunc_venn.png",
  height=5, width=5
)

mutant_and_trunc <- list(
  Truncating=tcga_trunc_rxn,
  Mutant=tcga_mutant_rxn
) %>% 
  ggvenn(fill_color = cbPalette)

save_plot(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/mutant_trunc_venn.png",
  height=5, width=5
)

list(
  Truncating=tcga_trunc_rxn,
  Mutant=tcga_mutant_rxn,
  Ges1=ges_ko_rxn
) %>% 
  ggvenn(fill_color = cbPalette)

save_plot(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/ges_mutant_trunc_venn.png",
  height=5, width=5
)

## FEA

active_fea <- active_all %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA()

save_plot(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/active_cell_lines_fea.png",
)

inactive_fea <- inactive_all %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA()

save_plot(
  "../results/sampling_results/arid1a_redo/loopless-non_growing/inactive_cell_lines_fea.png",
 
)

ges_trunc %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA() %>% 
  save_plot(
    "../results/sampling_results/arid1a_redo/loopless-non_growing/ges_trunc_fea.png",
    plot=.
  )

trunc_mut %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA() %>% 
  save_plot(
    "../results/sampling_results/arid1a_redo/loopless-non_growing/mutant_trunc_fea.png",
    plot=.
  )

trunc_mut_ges %>% 
  FEA(rxn_df$Reaction, rxn_df$subSystem) %>% 
  plot_FEA() %>% 
  save_plot(
    "../results/sampling_results/arid1a_redo/loopless-non_growing/ges_mutant_trunc_fea.png",
    plot=.
  )

