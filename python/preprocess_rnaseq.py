# Process the rnaseq dataset to add gene names to the rows
import polars as pl

# Import annotation data used in NCBI
annotation_df = pl.read_csv(
    "./data/rnaseq/Human.GRCh38.p13.annot.tsv",
    separator="\t",
    columns=["GeneID", "Symbol"],
)
# Import Recon specific gene data
recon_annot_df = pl.read_csv(
    "./data/recon-store-genes-1.tsv",
    separator="\t",
    columns=["gene_number", "entrez_id"],
)


# Create annotation dictionaries
# gene_dict = {id: symbol for id, symbol in annotation_df.to_dict()}
recon_dict = {
    entry["entrez_id"]: entry["gene_number"] for entry in recon_annot_df.to_dicts()
}  # I want entrez_id:gene_number


fkpm_df = pl.read_csv("./data/rnaseq/fkpm.tsv", separator="\t")
tpm_df = pl.read_csv("./data/rnaseq/tpm.tsv", separator="\t")
raw_df = pl.read_csv("./data/rnaseq/raw_counts.tsv", separator="\t")

fkpm_df.with_columns(
    pl.col("GeneID").replace_strict(
        recon_dict, default=pl.first(), return_dtype=pl.Utf8
    )
).write_csv("./data/rnaseq/fkpm_recon.tsv", separator="\t")
tpm_df.with_columns(
    pl.col("GeneID").replace_strict(
        recon_dict, default=pl.first(), return_dtype=pl.Utf8
    )
).write_csv("./data/rnaseq/tpm_recon.tsv", separator="\t")
raw_df.with_columns(
    pl.col("GeneID").replace_strict(
        recon_dict, default=pl.first(), return_dtype=pl.Utf8
    )
).write_csv("./data/rnaseq/raw_recon.tsv", separator="\t")
