# Program to combine flux samples from multiple conditions into one file

import polars as pl
import os
from pathlib import Path
import polars.selectors as cs
import argparse


def verify_path(path: Path):
    if not path.exists():
        print("Creating directory: \033[32m{}\033[0m".format(path))
        os.makedirs(path)
    return path


def main(
    files_dir,
    output_dir,
    modify_names=True,
    modify_names_file="../data/samplenames.tsv",
):
    output_dir = verify_path(Path(output_dir))
    files = list(Path(files_dir).glob("*.parquet"))
    dfs = list()
    for file in files:
        print(
            "Reading file: \033[95m{}\033[0m -".format(file),
        )
        df = pl.read_parquet(file)
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

    df.write_parquet(output_dir / "full.parquet", compression_level=16)
    common_df.write_parquet(output_dir / "common.parquet", compression_level=16)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--files_dir", type=str, required=True)
    parser.add_argument("--output_dir", type=str, required=True)
    parser.add_argument(
        "--modify_names", type=bool, action=argparse.BooleanOptionalAction, default=True
    )
    parser.add_argument(
        "--modify_names_file", type=str, default="../data/samplenames.tsv"
    )
    args = parser.parse_args()
    print(args)

    main(**vars(args))
