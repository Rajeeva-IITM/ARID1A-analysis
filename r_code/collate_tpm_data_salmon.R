# Getting tpm and counts from salmon processed reads and comparing it to
# star output

# library(tximport)
library(DESeq2)
suppressPackageStartupMessages(library(TxDb.Hsapiens.UCSC.hg38.knownGene))
library(purrr)
library(dplyr)
library(biomaRt)

# Get names of the samples
df <- read.csv("../data/samples.tsv", sep='\t')
samples <- df$sample_name

# Get paths to all the quant.sf
files <- file.path('..','data', 'salmon_results', samples, 'quant.sf')
all(file.exists(files)) #verify if all files exist

# Using txdb for getting gene names
txdb <- TxDb.Hsapiens.UCSC.hg38.knownGene
k <- keys(txdb, keytype = "TXNAME")
tx2gene <- select(txdb, k, "GENEID", "TXNAME")
tx2gene <- rename(tx2gene, Name=TXNAME)

# ensembl <- useEnsembl(biomart = "ENSEMBL_MART_ENSEMBL", dataset = "hsapiens_gene_ensembl",)

col.types <- readr::cols(
  readr::col_character(),readr::col_integer(),readr::col_double(),readr::col_double(),readr::col_double()
)
importer <- function(x) {readr::read_tsv(
  x, col_types=col.types, col_select = c('Name', 'EffectiveLength', 'TPM', 'NumReads')
)}

txi <- map(files, ~ importer(.x) %>% mutate(weightedLength = EffectiveLength*TPM))
names(txi) <- samples

common_transcripts <- map(txi, ~ pluck(.x, 'Name' )) %>% reduce(unique)



final_df <- txi[[names(txi)[1]]]

for(data in names(txi[2:8])) {
  final_df <- full_join(
    final_df,
    txi[[data]],
    suffix = c("", paste0("_", data)),
    by=c('Name')
  )
}

final_df <- rename(
  final_df,
  TPM_Ges1_A_10 = TPM,
  NumReads_Ges1_A_10 = NumReads,
  weightedLength_Ges1_A_10 = weightedLength,
  EffectiveLength_Ges1_A_10 = EffectiveLength
)
final_df <- left_join(final_df, tx2gene)

abundanceMat <- final_df %>% 
  group_by(GENEID) %>% 
  summarise(
    Ges1_A_10 = sum(TPM_Ges1_A_10),
    Ges1_A_D = sum(TPM_Ges1_A_D),
    Ges1_P_10 = sum(TPM_Ges1_P_10),
    Ges1_P_D = sum(TPM_Ges1_P_D),
    MCF10A_KO = sum(TPM_MCF10A_KO),
    MCF10A_P = sum(TPM_MCF10A_P),
    OVCAR3_P = sum(TPM_OVCAR3_P),
    OVCAR3_A1AKO = sum(TPM_OVCAR3_A1AKO)
  )

# countsMat <- final_df %>% 
#   group_by(GENEID) %>% 
#   summarise(
#     Ges1_A_10 = sum(NumReads_Ges1_A_10),
#     Ges1_A_D = sum(NumReads_Ges1_A_D),
#     Ges1_P_10 = sum(NumReads_Ges1_P_10),
#     Ges1_P_D = sum(NumReads_Ges1_P_D),
#     MCF10A_KO = sum(NumReads_MCF10A_KO),
#     MCF10A_P = sum(NumReads_MCF10A_P),
#     OVCAR3_P = sum(NumReads_OVCAR3_P),
#     OVCAR3_A1AKO = sum(NumReads_OVCAR3_A1AKO)
#   )

# weightedLength <- final_df %>% 
#   group_by(GENEID) %>% 
#   summarise(
#     Ges1_A_10 = sum(weightedLength_Ges1_A_10),
#     Ges1_A_D = sum(weightedLength_Ges1_A_D),
#     Ges1_P_10 = sum(weightedLength_Ges1_P_10),
#     Ges1_P_D = sum(weightedLength_Ges1_P_D),
#     MCF10A_KO = sum(weightedLength_MCF10A_KO),
#     MCF10A_P = sum(weightedLength_MCF10A_P),
#     OVCAR3_P = sum(weightedLength_OVCAR3_P),
#     OVCAR3_A1AKO = sum(weightedLength_OVCAR3_A1AKO)
#   )
# 
# lengthMat <- as.matrix(dplyr::select(weightedLength, where(is.numeric))
#                        ) / as.matrix(dplyr::select(abundanceMat, where(is.numeric)))
# rownames(lengthMat) <- weightedLength$GENEID
# colnames(lengthMat) <- samples
# lengthMat <- as_tibble(lengthMat, rownames='GENEID')
# 
# avgLengthSamp <- final_df %>% 
#   mutate(AvgTranscriptLength = rowMeans(pick(starts_with('Effective')))) %>% 
#   dplyr::select(GENEID, AvgTranscriptLength)
# 
# avgLengthSampGene <- avgLengthSamp %>% group_by(GENEID) %>% 
#   summarise(GeneLength = mean(AvgTranscriptLength))
