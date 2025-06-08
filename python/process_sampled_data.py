# Program to combine flux samples from multiple conditions into one file

import polars as pl
import os
from pathlib import Path
import polars.selectors as cs
import argparse


def verify_path(path: Path):
    """
    Verifies if a directory path exists, and if not, creates it

    Parameters
    ----------
    path : Path
        The path to the directory

    Returns
    -------
    Path
        The same path
    """
    if not path.exists():
        print("Creating directory: \033[32m{}\033[0m".format(path))
        os.makedirs(path)
    return path


def main(
    files_dir,
    output_dir,
    file_type="parquet",
    modify_names=True,
    modify_names_file="../data/samplenames.tsv",
):
    """
    Reads multiple files (parquet or csv) from a directory and combines them into one. The stem of each file is used as the value for the experiment column.

    Parameters
    ----------
    files_dir : str or Path
        The directory containing the files
    output_dir : str or Path
        The directory where the combined data will be written to
    file_type : str, optional
        The type of files to process ('parquet' or 'csv'), by default 'parquet'
    modify_names : bool, optional
        If True, the experiment names will be modified according to the file specified in the `modify_names_file` argument, by default True
    modify_names_file : str or Path, optional
        The file containing the mapping of old to new experiment names, by default "../data/samplenames.tsv"

    Returns
    -------
    None
    """
    output_dir = verify_path(Path(output_dir))
    files = list(Path(files_dir).glob(f"*.{file_type}"))
    dfs = list()
    for file in files:
        print(
            "Reading file: \033[95m{}\033[0m -".format(file),
        )
        if file_type == "parquet":
            df = pl.read_parquet(file).cast(pl.Float32)
        elif file_type == "csv": # For deletion experiments
            df = pl.read_csv(file, schema_overrides={'grRatio': pl.Float32})
        else:
            raise ValueError(f"Unsupported file type: {file_type}")
        
        df = df.with_columns(experiment=pl.lit(file.stem))
        dfs.append(df)
    df = pl.concat(dfs, how="diagonal")

    if modify_names:
        annot_df = pl.read_csv(modify_names_file, separator="\t")
        annot_dict = {key: value[0] for key, value in annot_df.to_dict().items()}
        df = df.with_columns(
            pl.col("experiment").replace_strict(annot_dict, default=pl.first())
        )

    uncommon_columns = [
        column
        for column in df.select(cs.numeric()).columns
        if df[column].is_null().any()
    ]

    # print(uncommon_columns)
    # print(df)
    common_df = df.drop(uncommon_columns)

    if file_type == "parquet":
        df.write_parquet(output_dir / "full.parquet", compression_level=16)
        common_df.write_parquet(output_dir / "common.parquet", compression_level=16)
    elif file_type == "csv":
        df.write_csv(output_dir / "full.csv")
        common_df.write_csv(output_dir / "common.csv")


if __name__ == "__main__":
    
    # Simple argument pars
    parser = argparse.ArgumentParser()
    parser.add_argument("--files_dir", type=str, required=True)
    parser.add_argument("--output_dir", type=str, required=True)
    parser.add_argument("--file_type", type=str, choices=["parquet", "csv"], default="parquet")
    parser.add_argument(
        "--modify_names", type=bool, action=argparse.BooleanOptionalAction, default=True
    )
    parser.add_argument(
        "--modify_names_file", type=str, default="../data/samplenames.tsv"
    )
    args = parser.parse_args()
    print(args)

    main(**vars(args))
