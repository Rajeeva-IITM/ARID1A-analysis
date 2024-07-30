# Create averaged gene expression values

library(readr)
library(dplyr)
library(ggplot2)

annot_df <- read_tsv_arrow("../data/samplenames.tsv", ) %>% as.list()
tpm <- read_tsv_arrow("../data/rnaseq/tpm_recon.tsv")

newcolnames <- colnames(tpm)[2:13] %>% map(~annot_df[[.x]]) %>% unlist()
colnames(tpm) <- c('GeneID', newcolnames)

avg_df <- tpm %>% 
  mutate(
    GES_W1 = (GES1_WT_rep1+GES1_WT_rep2)*0.5,
    GES1_ARID1A_KO = (`GES1_ARID1A KO_rep1`+`GES1_ARID1A KO_rep2`)*0.5,
    GES1_WT_Volasertib = (GES1_WT_Volasertib_rep2 + GES1_WT_Volasertib_rep1)*0.5,
    GES1_ARID1A_KO_Volasertib = `GES1_ARID1A KO_Volasertib_rep1`*0.5 + `GES1_ARID1A KO_Volasertib_rep2`*0.5,
    OVCAR3_WT = OVCAR3_WT_rep1*0.5+OVCAR3_WT_rep2*0.5,
    OVCAR3_ARID1A_KO = `OVCAR3_ARID1A KO_rep1`*0.5 + `OVCAR3_ARID1A KO_rep2`*0.5
  ) %>% 
  select(-all_of(newcolnames))

write_csv(avg_df, "../data/rnaseq/tpm_avg_recon.tsv")
