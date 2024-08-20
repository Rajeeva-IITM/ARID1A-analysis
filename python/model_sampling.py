import cobra as cb
import os
import polars as pl
from pathlib import Path
from argparse import ArgumentParser
from cobra.sampling import OptGPSampler

def verify_path(path: Path):
    if not path.exists():
        print('Creating directory: \033[32m{}\033[0m'.format(path))
        os.makedirs(path)
    return path

def main(model_dir, output_dir, sample_size=10000, seed=42, thinning=100, njobs=1):
    
    model_path = Path(model_dir)
    output_path = verify_path(Path(output_dir))
    
    # Sampling for each model in model_path
    for file in model_path.glob('*.mat'):
        print('Sampling file: \033[95m{}\033[0m'.format(file))
        model = cb.io.load_matlab_model(file)
        sampler = OptGPSampler(model, seed=seed, thinning=thinning, processes=njobs, )
        samples = sampler.sample(sample_size)
        pl.from_pandas(samples).with_columns(pl.all().cast(pl.Float32)).write_parquet(output_path / (file.stem + '.parquet'))
        
    return None

if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('--model_dir', type=str, required=True)
    parser.add_argument('--output_dir', type=str, required=True)
    parser.add_argument('--sample_size', type=int, default=10000)
    parser.add_argument('--seed', type=int, default=42)
    parser.add_argument('--thinning', type=int, default=100)
    parser.add_argument('--njobs', type=int, default=1)
    args = parser.parse_args()
    main(**vars(args))
    
