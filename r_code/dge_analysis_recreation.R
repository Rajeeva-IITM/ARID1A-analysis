# Performing DE analysis to identify modified targets. Essentially a recreation

library(DESeq2)
library(purrr)
library(ggplot2)

df <- read_tsv("../data/counts/all.symbol.tsv", )
mat <- as.matrix(df[,2:9])
rownames(mat) <- df$gene

coldata <- read.csv('../data/samples.tsv', row.names = 1, sep = '\t')
coldata$Gene_KO <- as.factor(coldata$Gene_KO)
coldata$Drug <- as.factor(coldata$Drug)
coldata <- coldata[colnames(mat),]
coldata[['cell_type']] <- map(
  rownames(coldata), ~ strsplit(.x, "_", fixed = T) %>% pluck(1) %>% pluck(1) 
) %>% unlist()
coldata$cell_type <- as.factor(coldata$cell_type)

dds <- DESeqDataSetFromMatrix(mat, coldata, design = ~ Gene_KO)

smallestGroupSize <- 3
keep <- rowSums(counts(dds) >= 10) >= smallestGroupSize
dds <- dds[keep,]

dds$Gene_KO <- relevel(dds$Gene_KO, ref='WT')

dds <- DESeq(dds)

# res <- results(dds, name = "Gene_KO_WT_vs_KO")
resLFC <- lfcShrink(dds, contrast = c('Gene_KO', 'WT', 'KO'), type='ashr')

resLFC <- resLFC[order(resLFC$pvalue),]


# Variance transformation

vsd <- vst(dds)
pcadata <- DESeq2::plotPCA(
  vsd,
  returnData=TRUE,
 intgroup=c('cell_type','Drug','Gene_KO')
)
ggplot(pcadata, aes(x=PC1, y=PC2, color=cell_type, shape=Gene_KO)) +
  geom_point(size=5)
