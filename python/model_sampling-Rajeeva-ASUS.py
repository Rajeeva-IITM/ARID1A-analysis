import cobra as cb
import os
import polars as pl
from pathlib import Path
from argparse import ArgumentParser
from cobra.sampling import OptGPSampler
import logging

# Configure the logger
logging.basicConfig(
    level=logging.INFO,  # Set the logging level to INFO
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',  # Log format
    handlers=[logging.StreamHandler()]  # Output to console
)

logger = logging.getLogger(__name__)
def verify_path(path: Path):
    if not path.exists():
        print('Creating directory: \033[32m{}\033[0m'.format(path))
        os.makedirs(path)
    return path

def main(model_dir, output_dir, growth_path, sample_size=10000, seed=42, thinning=100, njobs=1, nproj=None, growth_percent=0.9):
    
    model_path = Path(model_dir)
    output_path = verify_path(Path(output_dir))
    
    # get growths for each model built
    growths = pl.read_csv(growth_path) # Growths is a csv file that is one of the output of characterize_contextual_model.m
    growths = {condition.name: condition[0] for condition in growths.iter_columns()}
    
    # Sampling for each model in model_path
    for file in model_path.glob('*.mat'):
        
        if (output_path / (file.stem + '.parquet')).exists():
            print('File already sampled: \033[95m{}\033[0m'.format(file))
            continue
        
        logger.info('Sampling file: \033[95m{}\033[0m'.format(file))
        model = cb.io.load_matlab_model(file)
        
        # get growth
        try:
            growth = growths[file.stem]
        except Exception as e:
            logger.error(f"Mismatch between growths and model files. {file}: {e}")
        
        # fix lower bound of growth reaction in the model 
        try:
            model.reactions.get_by_id('biomass_maintenance').lower_bound = growth_percent*growth # Hardcoded for now 
        except Exception as e:
            logger.error(f"{e}\n No biomass reaction in model: {file}. Please build the model again with growth as core reaction")
        
        # setting minimum growth
        
        try:
            sampler = OptGPSampler(model, seed=seed, thinning=thinning, processes=njobs, nproj=nproj)
            samples = sampler.sample(n=sample_size,)
        except Exception as e:
            logger.error(f"Sampling failed for file {file}: {e}")
            continue
        pl.from_pandas(samples).with_columns(pl.all().cast(pl.Float32)).write_parquet(output_path / (file.stem + '.parquet'))
        
    return None

if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('--model_dir', type=str, required=True)
    parser.add_argument('--output_dir', type=str, required=True)
    parser.add_argument('--growth_path', type=str, required=True)
    parser.add_argument('--sample_size', type=int, default=10000)
    parser.add_argument('--seed', type=int, default=42)
    parser.add_argument('--thinning', type=int, default=100)
    parser.add_argument('--njobs', type=int, default=1)
    parser.add_argument('--nproj', type=int, default=None)
    parser.add_argument('--growth_percent', type=float, default=0.9)
    args = parser.parse_args()
    main(**vars(args))
