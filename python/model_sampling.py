import logging
import os
from argparse import ArgumentParser
from pathlib import Path

import cobra as cb
import polars as pl
from cobra.sampling import OptGPSampler

# from typing import Integer


cobra_config = cb.Configuration()
cobra_config.solver = "glpk"
# Configure the logger
logging.basicConfig(
    level=logging.INFO,  # Set the logging level to INFO
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",  # Log format
    handlers=[logging.StreamHandler()],  # Output to console
)

logger = logging.getLogger(__name__)


def verify_path(path: Path):
    if not path.exists():
        print("Creating directory: \033[32m{}\033[0m".format(path))
        os.makedirs(path)
    return path


def main(
    model_dir: str,
    output_dir: str,
    growth_path: str,
    sample_size: int,
    seed: int,
    thinning: int,
    njobs: int,
    nproj: int,
    growth_percent: float,
    growth_reaction: str,
):
    model_path = Path(model_dir)
    output_path = verify_path(Path(output_dir))

    # get growths for each model built
    growths = pl.read_csv(
        growth_path
    )  # Growths is a csv file that is one of the output of characterize_contextual_model.m
    growths = {condition.name: condition[0] for condition in growths.iter_columns()}

    # Sampling for each model in model_path
    for file in model_path.glob("*.mat"):  # For each file
        if (output_path / (file.stem + ".parquet")).exists():
            print("File already sampled: \033[95m{}\033[0m".format(file))
            continue

        logger.info("Sampling file: \033[95m{}\033[0m".format(file))
        model = cb.io.load_matlab_model(file)

        # get growth
        try:
            growth = growths[file.stem]
        except Exception as e:
            logger.error(
                f"Mismatch between growths and model files. {file}: {e}. Ensure the files are from the same data"
            )

        # fix lower bound of growth reaction in the model
        try:
            model.reactions.get_by_id(growth_reaction).lower_bound = (  # type: ignore
                growth_percent * growth  # type: ignore
            )  # Hardcoded for now
        except Exception as e:
            logger.error(
                f"{e}\n No biomass reaction in model: {file}. Please build the model again with growth as core reaction"
            )

        # setting minimum growth - This is relevant when you want the growth flux to have some value

        try:
            sampler = OptGPSampler(
                model, seed=seed, thinning=thinning, processes=njobs, nproj=nproj
            )
            samples = sampler.sample(
                n=sample_size,
            )
        except Exception as e:
            logger.error(f"Sampling failed for file {file}: {e}")
            continue
        pl.from_pandas(samples).with_columns(pl.all().cast(pl.Float32)).write_parquet(
            output_path / (file.stem + ".parquet")
        )

    return None


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--model_dir", type=str, required=True)
    parser.add_argument("--output_dir", type=str, required=True)
    parser.add_argument("--growth_path", type=str, required=True)
    parser.add_argument("--sample_size", type=int, default=10000)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--thinning", type=int, default=100)
    parser.add_argument("--njobs", type=int, default=1)
    parser.add_argument("--nproj", type=int, default=None)
    parser.add_argument("--growth_percent", type=float, default=0.0)
    parser.add_argument("--growth_reaction", type=str, default="biomass_maintenance")
    args = parser.parse_args()
    main(**vars(args))
