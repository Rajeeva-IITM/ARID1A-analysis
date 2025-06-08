import argparse
import polars as pl
from pathlib import Path

data_path = Path(__file__).parent.parent  # path to data folder


def process_rnaseq(
    dataset_path,
    dataset_type,
    output_dir,
    output_name=None,
    log2_transformed=False,
    separator="\t",
    input_gene_type = "entrez_id" # must correspond to a column name in recon-store-genes-1
):
    # Import Recon specific gene data
    recon_annot_df = pl.read_csv(
        data_path / "data/recon-store-genes-1.tsv",
        separator="\t",
        columns=["gene_number", input_gene_type],
    )
    print(recon_annot_df)
    # Create annotation dictionaries
    recon_dict = {
        entry[input_gene_type]: entry["gene_number"] for entry in recon_annot_df.to_dicts()
    }

    # Read the dataset
    dataset_df = pl.read_csv(dataset_path, separator=separator)

    # If the dataset is log2-transformed, preprocess it
    if log2_transformed:
        # Apply 2^cell_value transformation to all columns except "GeneID"
        dataset_df = dataset_df.with_columns(
            pl.col("GeneID"),
            **{col: 2 ** pl.col(col) for col in dataset_df.columns if col != "GeneID"},
        )

    # Process the dataset
    processed_df = dataset_df.with_columns(
        pl.col("GeneID").replace_strict(
            recon_dict, default=pl.first(), return_dtype=pl.Utf8
        )
    )
    processed_df = processed_df.filter(
        pl.any_horizontal( pl.all().exclude("GeneID").is_not_null()) # Filter out rows where any value is null
    )

    # Determine the output file name
    if not output_name:
        if not dataset_type:
            raise ValueError("Either --type or --output_name must be provided.")
        output_name = f"{dataset_type}_recon.tsv"

    # Save the processed dataset
    processed_df.write_csv(f"{output_dir}/{output_name}", separator="\t")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process RNA-seq dataset files.")
    parser.add_argument(
        "--dataset",
        required=True,
        help="Path to the dataset file. Must contain the GeneID column with entrez ids.",
    )
    parser.add_argument(
        "--type",
        choices=["fkpm", "tpm", "raw"],
        help="Type of the dataset (fkpm, tpm, or raw). Required if --output_name is not provided.",
    )
    parser.add_argument(
        "--output_dir", required=True, help="Directory to save the processed file."
    )
    parser.add_argument(
        "--output_name",
        help="Custom name for the output file (optional). If not provided, --type must be specified.",
    )
    parser.add_argument(
        "--log2_transformed",
        action="store_true",
        help="Specify if the dataset is log2-transformed. If set, values will be converted back to their original scale.",
    )
    parser.add_argument(
        "--separator",
        default="\t",
        type=str,
        help="Separator used in the input dataset file (default: '\\t').",
    )
    
    parser.add_argument(
        "--input_gene_type",
        default="entrez_id",
        type=str,
        help="Type of gene ids in the input dataset file (default: entrez_id). Others may include ['ensembl_gene', 'ensembl_trans', 'chebl_id', uniprot_gname', 'wikigene']",
    )

    args = parser.parse_args()

    process_rnaseq(
        dataset_path=args.dataset,
        dataset_type=args.type,
        output_dir=args.output_dir,
        output_name=args.output_name,
        log2_transformed=args.log2_transformed,
        separator=args.separator,
        input_gene_type=args.input_gene_type
    )
